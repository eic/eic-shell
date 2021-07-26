EIC software container
============================================

Simple Installation
------------
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
   internal `$ATHENA_PREFIX`

Singularity Container Dowload for Development Usage
-------------
**Note: this container download script is meant for expert usage. If it is unclear to you
why you would want to do this, you are probably looking for the single installation
above.**
To download the `jug_dev:testing` base image, do
```bash
curl https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/download_dev.sh | bash
```
To download the `jug_xl:nightly` image, do
```bash
curl https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/download_dev.sh | bash -s -- -c jug_xl -v nightly
```

Using the docker container for your CI purposes
-----------------------------------------------

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

Included software:
------------------
  - Included software:
    - gcc@10.2.1
    - madx@5.06.1
    - cmake@3.20.0
    - fmt@7.1.2 cxxstd=17
    - spdlog@1.8.1
    - nlohmann-json@3.9.1
    - heppdt@3.04.01
    - clhep@2.4.4.0 cxxstd=17
    - eigen@3.3.9
    - python@3.7.8
    - py-numpy@1.20.1
    - py-pip@20.2
    - pkg-config@0.29.2
    - xrootd@5.1.0 cxxstd=17 +python
    - root@6.22.08 cxxstd=17 
          +fftw +fortran +gdml +http +mlp +pythia8 
          +root7 +tmva +vc +xrootd +ssl 
          ^mesa swr=none +opengl -llvm -osmesa
    - pythia8@8303 +fastjet
    - fastjet@3.3.3
    - hepmc3@3.2.2 +python +rootio 
    - stow@2.3.1
    - cairo@1.16.0 +fc+ft+X+pdf+gobject
    - podio@0.13.1
    - geant4@10.7.1 cxxstd=17 +opengl +vecgeom +x11 +qt +threads ^qt +opengl
    - dd4hep@1.17 +geant4 +assimp +hepmc3 +ipo +lcio
    - acts@8.03.0p1 +dd4hep +digitization +identification +json +tgeo +ipo
    - genfit@2.00.00
    - gaudi@36.0
    - dawn@3_91a
    - dawncut@1_54a
    - opencascade@7.4.0p1
    - emacs@27.0:27.99 toolkit=athena
    - imagemagick@7.0.0:7.0.99
    - igprof@5.9.16
  - The singularity build exports the following applications:
    - eic-shell: a development shell in the image
