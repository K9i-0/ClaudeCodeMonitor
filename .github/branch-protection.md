# Branch Protection Rules

This document describes the recommended branch protection rules for the `main` branch.

## Required Status Checks

Configure these status checks as required before merging:

### 1. Test Suite
- **Check name**: `Test on macOS (15.0)`
- **Check name**: `Test on macOS (15.2)`
- **Description**: Ensures all tests pass on multiple Xcode versions

### 2. Code Quality
- **Check name**: `SwiftLint`
- **Description**: Ensures code follows style guidelines

### 3. Build Verification
- **Check name**: `build`
- **Description**: Ensures the project builds successfully

### 4. Security Scan (optional)
- **Check name**: `security`
- **Description**: Runs security vulnerability scanning

## GitHub Settings

To configure these rules:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - ✅ Require a pull request before merging
     - ✅ Require approvals (1)
     - ✅ Dismiss stale pull request approvals when new commits are pushed
     - ✅ Require review from CODEOWNERS
   - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date before merging
     - Select required status checks:
       - `Test on macOS (15.0)`
       - `Test on macOS (15.2)`
       - `SwiftLint`
   - ✅ Require conversation resolution before merging
   - ✅ Include administrators

## Additional Recommendations

- Enable "Automatically delete head branches" in repository settings
- Consider enabling "Allow auto-merge" for approved PRs
- Set up branch naming conventions