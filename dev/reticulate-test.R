library(reticulate)
conda_env <- "quokka3"
envname <- ".quokka3-env"

use_python("/usr/local/Caskroom/miniconda/base/bin/python3")

virtualenv_create(envname = envname, packages = "pandas")

use_virtualenv(envname)

pd <- import("pandas")
os <- import("os")
os$

conda_create(envname = conda_env, packages = c("pandas", "tiledb"))
conda_install

Sys.which("python")
