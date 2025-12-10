//
//  GeniusSquareSolver.swift
//  Genius Square Evaluator
//
//  Solver for Genius Square puzzle
//

import Foundation

class GeniusSquareSolver {
    // The 9 pieces in Genius Square (represented as relative coordinates)
    // Each piece is defined by its cells relative to a starting position
    private let pieces: [[PieceShape]] = [
        // Piece 0: Single square
        [
            PieceShape(cells: [(0, 0)])
        ],
        // Piece 1: 2x1 domino (2 rotations)
        [
            PieceShape(cells: [(0, 0), (0, 1)]),
            PieceShape(cells: [(0, 0), (1, 0)])
        ],
        // Piece 2: 3x1 line (2 rotations)
        [
            PieceShape(cells: [(0, 0), (0, 1), (0, 2)]),
            PieceShape(cells: [(0, 0), (1, 0), (2, 0)])
        ],
        // Piece 3: L-shape (4 rotations)
        [
            PieceShape(cells: [(0, 0), (1, 0), (1, 1)]),
            PieceShape(cells: [(0, 0), (0, 1), (1, 0)]),
            PieceShape(cells: [(0, 0), (0, 1), (1, 1)]),
            PieceShape(cells: [(0, 1), (1, 0), (1, 1)])
        ],
        // Piece 4: T-shape (4 rotations)
        [
            PieceShape(cells: [(0, 0), (0, 1), (0, 2), (1, 1)]),
            PieceShape(cells: [(0, 1), (1, 0), (1, 1), (2, 1)]),
            PieceShape(cells: [(0, 1), (1, 0), (1, 1), (1, 2)]),
            PieceShape(cells: [(0, 0), (1, 0), (2, 0), (1, 1)])
        ],
        // Piece 5: Small L (4 rotations)
        [
            PieceShape(cells: [(0, 0), (1, 0), (2, 0), (2, 1)]),
            PieceShape(cells: [(0, 0), (0, 1), (0, 2), (1, 0)]),
            PieceShape(cells: [(0, 0), (0, 1), (1, 1), (2, 1)]),
            PieceShape(cells: [(0, 2), (1, 0), (1, 1), (1, 2)])
        ],
        // Piece 6: Z-shape (2 rotations)
        [
            PieceShape(cells: [(0, 0), (0, 1), (1, 1), (1, 2)]),
            PieceShape(cells: [(0, 1), (1, 0), (1, 1), (2, 0)])
        ],
        // Piece 7: Big L (4 rotations)
        [
            PieceShape(cells: [(0, 0), (1, 0), (2, 0), (3, 0), (3, 1)]),
            PieceShape(cells: [(0, 0), (0, 1), (0, 2), (0, 3), (1, 0)]),
            PieceShape(cells: [(0, 0), (0, 1), (1, 1), (2, 1), (3, 1)]),
            PieceShape(cells: [(0, 3), (1, 0), (1, 1), (1, 2), (1, 3)])
        ],
        // Piece 8: Plus sign (1 rotation)
        [
            PieceShape(cells: [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)])
        ]
    ]

    func findAllSolutions(blockers: [(row: Int, col: Int)]) -> [[Solution]] {
        var board = Array(repeating: Array(repeating: -1, count: 6), count: 6)

        // Place blockers (use -2 to mark blocked cells)
        for blocker in blockers {
            board[blocker.row][blocker.col] = -2
        }

        var solutions: [[Solution]] = []
        var currentSolution: [Solution] = []

        backtrack(board: &board, pieceIndex: 0, currentSolution: &currentSolution, allSolutions: &solutions)

        return solutions
    }

    private func backtrack(
        board: inout [[Int]],
        pieceIndex: Int,
        currentSolution: inout [Solution],
        allSolutions: inout [[Solution]]
    ) {
        // If all pieces placed, we found a solution
        if pieceIndex == 9 {
            allSolutions.append(currentSolution)
            return
        }

        // Try placing current piece in all positions and rotations
        for rotation in pieces[pieceIndex] {
            for startRow in 0..<6 {
                for startCol in 0..<6 {
                    if canPlace(board: board, piece: rotation, at: (startRow, startCol)) {
                        // Place the piece
                        let positions = place(board: &board, piece: rotation, at: (startRow, startCol), pieceId: pieceIndex)

                        currentSolution.append(Solution(pieceId: pieceIndex, positions: positions))

                        // Recurse to next piece
                        backtrack(board: &board, pieceIndex: pieceIndex + 1, currentSolution: &currentSolution, allSolutions: &allSolutions)

                        // Backtrack - remove the piece
                        currentSolution.removeLast()
                        remove(board: &board, positions: positions)
                    }
                }
            }
        }
    }

    private func canPlace(board: [[Int]], piece: PieceShape, at start: (Int, Int)) -> Bool {
        for cell in piece.cells {
            let row = start.0 + cell.0
            let col = start.1 + cell.1

            // Check bounds
            if row < 0 || row >= 6 || col < 0 || col >= 6 {
                return false
            }

            // Check if cell is occupied
            if board[row][col] != -1 {
                return false
            }
        }
        return true
    }

    private func place(board: inout [[Int]], piece: PieceShape, at start: (Int, Int), pieceId: Int) -> [(row: Int, col: Int)] {
        var positions: [(row: Int, col: Int)] = []

        for cell in piece.cells {
            let row = start.0 + cell.0
            let col = start.1 + cell.1
            board[row][col] = pieceId
            positions.append((row, col))
        }

        return positions
    }

    private func remove(board: inout [[Int]], positions: [(row: Int, col: Int)]) {
        for pos in positions {
            board[pos.row][pos.col] = -1
        }
    }
}

struct PieceShape {
    let cells: [(Int, Int)]  // Relative positions (row, col)
}
