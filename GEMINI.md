# AirPosture

AirPosture is an iOS application designed to help users maintain good posture using the motion sensors in AirPod headphones (Pro/Max/3rd Gen).

## Project Overview

-   **Goal**: Detect when a user's head tilts forward excessively (bad posture) and alert them via audio ducking and a voice prompt.
-   **Core Technology**: `CoreMotion` (`CMHeadphoneMotionManager`) for tracking head pitch.
-   **User Feedback**: Audio alerts (ducking background music) and visual indicators (a dynamic "man figure" showing slouch level).

## Tech Stack

-   **Language**: Swift 5.0+
-   **UI Framework**: SwiftUI
-   **State Management**: `ObservableObject` / `@Published` properties (Combine).
-   **Audio**: `AVFoundation` (Headphone audio mixing policies).
-   **Build Tool**: `xcodegen` for project generation.

## key Components

### 1. `HeadphoneMotionManager.swift`
-   The central service managing the `CMHeadphoneMotionManager`.
-   **Responsibilities**:
    -   Connects/Disconnects from headphones.
    -   Provides real-time `pitch`, `roll`, `yaw` updates via `@Published` properties.
    -   Implements the "Bad Posture" detection logic based on a dynamic `badPostureThreshold`.
    -   Triggers callbacks (`onBadPosture`, `onGoodPosture`).

### 2. `AudioManager.swift`
-   Manages the app's audio session.
-   **Responsibilities**:
    -   Configures the audio session to mix with other apps (`.ambient` / `.duckOthers`).
    -   Plays the "Posture Warning" audio file.
    -   Ducks background audio when bad posture is detected.

### 3. `ContentView.swift`
-   The main user interface.
-   **Features**:
    -   **Connection Status**: Displays if AirPods are connected.
    -   **Start/Stop**: Toggle monitoring.
    -   **Visual Feedback**: Real-time pitch/roll values.
    -   **Sensitivity Slider**: Adjusts `badPostureThreshold` (Strict <-> Relaxed).
    -   **Man Figure Visualization**: A custom `Canvas` drawing that mimics the user's posture threshold setting.

## Development Workflow

### Setup & Build
This project uses `xcodegen` to generate the `.xcodeproj` file. Do not edit the project file directly if you can avoid it; update `project.yml` instead.

1.  **Generate Project**:
    ```bash
    xcodegen generate
    ```
2.  **Open Project**:
    ```bash
    open AirPosture.xcodeproj
    ```
3.  **Build**:
    Use Xcode (Cmd+B) or `xcodebuild`.
    **Note**: You must select a destination that supports CoreMotion (physical device recommended, though basic verification can be done on simulators).

### Testing
-   **Unit Tests**: Located in `AirPostureTests` or similar targets (if configured).
-   **Manual Testing**: Requires physical device + AirPods for full motion data. Simulators often provide limited or no motion data for headphones unless mocked.

## Project Structure
-   `AirPosture/`: Source code.
-   `project.yml`: XcodeGen configuration.
-   `GEMINI.md`: Project documentation.

## Common Issues
-   **No Motion Data**: Ensure AirPods are connected and worn. Some older iPads/iPhones may not support headphone motion.
-   **Build Errors**: If files are missing, re-run `xcodegen generate`.
