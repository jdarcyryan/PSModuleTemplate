# Contributing

## Prerequisite Software
* Git
* Make
* PowerShell Core (v7 or later)

## How to Contribute

### 1. Fork the Repository

Create your own copy of the project by clicking the "[Fork](https://github.com/jdarcyryan/PSModuleTemplate/fork)" button at the top right of the repository page.

### 2. Clone Your Fork

Download your fork to your local machine:

```bash
git clone https://github.com/OWNER/PSModuleTemplate.git
cd PSModuleTemplate
```

### 3. Create a Branch

Make a new branch for your changes (don't work directly on main/master):

```bash
git checkout -b your-branch-name
```

Use a descriptive branch name like `fix-bug-123` or `add-feature-xyz`.

### 4. Make Your Changes

Edit code, add features, fix bugs, or improve documentation as needed.

### 5. Test Your Changes

Before committing, ensure your changes work correctly:

#### Initial Setup
```bash
make setup
```
This will set up an example module for testing.

#### Build the Module
```bash
make build
```
Review the build output to ensure there are no errors.

#### Run Pester Tests
```bash
make pester
```
All tests should pass before submitting your pull request.

#### Additional Testing Requirements

- **If you modify Pester tests**: Create example functions and ensure to reference GitHub Actions runs on your forked repository
- **If you modify scripts or workflows**: Verify that the associated pipelines run correctly in your fork

### 6. Commit Your Changes

Save your work with clear, descriptive commit messages:

```bash
git add .
git commit -m "Brief description of your changes"
```

### 7. Push to Your Fork

Upload your branch to your GitHub fork:

```bash
git push origin your-branch-name
```

### 8. Open a Pull Request

Go to the original repository on GitHub and click "New Pull Request". Select your fork and branch, then provide a clear description of your changes.

## Guidelines

- Write clear commit messages
- Follow the existing code style
- Test your changes before submitting
- Update documentation if needed
- Be respectful and constructive in discussions

## Questions?

If you have questions or need help, feel free to open an issue.

Thank you for contributing!
