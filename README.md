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
    - acts@8.01.0
    - gaudi@34.0
    - dawn@3.91a
    - dawncut@1.54a
    - opencascade
    - madx@5.06.1
  - The singularity build exports the following applications:
    - eic-shell: a development shell in the image
