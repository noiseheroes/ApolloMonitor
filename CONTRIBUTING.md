# Contributing to Apollo Monitor

Thank you for your interest in contributing to Apollo Monitor! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Universal Audio Apollo device (for testing)
- UA Console app installed

### Setting Up the Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ApolloMonitor.git
   cd ApolloMonitor
   ```

3. **Open the project in Xcode**:
   ```bash
   open ApolloMonitor.xcodeproj
   ```

4. **Select your Development Team** in Signing & Capabilities

5. **Build and Run** (⌘R)

## How to Contribute

### Reporting Bugs

- Check if the bug has already been reported in [Issues](https://github.com/noiseheroes/ApolloMonitor/issues)
- Use the **Bug Report** template when creating a new issue
- Include as much detail as possible (macOS version, Apollo device, steps to reproduce)

### Suggesting Features

- Check existing [Issues](https://github.com/noiseheroes/ApolloMonitor/issues) for similar suggestions
- Use the **Feature Request** template
- Explain the use case and how it benefits users

### Submitting Code

1. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines below

3. **Test your changes** thoroughly with a real Apollo device

4. **Commit with a clear message**:
   ```bash
   git commit -m "Add: brief description of your change"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request** against the `main` branch

## Code Style Guidelines

### Swift

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### SwiftUI

- Use `@StateObject` for owned observable objects
- Use `@ObservedObject` for passed observable objects
- Prefer computed properties over stored properties when possible
- Extract reusable views into separate structs

### Project Structure

```
ApolloMonitor/          # Main app target
ApolloMonitorWidget/    # Widget extension
Shared/                 # Shared code between targets
```

- Place new views in `ApolloMonitor/`
- Place shared models and controllers in `Shared/`
- Keep TCP-related code in `Shared/ApolloTCP.swift`

## Testing

Since this app interacts with hardware, automated testing is limited. Please:

- Test all changes with a real Apollo device
- Verify sync with UA Console works correctly
- Test on multiple macOS versions if possible
- Check for memory leaks using Instruments

## Pull Request Process

1. Update the README.md if needed
2. Update version numbers following [Semantic Versioning](https://semver.org/)
3. Your PR will be reviewed by maintainers
4. Address any feedback or requested changes
5. Once approved, your PR will be merged

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## Questions?

Feel free to open an issue with the **question** label if you need help or clarification.

---

Thank you for contributing to Apollo Monitor!
