# Notes

These Dev Containers are derived from the
[language](https://github.com/b-data/julia-docker-stack)
[docker](https://github.com/b-data/python-docker-stack)
[stacks](https://github.com/b-data/r-docker-stack), share their environment
variables and incorporate most tweaks and default settings of the
[JupyterLab](https://github.com/b-data/jupyterlab-julia-docker-stack)
[docker](https://github.com/b-data/jupyterlab-python-docker-stack)
[stacks](https://github.com/b-data/jupyterlab-r-docker-stack).

They depend on very few 
[Dev Container Features](https://containers.dev/features) and add some extra
customisation through build argument (`build.args`) and environment variables
(`remoteEnv`).

## Tweaks

In comparison to the
[rocker-org/devcontainer-images](https://github.com/rocker-org/devcontainer-images),
these Dev Containers are tweaked as follows:

### Startup scripts

**Julia images**

The following startup scripts are put in place:

* [$JULIA_PATH/etc/julia/startup.jl](https://github.com/b-data/julia-docker-stack/blob/main/base/conf/julia/etc/julia/startup.jl)
  to add the `LOAD_PATH` of the pre-installed packages
* [~/.julia/config/startup.jl](https://github.com/b-data/julia-docker-stack/blob/main/base/conf/user/var/backups/skel/.julia/config/startup.jl)
  to start [Revise](https://github.com/timholy/Revise.jl) and activate either
  the project environment or package directory.
* [~/.julia/config/startup_ijulia.jl](.devcontainer/julia-base/conf/user/etc/skel/.julia/config/startup_ijulia.jl)
  to register MIME type `application/pdf` to IJulia.

### Environment variables

**Julia images**

* `JULIA_VERSION`
* `JULIA_NUM_THREADS`: If unset (default), Julia starts up with a single thread
  of execution.  
  :point_right: User-settable at runtime.

**R images**

* `R_VERSION`
* `QGIS_VERSION` (R qgisprocess image)
* `OTB_VERSION` (R qgisprocess image)
* `CRAN`: The CRAN mirror URL.
* `DOWNLOAD_STATIC_LIBV8=1`: R (V8): Installing V8 on Linux, the alternative
  way.
* `RETICULATE_MINICONDA_ENABLED=0`: R (reticulate): Disable prompt to install
  miniconda.

**Versions**

* `PYTHON_VERSION`
* `JUPYTERLAB_VERSION`
* `GIT_VERSION`
* `GIT_LFS_VERSION`
* `PANDOC_VERSION`
* `QUARTO_VERSION` (Julia pubtools, Python scipy, R verse+ images)

**Miscellaneous**

* `BASE_IMAGE`: Its very base, a [Docker Official Image](https://hub.docker.com/search?q=&type=image&image_filter=official).
* `PARENT_IMAGE`: The image it was derived from.
* `PARENT_IMAGE_BUILD_DATE`: The date the parent image was built (ISO 8601
  format).
* `LANG`: The locale inside the container.  
  :point_right: User-settable at build time with `SET_LANG`.
* `TZ`: The timezone inside the container.  
  :point_right: User-settable at build time with `SET_TZ`.
* `PIP_USER`: The Python package install directory.  
  :point_right: User-settable at build time.
    * `1`: user directory (`~/.local`, persistent)
    * `0`: system directory (`/usr/local`, not persistent)
* `CTAN_REPO`: The CTAN mirror URL. (Julia pubtools, Python scipy, R verse+
  images)
* `OMP_NUM_THREADS`: If unset (default), BLAS/OpenMP will use as many
  threads as possible.  
  :point_right: User-settable at runtime.

### Shell

The default shell is Zsh.

### TeX packages (Julia pubtools, Python scipy, R verse+ images)

In addition to the TeX packages used in
[rocker/verse](https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_texlive.sh),
[jupyter/scipy-notebook](https://github.com/jupyter/docker-stacks/blob/main/scipy-notebook/Dockerfile)
and required for `nbconvert`, the
[packages requested by the community](https://yihui.org/gh/tinytex/tools/pkgs-yihui.txt)
are installed.

## Settings

### Default

* [IPython](.devcontainer/conf/ipython/usr/local/etc/ipython/ipython_config.py):
    * Only enable figure formats `svg` and `pdf` for IPython.
* [JupyterLab](.devcontainer/conf/jupyterlab/usr/local/share/jupyter/lab/settings/overrides.json):
    * Theme > Selected Theme: JupyterLab Dark
    * Python LSP Server: Example settings according to [jupyter-lsp/jupyterlab-lsp > Installation > Configuring the servers](https://github.com/jupyter-lsp/jupyterlab-lsp#configuring-the-servers)
* VS Code
    * Extensions > GitLab Workflow
        * Ai Assisted Code Suggestions: Enabled: false
    * Extensions > GitLens — Git supercharged
        * General > Show Welcome On Install: false
        * General > Show Whats New After Upgrade: false
        * Graph > Status Bar: Enabled: false
            * Graph commands disabled where possible
    * Extensions > Resource Monitor Configuration
        * Show: Battery: false
        * Show: Cpufreq: false
* Zsh
    * Oh My Zsh: `~/.zshrc`
        * Set PATH so it includes user's private bin if it exists

**Julia images**

* VS Code
    * Extensions > Julia
        * Enable Crash Reporter: false
        * Enable Telemetry: false

**R images**

* R: `$(R RHOME)/etc/Rprofile.site`
    * IRkernel: Only enable `image/svg+xml` and `application/pdf` for plot
    display.
    * R Extension (VS Code): Disable help panel and revert to old behaviour.
* [JupyterLab](.devcontainer/r-base/conf/jupyterlab/usr/local/share/jupyter/lab/settings/overrides.json):
    * R LSP Server: Example settings according to [jupyter-lsp/jupyterlab-lsp > Installation > Configuring the servers](https://github.com/jupyter-lsp/jupyterlab-lsp#configuring-the-servers)
* VS Code
    * Extensions > R
        * Bracketed Paste: true
        * Plot: Use Httpgd: true
        * Rterm: Linux: `/usr/local/bin/radian`
        * Rterm: Option: `["--no-save", "--no-restore"]`
        * Workspace Viewer: Show Object Size: true

### Customise

* IPython: Create file `~/.ipython/profile_default/ipython_config.py`
    * Valid figure formats: `png`, `retina`, `jpeg`, `svg`, `pdf`.
* JupyterLab: Settings > Advanced Settings Editor
* VS Code Server: Manage > Settings
* Zsh
    * Oh My Zsh: Edit `~/.zshrc`.

**R images**

* R: Create file `~/.Rprofile`
    * Valid plot mimetypes: `image/png`, `image/jpeg`, `image/svg+xml`,
    `application/pdf`.  
    :information_source: MIME type `text/plain` must always be specified.

## Python

The Python version is selected as follows:

* Julia/R images: The latest [Python version numba is compatible with](https://numba.readthedocs.io/en/stable/user/installing.html#numba-support-info).
* Python images: The latest Python version, regardless of whether all packages –
  such as numba, tensorflow, etc. – are already compatible with it.

This Python version is installed at `/usr/local/bin`.

# Additional notes on CUDA

The CUDA and OS versions are selected as follows:

* CUDA: The lastest version that has image flavour `devel` including cuDNN
  available.
* OS: The latest version that has TensortRT libraries for `amd64` available.  
  :information_source: It is taking quite a long time for these to be available
  for `arm64`.

## Tweaks

**R images**

* R: Provide NVBLAS-enabled `R_` and `Rscript_`.
    * Enabled at runtime and only if `nvidia-smi` and at least one GPU are
    present.

### Environment variables

**Versions**

* `CUDA_VERSION`

**Miscellaneous**

* `CUDA_IMAGE`: The CUDA image it is derived from.
* `CUDA_VISIBLE_DEVICES`: If unset (default), CUDA will use all available
  CUDA-capable devices.  
  :point_right: User-settable at runtime.

## Settings

### Default

**R images**

* VS Code
    * Extensions > R > Rterm: Linux: `/usr/local/bin/R`

## Basic Linear Algebra Subprograms (BLAS)

The **R images** use OpenBLAS by default.

To have `R` and `Rscript` use NVBLAS instead,

1. copy the NVBLAS-enabled executables to `~/.local/bin`  
   ```bash
   for file in $(which {R,Rscript}); do
     cp "$file"_ "~/.local/bin/$(basename "$file")";
   done
   ```
1. set Extensions > R > Rterm > Linux: `/home/USER/.local/bin/R` in VS Code
   settings  
   :point_right: Substitute `USER` with your user name.

and restart the R terminal.

:information_source: The
[xgboost](https://cran.r-project.org/package=xgboost) package benefits greatly
from NVBLAS, if it is
[installed correctly](https://xgboost.readthedocs.io/en/stable/build.html).

# Additional notes on `INSTALL_DEVTOOLS`

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

:information_source: Because [a more recent Python version](#python) is
installed at `/usr/local/bin`, it takes precedence over the system's Python
version.