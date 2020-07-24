EIC software container
============================================

Installation
------------

1. Clone the repository and go into the directory
```bash
git clone https://eicweb.phy.anl.gov/containers/eic_container.git
cd eic_container
```

2. Run the deploy script `deploy.py` to install to your `<PREFIX>` of choice 
   (e.g. $HOME/local/opt/eic_container_1.0.4). By default the
   modelefile will be installed to `$PREFIX/../../etc/modulefiles`. 
   You can use the `-v` flag to select the version you want to deploy, or omit the 
   flag if you want to install the master build. The recommended stable 
   release version is `v2.0.0`.
```bash
./deploy.py -v 2.0.0 <PREFIX>
```

   Available flags:
```bash
  -v VERSION, --version VERSION 
                        (opt.) project version. Default: current git branch/tag.
  -b BIND_PATHS, --bind-path BIND_PATHS
                        (opt.) extra bind paths for singularity.
  -m MODULE_PATH, --module-path MODULE_PATH
                        (opt.) Root module path where you want to install a
                        modulefile. D: <prefix>/../../etc/modulefiles
  -f, --force           Force-overwrite already downloaded container with the same name.
  --install-builder BUILDER
                        (opt.) Install fat builder image, instead of normal
                        slim image
```


3. To use the container: load the modulefile, and then use the included apps as if
   they are native apps on your system!
```bash
module load eic_container
```

4. (Advanced) If you need to add additional bind directives for the internal singularity container,
   you can add them with the `-b` flag. Run `./deploy.py -h` to see a list of all
   supported options.
