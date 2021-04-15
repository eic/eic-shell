EIC software container
============================================

Installation
------------

1. Clone the repository and go into the directory
```bash
git clone https://eicweb.phy.anl.gov/containers/eic_container.git
cd eic_container
```

2. Run the install script `install.py` to install to your `<PREFIX>` of choice 
   (e.g. $HOME/local/opt/eic_container_1.0.4). By default the
   modeuefile will be installed to `$PREFIX/../../etc/modulefiles`. 
   You can use the `-v` flag to select the version you want to install, or omit the 
   flag if you want to install the master build. The recommended stable 
   release version is `v2.8.0`.
```bash
./install.py -v 2.8.0 <PREFIX>
```

   Available flags:
```bash
  -v VERSION, --version VERSION 
                        (opt.) project version. Default: current version (in repo).
  -b BIND_PATHS, --bind-path BIND_PATHS
                        (opt.) extra bind paths for singularity.
  -m MODULE_PATH, --module-path MODULE_PATH
                        (opt.) Root module path where you want to install a
                        modulefile. D: <prefix>/../../etc/modulefiles
  -l, --local           Local install, will not install the modulefiles (you will have
                        to run the launcher scripts from their relative paths).
  -f, --force           Force-overwrite already downloaded container with the same name.
```


3. To use the container in installed mode, you can load the modulefile, 
   and then use the included apps as if they are native apps on your system!
```bash
module load eic_container
```

4. To use the container in local mode, you can install the container with the `-l` flag,
   and then use the runscripts (under `$PREFIX/bin`) manually.
```bash
./install.py $PREFIX -l
...
$PREFIX/bin/eic-shell
```

4. (Advanced) If you need to add additional bind directives for the internal singularity container,
   you can add them with the `-b` flag. Run `./install.py -h` to see a list of all
   supported options.

Usage
-----

### A. Running the singularity development environment with modulefiles

1. Add the installed modulefile to your module path, e.g.,
```bash
module use <prefix>/../../etc/modulefiles
```

2. Load the eic container
```bash
module load eic_container
```

3. To start a shell in the container environment, do
```bash
eic-shell
```

### B. Running the singularity development locally (without modulefiles)

1. This is assuming you installed with the `-l` flag to a prefix `$PREFIX`:
```bash
./install.py $PREFIX
```

2. To start a shell in the container environment, do
```bash
$PREFIX/bin/eic-shell
```

### C. Using the docker container for your CI purposes

1. To load the container environment in your run scripts, you have to do nothing special.  
   The environment is already setup with good defaults, so you can use all the programs 
   in the container as usual and assume everything needed to run the included software 
   is already setup.  

2. If using this container as a basis for a new container, you can direction access 
   the full container environment from a docker `RUN` shell command with no further
   action needed. For the most optimal experience, you can install your software to
   `/usr/local` to fully integrate with the existing environment. (Note that, internally,
   `/usr/local` is a symlink to `/opt/view`).

Included software:
------------------
  - Included software:
    - gcc@10.2.1
    - cmake@3.20.0
    - fmt@7.1.2
    - spdlog@1.8.1
    - nlohmann-json
    - heppdt@3.04.01
    - clhep@2.4.4.0
    - eigen@3.3.9
    - python@3.7.8 with pip, numpy, pyyaml, pyafp,  matplotlib, ipython, scipy
    - xrootd@5.1.0
    - root@6.22.08
    - pythia8@8303
    - hepmc3@3.2.2 +python +rootio
    - stow@2.3.1
    - podio@0.13
    - geant4@10.7.1
    - dd4hep@1.16.1
    - acts@5.00.0
    - gaudi@34.0
    - dawn@3.91a
    - dawncut@1.54a
    - opencascade
  - The singularity build exports the following applications:
    - eic_shell: a development shell in the image
    - container_dev: same as EIC shell
    - ipython
