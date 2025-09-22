# Notes

These dev containers are derived from the
[lan](https://github.com/b-data/julia-docker-stack)[guage](https://github.com/b-data/mojo-docker-stack)
[docker](https://github.com/b-data/python-docker-stack)
[stacks](https://github.com/b-data/r-docker-stack), share their environment
variables and incorporate most tweaks and default settings of the
[Jupyter](https://github.com/b-data/jupyterlab-julia-docker-stack)[Lab](https://github.com/b-data/jupyterlab-mojo-docker-stack)
[docker](https://github.com/b-data/jupyterlab-python-docker-stack)
[stacks](https://github.com/b-data/jupyterlab-r-docker-stack).

They depend on very few
[Dev Container Features](https://containers.dev/features) and add some extra
customisation through build argument (`build.args`) and environment variables
(`remoteEnv`).  
:information_source: See [Notes on `INSTALL_DEVTOOLS`](DEVTOOLS_NOTES.md).

## Tweaks

In comparison to the
[rocker-org/devcontainer-images](https://github.com/rocker-org/devcontainer-images),
these dev containers are tweaked as follows:

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
* `QGIS_VERSION` ((CUDA) R qgisprocess image)
* `OTB_VERSION` ((CUDA) R qgisprocess image)
* `CRAN`: The CRAN mirror URL.  
  :point_right: User-settable at build time.
* `R_BINARY_PACKAGES`: R package type to use.  
  :point_right: User-settable at build time.
  * unset: Source packages. (default)
  * `1`/`yes`: Binary packages.
* `DOWNLOAD_STATIC_LIBV8=1`: R (V8): Installing V8 on Linux, the alternative
  way.
* `RETICULATE_MINICONDA_ENABLED=0`: R (reticulate): Disable prompt to install
  miniconda.
* `QT_QPA_PLATFORM` ((CUDA) R qgisprocess image): Qt Platform Plugin to use.  
  :point_right: User-settable at runtime.
  * `offscreen`: Renders to an offscreen buffer. (default)
  * unset: Auto-detect Qt Platform Plugin.
* `LIBGL_ALWAYS_SOFTWARE=1` ((CUDA) R qgisprocess image): Always use software
  rendering.  
  :point_right: User-settable at runtime.
* `VGL_DISPLAY=egl` ((CUDA) R qgisprocess image): Use the EGL backend to enable
  OpenGL rendering without an X server.  
  :point_right: User-settable at runtime.

**MAX/Mojo images**

* `MOJO_VERSION`
* `MODULAR_HOME`

**Versions**

* `PYTHON_VERSION`
* `JUPYTERLAB_VERSION`
* `GIT_VERSION`
* `GIT_LFS_VERSION`
* `PANDOC_VERSION`
* `QUARTO_VERSION` (Julia pubtools, MAX/Mojo/Python scipy, R verse+ images)

**Miscellaneous**

* `BASE_IMAGE`: Its very base, a [Docker Official Image](https://hub.docker.com/search?q=&type=image&image_filter=official).
* `PARENT_IMAGE`: The image it was derived from.
* `PARENT_IMAGE_BUILD_DATE`: The date the parent image was built (ISO 8601
  format).
* `LANG`: The locale inside the container.  
  :point_right: User-settable at build time.
* `TZ`: The timezone inside the container.  
  :point_right: User-settable at build time.
* `PIP_USER`: The Python package install directory.  
  :point_right: User-settable at runtime.
  * `1`: user directory (`~/.local`, persistent (default))
  * `0`: system directory (`/usr/local`, not persistent)
* `CTAN_REPO`: The CTAN mirror URL. (Julia pubtools, MAX/Mojo/Python scipy, R
  verse+ images)
* `OMP_NUM_THREADS`: If unset (default), BLAS/OpenMP will use as many
  threads as possible.  
  :point_right: User-settable at runtime.

### Shell

The default shell is Zsh.

### TeX packages (Julia pubtools, MAX/Mojo/Python scipy, R verse+ images)

In addition to the TeX packages used in
[rocker/verse](https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_texlive.sh),
[jupyter/scipy-notebook](https://github.com/jupyter/docker-stacks/blob/main/images/scipy-notebook/Dockerfile)
and required for `nbconvert`, the
[packages requested by the community](https://yihui.org/gh/tinytex/tools/pkgs-yihui.txt)
are installed.

## Settings

### Default

* [IPython](.devcontainer/conf/ipython/usr/local/etc/ipython/ipython_config.py):
  * Only enable figure formats `svg` and `pdf` for IPython.
* [JupyterLab](.devcontainer/conf/jupyterlab/usr/local/share/jupyter/lab/settings/overrides.json):
  * Theme > Selected Theme: JupyterLab Dark
  * Python LSP Server: Example settings according to
    [jupyter-lsp/jupyterlab-lsp > Installation > Configuring the servers](https://github.com/jupyter-lsp/jupyterlab-lsp#configuring-the-servers)
* VS Code
  * Extensions > GitLab Workflow
    * GitLab Duo Pro > Duo Code Suggestions: false
    * GitLab Duo Pro > Duo Chat: false
    * GitLab Duo Pro > Duo Agent Platform: false
    * GitLab Duo Pro > Enabled Without Gitlab Project: false
  * Extensions > GitLens — Git supercharged
    * General > Show Welcome On Install: false
    * General > Show Whats New After Upgrade: false
  * Extensions > Resource Monitor Configuration
    * Show: Battery: false
    * Show: Cpufreq: false
* Zsh
  * Oh My Zsh: `~/.zshrc`
    * Set `PATH` so it includes user's private bin if it exists
* Bash: [/etc/skel/.profile](.devcontainer/conf/shell/etc/skel/.profile)
  * Update `PATH` for login shells, e.g. when started as a server associated
    with JupyterHub.

**Julia images**

* VS Code
  * Extensions > Julia
    * Enable Crash Reporter: false
    * Enable Telemetry: false

**MAX/Mojo images**

* [Mojo LSP Server](.devcontainer/mojo-base/conf/jupyterlab/usr/local/etc/jupyter/jupyter_server_config.d/mojo-lsp-server.json)

**R images**

* R: `$(R RHOME)/etc/Rprofile.site`
  * IRkernel: Only enable `image/svg+xml` and `application/pdf` for plot
    display.
  * R Extension (VS Code): Disable help panel and revert to old behaviour.
* [JupyterLab](.devcontainer/r-base/conf/jupyterlab/usr/local/share/jupyter/lab/settings/overrides.json):
  * R LSP Server: Example settings according to
    [jupyter-lsp/jupyterlab-lsp > Installation > Configuring the servers](https://github.com/jupyter-lsp/jupyterlab-lsp#configuring-the-servers)
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
* Bash
  * Edit `~/.bashrc`.

**R images**

* R: Create file `~/.Rprofile`
  * Valid plot mimetypes: `image/png`, `image/jpeg`, `image/svg+xml`,
    `application/pdf`.  
    :information_source: MIME type `text/plain` must always be specified.

## Python

The Python version is selected as follows:

* Julia/MAX/Mojo/R images: The latest Python version
  [Numba](https://numba.readthedocs.io/en/stable/user/installing.html#numba-support-info),
  [PyTorch](https://github.com/pytorch/pytorch/blob/main/RELEASE.md#release-compatibility-matrix)
  and
  [TensorFlow](https://www.tensorflow.org/install/source#cpu) are compatible
  with.
* Python images: The latest Python version, regardless of whether all packages –
  such as Numba, PyTorch, TensorFlow, etc. – are already compatible with it.

This Python version is installed at `/usr/local/bin`.
