# Genius Square Evaluator

An iOS app that uses computer vision to detect a Genius Square puzzle board and provides real-time feedback on piece placement by showing how many pieces are correctly positioned toward a valid solution.

## Features

### Automatic Board Detection
- Uses Vision framework to automatically detect the Genius Square board
- Continuously tracks the board position in real-time
- Green overlay shows detected board boundaries

### Manual Calibration Fallback
- Tap the hand icon (top-right) to enter manual mode
- Drag the four yellow corner handles to precisely align with board corners
- Tap the camera icon to return to automatic detection

### Real-Time Solution Tracking
- Automatically detects blocker positions on the board
- Identifies placed puzzle pieces by color
- Compares current board state against all valid solutions
- Displays "X/9 pieces correct" counter at top of screen

## How It Works

### 1. Board Detection (CameraManager.swift)
- Captures live video feed from device camera
- Uses Vision's rectangle detection to find the board automatically
- Tracks board position continuously for smooth experience

### 2. Grid Analysis (ImageAnalyzer.swift)
- Maps detected board corners to a 6x6 grid
- Samples color at each grid cell to determine state:
  - Dark colors → blockers
  - Bright colors → puzzle pieces (identified by hue)
  - Light colors → empty cells

### 3. Solution Finding (GeniusSquareSolver.swift)
- Implements backtracking algorithm to find all valid solutions
- Defines all 9 Genius Square pieces with their rotations:
  - Piece 0: Single square (1 rotation)
  - Piece 1: 2x1 domino (2 rotations)
  - Piece 2: 3x1 line (2 rotations)
  - Piece 3: L-shape (4 rotations)
  - Piece 4: T-shape (4 rotations)
  - Piece 5: Small L (4 rotations)
  - Piece 6: Z-shape (2 rotations)
  - Piece 7: Big L (4 rotations)
  - Piece 8: Plus sign (1 rotation)

### 4. Piece Matching (BoardDetector.swift)
- Compares detected piece positions to all solutions
- Finds the solution that best matches current board state
- Counts how many pieces are correctly placed
- Updates counter in real-time as pieces are moved

## Project Structure

```
Genius Square Evaluator/
├── Genius_Square_EvaluatorApp.swift  # App entry point
├── ContentView.swift                  # Main UI with camera view
├── CameraView.swift                   # Camera preview component
├── CameraManager.swift                # Camera session & Vision detection
├── BoardDetector.swift                # Board state management
├── ImageAnalyzer.swift                # Grid cell color analysis
└── GeniusSquareSolver.swift          # Backtracking solver algorithm
```

## Requirements

- iOS 16.0+
- iPhone or iPad with camera
- Xcode 14.0+

## Camera Permissions

The app requires camera access to function. On first launch:
1. App will request camera permission
2. Tap "Allow" to grant access
3. If denied, go to Settings > Privacy & Security > Camera to enable

**Note:** You'll need to add camera usage description in Xcode:
1. Open project in Xcode
2. Select target "Genius Square Evaluator"
3. Go to Info tab
4. Add key: "Privacy - Camera Usage Description"
5. Set value: "Camera access is required to detect the Genius Square board and track piece placement."

## Usage Tips

### For Best Results:
- Position camera directly above board (aerial view)
- Ensure good, even lighting
- Keep camera steady or use a phone stand
- Make sure entire board is visible in frame

### Troubleshooting:
- **Board not detected?** → Tap hand icon and manually adjust corners
- **Incorrect piece count?** → Ensure good lighting and pieces are flat on board
- **Counter not updating?** → Blockers may not be detected correctly; verify lighting

## How to Build

1. Open `Genius Square Evaluator.xcodeproj` in Xcode
2. Select a simulator or connected iOS device
3. Press Cmd+R to build and run

Or build from command line:
```bash
xcodebuild -project "Genius Square Evaluator.xcodeproj" \
  -scheme "Genius Square Evaluator" \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## Current Limitations & Future Improvements

### Known Limitations:
1. **Color-based piece detection** - Currently identifies pieces by color heuristics which may not match actual Genius Square piece colors
2. **Simplified grid mapping** - Uses bilinear interpolation instead of full perspective transform
3. **No piece shape validation** - Doesn't verify detected piece shapes match expected piece geometry

### Future Enhancements:
1. **Calibration mode** - Allow users to identify which piece is which color
2. **Shape detection** - Use contour detection to identify pieces by shape
3. **Perspective correction** - Apply proper perspective transform for more accurate grid mapping
4. **Solution visualization** - Show overlay of where pieces should go (optional spoiler mode)
5. **Performance metrics** - Track solve time and show solution count
6. **Multi-board support** - Save and recall multiple board configurations

## Technical Details

### Vision Framework Usage
- `VNDetectRectanglesRequest` for board detection
- Configured for square-ish shapes (aspect ratio 0.8-1.2)
- Minimum size 30% of frame to avoid false positives

### Solver Algorithm
- Backtracking with constraint propagation
- Tries all piece rotations and positions
- Terminates when all 9 pieces are placed
- Returns all valid solutions (there can be multiple)

### Performance Optimizations
- Board state analysis throttled to 1 update per second
- Vision processing on background queue
- UI updates on main thread via Combine publishers

## License

This is a personal project for use with the Genius Square puzzle game.
