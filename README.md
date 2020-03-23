EIC software container
============================================

Installation
-----------

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

