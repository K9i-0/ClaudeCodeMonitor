# Branching Strategy

This project follows **GitHub Flow** - a simple and effective branching model.

## Main Branch
- `main` - The production-ready branch. All code here should be deployable.

## Feature Development

1. **Create a feature branch** from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit regularly
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

3. **Push to GitHub**
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request** to `main`
   - CI will run automatically
   - Request review if needed

5. **Merge** after approval and CI passes

## Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes
- `ci/` - CI/CD related changes

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, semicolons, etc)
- `refactor:` - Code refactoring
- `test:` - Test additions or fixes
- `chore:` - Build process or auxiliary tool changes

## Release Process

1. Create a release branch if needed for final adjustments
2. Tag the release on `main`
3. GitHub Actions will automatically build and create a release