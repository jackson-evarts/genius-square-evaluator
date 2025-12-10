//
//  CameraManager.swift
//  Genius Square Evaluator
//
//  Manages camera session and board detection
//

import AVFoundation
import Vision
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var detectedCorners: [CGPoint] = []
    @Published var isDetecting = false
    @Published var permissionGranted = false

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "vision.processing.queue")
    private let imageAnalyzer = ImageAnalyzer()

    var onBoardStateDetected: (([[BoardDetector.CellState]]) -> Void)?
    private var lastAnalysisTime: Date = Date.distantPast

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            permissionGranted = false
        }
    }

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // Set preset for high quality
            self.session.sessionPreset = .high

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                return
            }

            self.session.addInput(videoInput)

            // Add video output
            self.videoOutput.setSampleBufferDelegate(self, queue: self.visionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func startDetection() {
        isDetecting = true
    }

    func stopDetection() {
        isDetecting = false
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isDetecting else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Perform rectangle detection
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNRectangleObservation],
                  let firstRect = results.first else {
                return
            }

            // Convert Vision coordinates (normalized, bottom-left origin) to view coordinates
            let corners = [
                firstRect.topLeft,
                firstRect.topRight,
                firstRect.bottomRight,
                firstRect.bottomLeft
            ]

            DispatchQueue.main.async {
                self.detectedCorners = corners
            }
        }

        // Configure request for better square detection
        request.minimumAspectRatio = 0.8  // Close to square
        request.maximumAspectRatio = 1.2
        request.minimumSize = 0.3  // At least 30% of image
        request.maximumObservations = 1  // Only the most prominent rectangle

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Rectangle detection failed: \(error)")
        }

        // Analyze board state if we have corners (throttle to once per second)
        let now = Date()
        if !detectedCorners.isEmpty && now.timeIntervalSince(lastAnalysisTime) > 1.0 {
            lastAnalysisTime = now

            imageAnalyzer.analyzeBoard(pixelBuffer: pixelBuffer, boardCorners: detectedCorners) { [weak self] gridState in
                self?.onBoardStateDetected?(gridState)
            }
        }
    }
}
