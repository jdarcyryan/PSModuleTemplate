# PSModuleTemplate

A template repository for creating PowerShell modules with built-in CI/CD, testing, and best practices.

## About

PSModuleTemplate provides a standardized structure for developing PowerShell modules with automated testing, building, and deployment workflows.
Use this template to quickly bootstrap new PowerShell module projects with industry-standard tooling and practices.

## Features

- Pre-configured module structure
- Easy building and testing with make
- Pester testing framework integration
- GitHub Actions CI/CD workflows
- C# class support
- Automatic documentation

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/install)
- [Make](https://gnuwin32.sourceforge.net/packages/make.htm)
- [PowerShell Core](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)


### Using This Template

Click the '[Use this template](https://github.com/jdarcyryan/PSModuleTemplate/generate)' button at the top of this repository to create a new repository based on this template.

### Quick Start
```bash
# Clone your new repository
git clone https://github.com/OWNER/MODULE_NAME.git
cd MODULE_NAME

# Set up the module structure
make setup
```

## Usage

### Setting up your module

This creates a folder with the repository name, housing the module files/folders.
```bash
make setup
```

### Perform a build

This builds a nupkg from your source code into the .output folder.
```bash
make build
```

### Running tests

This runs all pester tests against the built module.
```bash
make pester
```

## Custom Scripts

For advanced scenarios that fall outside the standard module build process, two custom scripts are available.
These are intended for things like compiling native or foreign-language code, staging external binaries, or configuring specialised environments.

### Container Setup

`.build/scripts/Invoke-ContainerSetup.ps1`

Runs during environment or container initialisation. Use this for installing SDKs, runtimes, configuring environment variables, authenticating with external feeds, or validating toolchain versions before any build steps execute.

### Post Build

`.build/scripts/Invoke-PostBuild.ps1`

Runs after the module has been built to the output directory but before the nupkg is packed. Use this for copying compiled DLLs or native binaries into the output module folder, embedding additional metadata, signing output binaries, or staging any extra assets that need to be included in the final package.

## Pipelines

### Pull Request

On pull request, the module will be built and tested with the pester tests in your repository.
Another runner will execute, producing markdown documentation for exported functions.

### Merge to master

Once you merge your pull request, this will carry out the same steps but also release your package.
It will produce release notes, changelog and a nupkg in GitHub packages.

__Note__: _this will fail if the version is not bumped, or if the current version already exists as a release or package._

### After merge

After merging to master, markdown files for each public function in the module will be created.
Ensure Get-Help is accurate and populated, as this will be referenced to create the documentation.

## Contributing

We welcome contributions! Please see [CONTRIBUTING](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 James D'Arcy Ryan

## Author

**James D'Arcy Ryan**

- GitHub: [@jdarcyryan](https://github.com/jdarcyryan)

## Acknowledgments

Thank you to all contributors who help improve this template!