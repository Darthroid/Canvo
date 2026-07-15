# Canvo

<a href="https://apps.apple.com/app/apple-store/id6761765531?pt=128746542&ct=github&mt=8">
  <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="40">
</a>

<p align="left">
  <img alt="iOS 18+" src="https://img.shields.io/badge/iOS-18%2B-000000?logo=apple&logoColor=white">
  <img alt="visionOS 26+" src="https://img.shields.io/badge/visionOS-26%2B-000000?logo=apple&logoColor=white">
  <img alt="Swift 6" src="https://img.shields.io/badge/Swift-6-orange?logo=swift">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-interface-0A84FF">
  <img alt="SwiftData" src="https://img.shields.io/badge/SwiftData-persistence-5E5CE6">
  <img alt="Apple Foundation Models" src="https://img.shields.io/badge/Apple%20Foundation%20Models-iOS%2026%2B-000000?logo=apple&logoColor=white">
</p>

Canvo is an AI-powered visual thinking application for building connected knowledge, brainstorming ideas, planning projects, and organizing information on a flexible canvas.

Built entirely with **SwiftUI**, **SwiftData**, and **Apple Foundation Models**, Canvo demonstrates a modern Apple-platform architecture with native AI integration, command-based editing, and support for both **iOS** and **visionOS**.

---

# Screenshots

## iOS

<img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/1.png" width="160"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/2.png" width="160"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/3.png" width="160"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/4.png" width="160"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/5.png" width="160">

## visionOS

<img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/vision1.png" width="400"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/vision2.png" width="400">

<img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/vision3.png" width="400"><img src="https://github.com/Darthroid/Canvo/blob/main/Screenshots/vision4.png" width="400">

---

# Features

### Visual Canvas

- Interactive node-based canvas
- Unlimited node connections
- Rich text notes
- Image attachments
- Tag system
- Search and filtering

### AI

Powered by Apple Foundation Models.

- Generate complete canvases from prompts
- Expand existing nodes
- Summarize branches
- Simplify complex structures
- Explain concepts
- Continue idea generation

### Import & Export

- JSON
- Markdown
- Markdown Package

### Productivity

- Undo / Redo
- Canvas previews
- Spotlight indexing
- Multiple themes
- Focus mode
- Secure canvases

### visionOS

- Native immersive canvas
- Spatial interaction
- 3D node visualization

---

# Architecture

Canvo follows a feature-oriented architecture with a clear separation between UI, business logic and persistence.

```
                App
                 │
        ┌────────┴────────┐
        │                 │
    Features           Core
        │                 │
        │          Services
        │          Repository
        │          Actions
        │          AI
        │          Domain
        │
    SwiftUI Views
```

More details are available in **ARCHITECTURE.md**.

---

# Project Structure

```
Canvo
├── App
├── Core
│   ├── Actions
│   ├── AI
│   ├── Domain
│   ├── Repository
│   ├── Services
│   ├── Theme
│   └── State
├── Features
└── Resources
```

---

# Building

## Requirements

- Xcode 26.3+
- Swift 6
- iOS 18+
- visionOS 26+

## Clone

```bash
git clone https://github.com/Darthroid/Canvo.git
```

Open `Canvo.xcodeproj` and run the project.

---

<br>
<a href="https://raw.githubusercontent.com/Darthroid/Canvo-documentation/refs/heads/main/privacy.md">
  Privacy Policy
</a>
<br><br>
