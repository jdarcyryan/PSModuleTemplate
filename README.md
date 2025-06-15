# 🎯 PSModuleTemplate

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-Automated-success.svg)](https://github.com/features/actions)
[![Template](https://img.shields.io/badge/Template-Use%20This%20Template-brightgreen.svg)](https://github.com/jdarcyryan/PSModuleTemplate/generate)

A modern PowerShell module template with automated building and releasing via GitHub Actions. 🚀

## ✨ Features

- 🤖 **Automated CI/CD Pipeline**: GitHub Actions workflow for building and releasing your module
- 📈 **Intelligent Versioning**: Automatic version bumping based on commit messages
- 🏗️ **Professional Structure**: Organized module layout following PowerShell best practices
- 🔧 **Build System**: Flexible build script supporting multiple modes (Build, Setup, Ship)
- 📦 **Release Automation**: Automatic GitHub releases with downloadable artifacts
- 🎯 **Zero Configuration**: Works out of the box with sensible defaults

## 📋 Prerequisites

- ✅ PowerShell 5.1 or higher
- ✅ Git
- ✅ GitHub account (for automated releases)

## 🚀 Quick Start

### 1️⃣ Use This Template

Click the "Use this template" button on GitHub to create a new repository based on this template.

### 2️⃣ Clone Your New Repository

```powershell
git clone https://github.com/YOUR_USERNAME/YOUR_MODULE_NAME.git
cd YOUR_MODULE_NAME
```

### 3️⃣ Initial Setup

Run the setup script to initialize your module:

```powershell
.\build.ps1 -Mode Setup
```

This will:
- ✨ Create the module manifest (.psd1 file)
- 📁 Set up the initial module structure
- ⚙️ Configure module metadata

### 4️⃣ Customize Your Module

1. 📝 **Update Module Manifest**: Edit the `.psd1` file in your module directory with your module's information
2. 💻 **Add Your Code**: Place your PowerShell functions in the appropriate directories
3. 📚 **Update Documentation**: Modify this README to describe your specific module

## 🔨 Build Modes

The `build.ps1` script supports three modes:

### 🏗️ Build Mode (Development)
```powershell
.\build.ps1 -Mode Build
```
- 🔍 Compiles the module without versioning
- 💻 Used during development and for pull requests
- ⚡ Quick validation of module structure

### 🎨 Setup Mode (Initial Configuration)
```powershell
.\build.ps1 -Mode Setup
```
- 🆕 Initializes module manifest for new modules
- 📋 Sets up required files and structure
- 🎯 Run this once when starting a new module

### 🚢 Ship Mode (Release)
```powershell
.\build.ps1 -Mode Ship
```
- 📦 Builds the module with proper versioning
- 🎁 Prepares for release to PowerShell Gallery or distribution
- 🤖 Used by the automated release workflow

### 🔍 Verbose Output
Add `-Verbose` to any mode for detailed progress information:
```powershell
.\build.ps1 -Mode Build -Verbose
```

## 🤖 Automated Workflows

### 🔄 Continuous Integration

Every push to a pull request triggers the CI workflow that:
- ✅ Validates PowerShell syntax
- 🏗️ Builds the module
- 📊 Provides feedback on build status

### 🚀 Automated Releases

Pushing to the `main` branch triggers the release workflow that:

1. **🔢 Determines Version**: Analyzes commits to decide version bump type
   - 💥 `BREAKING CHANGE`, `!:`, or `breaking` → Major version bump (1.0.0 → 2.0.0)
   - ✨ `feat`, `feature`, `add`, or `new` → Minor version bump (1.0.0 → 1.1.0)
   - 🐛 All other commits → Patch version bump (1.0.0 → 1.0.1)

2. **🏗️ Builds Module**: Creates release-ready module with updated version

3. **📦 Creates Release**: Publishes GitHub release with:
   - 📝 Automatically generated release notes
   - 💾 Downloadable module ZIP file
   - 🏷️ Proper semantic versioning tag

### 🎮 Manual Release Control

You can also trigger a release manually with specific version bump:

1. Go to Actions → Release Module
2. Click "Run workflow" 
3. Select version bump type (auto, patch, minor, or major)

## 🏷️ Version Control

### 📝 Commit Message Conventions

For automatic version bumping, use these conventions in your commit messages:

#### 💥 Major Release (Breaking Changes)
- Include `BREAKING CHANGE:` in commit message
- Or use `!:` prefix: `!: Remove deprecated function`
- Or include words: `breaking`, `major`

#### ✨ Minor Release (New Features)
- Use prefixes: `feat:`, `feature:`
- Or include words: `add`, `new`
- Example: `feat: Add new Export-Data function`

#### 🐛 Patch Release (Bug Fixes)
- Any other commit message
- Common prefixes: `fix:`, `docs:`, `style:`, `refactor:`
- Example: `fix: Correct parameter validation`

## 💡 Pro Tips

1. **🎯 Keep commits atomic**: One feature/fix per commit for better version history
2. **✍️ Write clear commit messages**: They become your release notes
3. **🧪 Test locally**: Run `.\build.ps1 -Mode Build` before pushing
4. **🔒 Use branch protection**: Require PR reviews before merging to main
5. **📊 Monitor releases**: Check the Actions tab to see your automated releases

## 🚨 Troubleshooting

### ❌ Build Fails Locally
- 🔍 Ensure you have PowerShell 5.1+ installed
- 🐛 Check for syntax errors in your module files
- 📊 Run with `-Verbose` flag for detailed output

### ❌ GitHub Actions Fails
- 📋 Check the Actions tab for detailed error logs
- 📦 Ensure all module dependencies are properly declared
- 📁 Verify file paths match expected structure

### ❌ Release Not Creating
- 🎯 Confirm you're pushing to the `main` branch
- 🏷️ Check that previous releases don't have conflicting tags
- 💬 Ensure your commit messages follow conventions

## 📄 License

This template is provided as-is. Remember to add your own LICENSE file for your module.

## 🤝 Contributing

To contribute to this template:
1. 🍴 Fork the repository
2. 🌿 Create a feature branch
3. 💻 Make your changes
4. 🚀 Submit a pull request

## 👤 Author

**James D'Arcy Ryan**

- 🐙 GitHub: [@jdarcyryan](https://github.com/jdarcyryan)
- 🌐 Template: [PSModuleTemplate](https://github.com/jdarcyryan/PSModuleTemplate)

---

Made with ❤️ for the PowerShell community