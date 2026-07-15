# Contributing

Thank you for your interest in contributing to Canvo.

At the moment, this project is primarily maintained by a single developer, but contributions, bug reports, feature suggestions, and discussions are always welcome.

---

# Before You Start

Please open an Issue before implementing large features or architectural changes.

This helps avoid duplicated work and ensures that the proposed solution aligns with the project's direction.

For small bug fixes, documentation improvements, or minor UI adjustments, feel free to submit a Pull Request directly.

---

# Development Requirements

* Xcode 26.3 or newer
* Swift 6
* iOS 18+
* visionOS 26+

---

# Project Principles

Canvo follows several architectural principles.

## Feature-oriented structure

UI code is organized by features rather than by view type.

```
Features/
    Canvas Editor/
    Canvas List/
    Node Editor/
    Settings/
```

---

## Business logic belongs in Core

Application logic should remain independent from SwiftUI whenever possible.

Examples include:

* Services
* Repository
* Actions
* AI
* Domain models

---

## Command-based editing

All canvas modifications should be represented as Actions.

Instead of mutating models directly:

* create an Action
* execute it through `ActionService`
* support Undo / Redo automatically

Direct mutations should be avoided unless there is a compelling reason.

---

## Small Services

Services should have a single responsibility.

Prefer multiple focused services instead of one large "manager" object.

---

## SwiftUI

Views should remain lightweight.

Business logic should not live inside SwiftUI views.

---

# Code Style

## Naming

Use descriptive names.

Prefer:

* `CanvasLayoutService`
* `ImportService`
* `NodeGraphService`

Avoid abbreviations unless they are well known.

---

## Files

One primary type per file whenever practical.

Split large files using extensions if they become difficult to navigate.

Example:

```
NodeMapView.swift
NodeMapView+Gestures.swift
NodeMapView+Export.swift
NodeMapView+Preview.swift
```

---

## Extensions

Only create extensions when they add meaningful functionality.

Avoid creating extensions that contain a single trivial helper.

---

## Services

Services should generally be stateless.

If a service maintains state, it should have a clear reason for doing so.

---

# Pull Requests

Please ensure that:

* the project builds successfully
* no compiler warnings are introduced
* existing functionality continues to work
* new functionality follows the existing architecture
* unrelated formatting changes are avoided

Keep pull requests focused on a single topic whenever possible.

---

# Reporting Bugs

When reporting a bug, please include:

* device
* iOS / visionOS version
* steps to reproduce
* expected behavior
* actual behavior
* screenshots or screen recordings if applicable

---

# Feature Requests

Feature requests are welcome.

When possible, include:

* the problem you're trying to solve
* your proposed solution
* alternative approaches considered

---

# Discussions

Questions, architectural discussions, and ideas are welcome through GitHub Issues.

---

# License

By contributing to Canvo, you agree that your contributions will be licensed under the same license as the project.
