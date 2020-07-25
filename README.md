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
   release version is `v2.0.1`.
```bash
./deploy.py -v 2.0.1 <PREFIX>
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
  -l, --local           Local deploy, will not install the modulefiles (you will have
                        to run the launcher scripts from their relative paths).
  -f, --force           Force-overwrite already downloaded container with the same name.
```


3. To use the container in installed mode, you can load the modulefile, 
   and then use the included apps as if they are native apps on your system!
```bash
module load eic_container
```

4. To use the container in local mode, you can run the runscripts (under `$PREFIX/bin`)
   manually.

4. (Advanced) If you need to add additional bind directives for the internal singularity container,
   you can add them with the `-b` flag. Run `./deploy.py -h` to see a list of all
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

1. This is assuming you deployed with the `-l` flag to a prefix `$PREFIX`:
```bash
./deploy.py $PREFIX
```

2. To start a shell in the container environment, do
```bash
$PREFIX/bin/eic-shell
```

### C. Using the docker container for your CI purposes

1. To load the container environment in your run scripts, you can 
   - launch the script or program using `eic-shell`,
   - or `source /etc/eic-env.sh` at the start of your commands.

2. If using this container as a basis for a new container, you can direction access 
   the full container environment from a docker `RUN` shell command with no further
   action needed. For the most optimal experience, you can install your software to
   `/opt/view` to fully integrate with the existing environment. Depending on your
   use case, installation to `/usr/local` may also work, but this might require you
   to write and run additional environment scripts.
