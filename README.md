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
   release version is `v1.0.4`.
```bash
./deploy.py -v 1.0.4 <PREFIX>
```

3. To use the container: load the modulefile, and then use the included apps as if
   they are native apps on your system!
```
module load eic_container
```

4. (Advanced) If you need to add additional bind directives for the internal singularity container,
   you can add them with the `-b` flag. Run `./deploy.py -h` to see a list of all
   supported options.


Installation (throug cmake)
---------------------------

*Use of the cmake-based deploy is deprecated, We recommend to use the `deploy.py` method
instead.*

1. Checkout the repository and create a build directory
```
git clone https://eicweb.phy.anl.gov/containers/eic_container.git
cd eic_containers && mkdir BUILD && cd BUILD
```

2. Configure the install for your environment, providing the appropriate `prefix` and
   `module_dir` you want to use.
```
cmake ../. -DCMAKE_INSTALL_PREFIX=$HOME/stow/development
```
or
```
cmake ../. -DCMAKE_INSTALL_PREFIX=<prefix> -DINSTALL_MODULE_DIR=<module_dir>
```

3. Download the container and install.
```
make install
```

4. To use the container: load the modulefile, and then use the included apps as if
   they are native to your system!
```
module load eic_container
```

