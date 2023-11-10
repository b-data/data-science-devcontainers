# Notes on `INSTALL_DEVTOOLS`

If `INSTALL_DEVTOOLS` is set, the required tools according to [microsoft/vscode > Wiki > How to Contribute](https://github.com/Microsoft/vscode/wiki/How-to-Contribute)
and [coder/code-server > Docs > Contributing](https://github.com/coder/code-server/blob/main/docs/CONTRIBUTING.md)
are installed.

Node.js is installed with corepack enabled by default. Use it to manage Yarn
and/or pnpm:

* [Installation | Yarn - Package Manager > Updating the global Yarn version](https://yarnpkg.com/getting-started/install#updating-the-global-yarn-version)
* [Installation | pnpm > Using Corepack](https://pnpm.io/installation#using-corepack)

## Environment variables

**Versions**

* `NODE_VERSION`

## System Python

Package `libsecret-1-dev` depends on `python3` from the system's package
repository.

The system's Python version is installed at `/usr/bin`.  

:information_source: Because a [more recent Python version](NOTES.md#python) is
installed at `/usr/local/bin`, it takes precedence over the system's Python
version.
