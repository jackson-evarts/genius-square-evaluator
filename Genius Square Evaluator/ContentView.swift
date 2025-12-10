//
//  ContentView.swift
//  Genius Square Evaluator
//
//  Created by Jackson Evarts on 12/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var boardDetector = BoardDetector()
    @State private var manualMode = false
    @State private var manualCorners: [CGPoint] = [
        CGPoint(x: 0.2, y: 0.2),  // Top-left
        CGPoint(x: 0.8, y: 0.2),  // Top-right
        CGPoint(x: 0.8, y: 0.8),  // Bottom-right
        CGPoint(x: 0.2, y: 0.8)   // Bottom-left
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera feed
                CameraView(session: cameraManager.session)
                    .ignoresSafeArea()
                    .onAppear {
                        cameraManager.startSession()
                        if !manualMode {
                            cameraManager.startDetection()
                        }

                        // Set up board state detection callback
                        cameraManager.onBoardStateDetected = { gridState in
                            DispatchQueue.main.async {
                                boardDetector.updateGridState(gridState)
                            }
                        }
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                    }

                // Detected board overlay
                if !manualMode && !cameraManager.detectedCorners.isEmpty {
                    BoardOverlay(corners: cameraManager.detectedCorners)
                        .stroke(Color.green, lineWidth: 3)
                }

                // Manual adjustment mode
                if manualMode {
                    ManualCornersView(
                        corners: $manualCorners,
                        geometry: geometry
                    )
                }

                // Top controls
                VStack {
                    HStack {
                        Text(boardDetector.correctPieces >= 0 ? "\(boardDetector.correctPieces)/9 pieces correct" : "Detecting...")
                            .font(.headline)
                            .padding(10)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)

                        Spacer()

                        Button(action: {
                            manualMode.toggle()
                            if manualMode {
                                cameraManager.stopDetection()
                            } else {
                                cameraManager.startDetection()
                            }
                        }) {
                            Image(systemName: manualMode ? "camera.viewfinder" : "hand.tap")
                                .font(.title2)
                                .padding(10)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    Spacer()

                    // Bottom info
                    if !cameraManager.permissionGranted {
                        Text("Camera permission required")
                            .font(.headline)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .onChange(of: cameraManager.detectedCorners) { corners in
                if !corners.isEmpty && !manualMode {
                    boardDetector.updateBoardCorners(corners)
                }
            }
            .onChange(of: manualCorners) { corners in
                if manualMode {
                    boardDetector.updateBoardCorners(corners)
                }
            }
        }
    }
}

struct BoardOverlay: Shape {
    let corners: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard corners.count == 4 else { return Path() }

        var path = Path()

        // Convert normalized Vision coordinates to screen coordinates
        let screenCorners = corners.map { corner in
            CGPoint(
                x: corner.x * rect.width,
                y: (1 - corner.y) * rect.height  // Flip Y axis
            )
        }

        path.move(to: screenCorners[0])
        for i in 1..<4 {
            path.addLine(to: screenCorners[i])
        }
        path.closeSubpath()

        return path
    }
}

struct ManualCornersView: View {
    @Binding var corners: [CGPoint]
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            // Draw lines connecting corners
            Path { path in
                let screenCorners = corners.map { corner in
                    CGPoint(
                        x: corner.x * geometry.size.width,
                        y: corner.y * geometry.size.height
                    )
                }

                path.move(to: screenCorners[0])
                for i in 1..<4 {
                    path.addLine(to: screenCorners[i])
                }
                path.closeSubpath()
            }
            .stroke(Color.yellow, lineWidth: 3)

            // Draggable corner handles
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .position(
                        x: corners[index].x * geometry.size.width,
                        y: corners[index].y * geometry.size.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                corners[index] = CGPoint(
                                    x: max(0, min(1, value.location.x / geometry.size.width)),
                                    y: max(0, min(1, value.location.y / geometry.size.height))
                                )
                            }
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
