EIC software container
============================================

Simple Installation
------------

*The environment has been tested on linux (requires singularity v3+) and MacOS (requires
docker)*

Please follow the steps below to setup and run the container in your environment.

1. Create a local directory that you want to work in, e.g `$HOME/eic`, and go into this
   directory.
```bash
mkdir $HOME/eic
cd $HOME/eic
```

2. Execute the following line in your terminal to setup your environment in this directory
   to install the latest stable container
```bash
curl https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/install.sh | bash
```

3. You can now load your development environment by executing the `eic-shell` script that
   is in your top-level working directory.
```bash
eic-shell
```

4. Within your development environment (`eic-shell`), you can install software to the
   internal `$EIC_SHELL_PREFIX`

Singularity Container setup for Development Usage
-------------
**Note: this container download script is meant for expert usage. If it is unclear to you
why you would want to do this, you are probably looking for the simple `jug_xl` installation
above.**

You can use the same install scripts to setup other container setups, including `jug_dev`
(the main development container). Note that for `jug_dev` there is no nighlty release, and
the appropriate version (tag) would be `testing`.  To setup the `jug_dev:testing` environment, do
```bash
curl https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/install.sh | bash -s -- -c jug_dev -v testing
```

Included software:
------------------
  - Included software (for the exact versions, check the file [spack.yaml](spack.yaml) or use the command `eic-info` inside the container):
    - gcc
    - madx
    - cmake
    - fmt cxxstd=17
    - spdlog
    - nlohmann-json
    - heppdt
    - clhep cxxstd=17
    - eigen
    - python
    - py-numpy
    - py-pip
    - pkg-config
    - xrootd cxxstd=17 +python
    - root cxxstd=17 
          +fftw +fortran +gdml +http +mlp +pythia8 
          +root7 +tmva +vc +xrootd +ssl 
          ^mesa swr=none +opengl -llvm -osmesa
    - pythia8 +fastjet
    - fastjet
    - hepmc3 +python +rootio 
    - stow
    - cairo +fc+ft+X+pdf+gobject
    - podio
    - geant4 cxxstd=17 +opengl +vecgeom +x11 +qt +threads ^qt +opengl
    - dd4hep +geant4 +assimp +hepmc3 +ipo +lcio
    - acts +dd4hep +digitization +identification +json +tgeo +ipo +examples +fatras +geant4
    - genfit
    - gaudi
    - dawn
    - dawncut
    - opencascade
    - emacs toolkit=athena
    - imagemagick
    - igprof
  - The singularity build exports the following applications:
    - eic-shell: a development shell in the image

Using the docker container for your CI purposes
-----------------------------------------------

**These instructions are old and need updating. In general we recommend using
`eicweb/juggler:latest` for most CI usages. This image is functionally identical to
`jug_xl:nightly`**

The docker containers are publicly accessible from
[Dockerhub](https://hub.docker.com/u/eicweb). You probably want to use the default
`jug_xl` container. Relevant versions are:
 - `eicweb/jug_xl:nightly`: nightly release, with latest detector and reconstruction
   version. This is probably what you want to use unless you are dispatching a large
   simulation/reconstruciton job
 - `eicweb/jug_xl:3.0-stable`: latest stable release, what you want to use for large
   simulation jobs (for reproducibility). Please coordinate with the software group to
   ensure all desired software changes are present in this container.

1. To load the container environment in your run scripts, you have to do nothing special.  
   The environment is already setup with good defaults, so you can use all the programs 
   in the container as usual and assume everything needed to run the included software 
   is already setup.  

2. If using this container as a basis for a new container, you can direction access 
   the full container environment from a docker `RUN` shell command with no further
   action needed. For the most optimal experience, you can install your software to
   `/usr/local` to fully integrate with the existing environment. (Note that, internally,
   `/usr/local` is a symlink to `/opt/view`).

