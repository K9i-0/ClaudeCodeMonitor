# Contributing to ClaudeCodeMonitor

First off, thank you for considering contributing to ClaudeCodeMonitor! It's people like you that make ClaudeCodeMonitor such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem
* **Describe the exact steps which reproduce the problem** in as many details as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior
* **Explain which behavior you expected to see instead and why**
* **Include screenshots and animated GIFs** if possible
* **Include your environment details** (macOS version, Node.js version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why
* **Explain why this enhancement would be useful** to most ClaudeCodeMonitor users

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing code style
6. Issue that pull request!

## Development Setup

### Prerequisites

* macOS 13.0 or later
* Xcode 15 or later
* Swift 5.9 or later
* Node.js (for ccusage CLI)

### Building

```bash
# Clone the repository
git clone https://github.com/K9i-0/ClaudeCodeUsageMonitor.git
cd ClaudeCodeUsageMonitor

# Build with Swift
swift build

# Or open in Xcode
open Package.swift
```

### Running Tests

```bash
swift test
```

### Code Style

* Use Swift's standard naming conventions
* Follow the existing code formatting
* Use meaningful variable and function names
* Add comments for complex logic
* Keep functions small and focused

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

## License

By contributing, you agree that your contributions will be licensed under the MIT License.