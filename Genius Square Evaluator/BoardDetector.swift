//
//  BoardDetector.swift
//  Genius Square Evaluator
//
//  Detects board state and compares to solutions
//

import Foundation
import SwiftUI
import Vision
import Combine

class BoardDetector: ObservableObject {
    @Published var correctPieces: Int = -1
    @Published var boardCorners: [CGPoint] = []
    @Published var gridState: [[CellState]] = Array(repeating: Array(repeating: .empty, count: 6), count: 6)

    private var solver = GeniusSquareSolver()
    private var currentSolutions: [[Solution]] = []

    enum CellState: Equatable {
        case empty
        case blocker
        case piece(Int)  // Piece ID (0-8 for the 9 pieces)
    }

    func updateBoardCorners(_ corners: [CGPoint]) {
        self.boardCorners = corners
        // TODO: Trigger board state analysis
    }

    func updateGridState(_ newState: [[CellState]]) {
        self.gridState = newState
        analyzeBoard()
    }

    private func analyzeBoard() {
        // Extract blocker positions
        var blockers: [(row: Int, col: Int)] = []
        for row in 0..<6 {
            for col in 0..<6 {
                if gridState[row][col] == .blocker {
                    blockers.append((row, col))
                }
            }
        }

        // Get all solutions for this blocker configuration
        currentSolutions = solver.findAllSolutions(blockers: blockers)

        // Compare current piece positions to solutions
        correctPieces = calculateCorrectPieces()
    }

    private func calculateCorrectPieces() -> Int {
        guard !currentSolutions.isEmpty else { return 0 }

        // Extract currently placed pieces
        var placedPieces: [(pieceId: Int, positions: [(Int, Int)])] = []
        var pieceCells: [Int: [(Int, Int)]] = [:]

        for row in 0..<6 {
            for col in 0..<6 {
                if case .piece(let id) = gridState[row][col] {
                    if pieceCells[id] == nil {
                        pieceCells[id] = []
                    }
                    pieceCells[id]?.append((row, col))
                }
            }
        }

        placedPieces = pieceCells.map { (pieceId: $0.key, positions: $0.value) }

        // Find the best matching solution
        var maxCorrect = 0

        for solution in currentSolutions {
            var correct = 0

            for placedPiece in placedPieces {
                // Check if this piece exists in the solution and matches position
                if let solutionPiece = solution.first(where: { $0.pieceId == placedPiece.pieceId }) {
                    let placedSet = Set(placedPiece.positions.map { "\($0.0),\($0.1)" })
                    let solutionSet = Set(solutionPiece.positions.map { "\($0.row),\($0.col)" })

                    if placedSet == solutionSet {
                        correct += 1
                    }
                }
            }

            maxCorrect = max(maxCorrect, correct)
        }

        return maxCorrect
    }

    // Convert screen point to grid cell
    func pointToGridCell(_ point: CGPoint, in viewSize: CGSize) -> (row: Int, col: Int)? {
        guard boardCorners.count == 4 else { return nil }

        // TODO: Implement perspective transformation
        // For now, simple linear interpolation
        let topLeft = boardCorners[0]
        let topRight = boardCorners[1]
        let bottomRight = boardCorners[2]
        let bottomLeft = boardCorners[3]

        // Calculate relative position (0-1) within the quadrilateral
        // This is simplified - proper implementation needs perspective transform

        let relX = (point.x - topLeft.x) / (topRight.x - topLeft.x)
        let relY = (point.y - topLeft.y) / (bottomLeft.y - topLeft.y)

        let col = Int(relX * 6)
        let row = Int(relY * 6)

        guard row >= 0 && row < 6 && col >= 0 && col < 6 else { return nil }

        return (row, col)
    }
}

// Represents a placed piece in a solution
struct Solution {
    let pieceId: Int
    let positions: [(row: Int, col: Int)]
}
