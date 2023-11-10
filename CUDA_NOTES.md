# Notes on CUDA

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

       for file in $(which {R,Rscript}); do
         cp "$file"_ "~/.local/bin/$(basename "$file")";
       done

1. set Extensions > R > Rterm > Linux: `/home/USER/.local/bin/R` in VS Code
   settings  
   :point_right: Substitute `USER` with your user name.

and restart the R terminal.

:information_source: The
[xgboost](https://cran.r-project.org/package=xgboost) package benefits greatly
from NVBLAS, if it is
[installed correctly](https://xgboost.readthedocs.io/en/stable/build.html).
