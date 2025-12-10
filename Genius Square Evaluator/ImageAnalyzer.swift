//
//  ImageAnalyzer.swift
//  Genius Square Evaluator
//
//  Analyzes camera frames to detect board state
//

import Foundation
import Vision
import CoreImage
import UIKit

class ImageAnalyzer {
    func analyzeBoard(
        pixelBuffer: CVPixelBuffer,
        boardCorners: [CGPoint],
        completion: @escaping ([[BoardDetector.CellState]]) -> Void
    ) {
        guard boardCorners.count == 4 else {
            completion(Array(repeating: Array(repeating: .empty, count: 6), count: 6))
            return
        }

        // Create CIImage from pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // TODO: Perform perspective correction to get a top-down view
        // For now, we'll sample grid cells directly

        var gridState = Array(repeating: Array(repeating: BoardDetector.CellState.empty, count: 6), count: 6)

        // Sample each grid cell to determine its state
        let context = CIContext()

        for row in 0..<6 {
            for col in 0..<6 {
                let cellCenter = calculateCellCenter(row: row, col: col, corners: boardCorners)
                let cellState = analyzeCellAtPoint(cellCenter, in: ciImage, context: context)
                gridState[row][col] = cellState
            }
        }

        completion(gridState)
    }

    private func calculateCellCenter(row: Int, col: Int, corners: [CGPoint]) -> CGPoint {
        // Interpolate position within the quadrilateral
        // corners: [topLeft, topRight, bottomRight, bottomLeft]

        let topLeft = corners[0]
        let topRight = corners[1]
        let bottomRight = corners[2]
        let bottomLeft = corners[3]

        // Calculate position as fraction of grid (0-1)
        let xFrac = (CGFloat(col) + 0.5) / 6.0
        let yFrac = (CGFloat(row) + 0.5) / 6.0

        // Bilinear interpolation
        let topX = topLeft.x + (topRight.x - topLeft.x) * xFrac
        let topY = topLeft.y + (topRight.y - topLeft.y) * xFrac

        let bottomX = bottomLeft.x + (bottomRight.x - bottomLeft.x) * xFrac
        let bottomY = bottomLeft.y + (bottomRight.y - bottomLeft.y) * xFrac

        let x = topX + (bottomX - topX) * yFrac
        let y = topY + (bottomY - topY) * yFrac

        return CGPoint(x: x, y: y)
    }

    private func analyzeCellAtPoint(
        _ point: CGPoint,
        in image: CIImage,
        context: CIContext
    ) -> BoardDetector.CellState {
        // Sample a small region around the point
        let sampleSize: CGFloat = 20
        let rect = CGRect(
            x: point.x * image.extent.width - sampleSize / 2,
            y: point.y * image.extent.height - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        guard let cgImage = context.createCGImage(image, from: rect) else {
            return .empty
        }

        // Analyze the color to determine cell state
        let avgColor = averageColor(of: cgImage)

        // Detect based on color heuristics
        // Blockers are typically dark/black
        // Pieces are colorful (various colors)
        // Empty cells are light (board color)

        let brightness = (avgColor.red + avgColor.green + avgColor.blue) / 3

        if brightness < 0.3 {
            // Dark - likely a blocker
            return .blocker
        } else if avgColor.red > 0.4 || avgColor.green > 0.4 || avgColor.blue > 0.4 {
            // Colorful - likely a piece
            // TODO: Identify specific piece by color/pattern
            let pieceId = identifyPieceByColor(avgColor)
            return .piece(pieceId)
        } else {
            // Light - empty cell
            return .empty
        }
    }

    private func averageColor(of image: CGImage) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0

        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            totalRed += CGFloat(pixelData[i])
            totalGreen += CGFloat(pixelData[i + 1])
            totalBlue += CGFloat(pixelData[i + 2])
        }

        let pixelCount = CGFloat(width * height)

        return (
            red: totalRed / (pixelCount * 255),
            green: totalGreen / (pixelCount * 255),
            blue: totalBlue / (pixelCount * 255)
        )
    }

    private func identifyPieceByColor(_ color: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Int {
        // Map colors to piece IDs
        // This is a simplified heuristic - you may need to calibrate based on actual piece colors

        if color.red > color.green && color.red > color.blue {
            return 0  // Red-ish
        } else if color.green > color.red && color.green > color.blue {
            return 1  // Green-ish
        } else if color.blue > color.red && color.blue > color.green {
            return 2  // Blue-ish
        } else if color.red > 0.5 && color.green > 0.5 {
            return 3  // Yellow-ish
        } else if color.red > 0.5 && color.blue > 0.5 {
            return 4  // Magenta-ish
        } else if color.green > 0.5 && color.blue > 0.5 {
            return 5  // Cyan-ish
        } else if color.red > 0.6 && color.green > 0.4 {
            return 6  // Orange-ish
        } else if color.red > 0.4 && color.green < 0.3 && color.blue > 0.3 {
            return 7  // Purple-ish
        } else {
            return 8  // Default
        }
    }
}
