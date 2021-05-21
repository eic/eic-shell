#!/bin/bash

CONTAINER="jug_xl"
VERSION="3.0-stable"

echo "Setting up development environment for eicweb/$CONTAINER:$VERSION"

## Simple setup script that installs the container
## in your local environment under $PWD/local/lib
## and creates a simple top-level launcher script
## that launches the container for this working directory
## with the $ATHENA_PREFIX variable pointing
## to the $PWD/local directory

mkdir -p local/lib || exit 1

## check for a singularity install
## jlab singularity
if [ -d "/apps/singularity/3.7.1/bin/" ]; then
  SINGULARITY="/apps/singularity/3.7.1/bin/singularity"
## cvmfs singularity
elif [ -f "/cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity" ]; then
  SINGULARITY="/cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity"
## whatever is in the path
elif [ $(type -P singularity ) ]; then
  SINGULARITY=$(which singularity)
else
  echo "ERROR: no singularity found, please make sure you have singularity in your \$PATH"
  exit 1
fi
echo " - Found singularity at $SINGULARITY"

## get singularity version
## we only care if is 2.x or not, so we can use singularity --version 
## which returns 2.xxxxx for version 2
SINGULARITY_VERSION=`$SINGULARITY --version`
SIF=
if [ ${SINGULARITY_VERSION:0:1} = 2 ]; then
  echo "WARNING: your singularity version $SINGULARITY_VERSION is ancient, we strongly recommend using version 3.x"
  echo "We will attempt to use a fall-back SIMG image to be used with this singularity version"
  if [ -f /gpfs02/eic/athena/jug_xl-3.0-stable.simg ]; then
    ln -df /gpfs02/eic/athena/jug_xl-3.0-stable.simg local/lib
    SIF="$PWD/local/lib/jug_xl-3.0-stable.simg"
  else
    echo "Attempting last-resort singularity pull for old image"
    echo "This may take a few minutes..."
    singularity pull docker://eicweb/$CONTAINER:$VERSION
  fi
## we are in sane territory, yay!
else
  ## check if we can just use cvmfs for the image
  if [ -f /cvmfs/eic.opensciencegrid.org/singularity/athena/jug_xl_v${VERSION}.sif ]; then
    ln -sf /cvmfs/eic.opensciencegrid.org/singularity/athena/jug_xl_v${VERSION}.sif local/lib
    SIF="$PWD/local/lib/jug_xl_v${VERSION}.sif"
  elif [ -f /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/jug_xl_v3.0-stable.sif ]; then
    ln -sf /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/jug_xl_v3.0-stable.sif local/lib
    SIF="$PWD/local/lib/jug_xl_v${VERSION}.sif"
  ## if not, download the container to the system
  else
    ## get the python installer and run the old-style install
    wget https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/install.py
    chmod +x install.py
    ./install.py -c $CONTAINER -v $VERSION $PWD/local
    ## Don't place eic-shell in local/bin as this may
    ## conflict with things we install inside the container
    rm $PWD/local/bin/eic-shell
    ## Cleanup
    rm -rf __pycache__ install.py
    SIF=$PWD/local/lib/${CONTAINER}.sif.${VERSION}
  fi
fi

if [ -z $SIF -o ! -f $SIF ]; then
  echo "ERROR: no singularity image found"
else
  echo " - Deployed ${CONTAINER} image: $SIF"
fi

## create a new top-level eic-shell launcher script
## that sets the ATHENA_PREFIX and then starts singularity
cat << EOF > eic-shell
#!/bin/bash
export ATHENA_PREFIX=$PWD/local
$SINGULARITY run $SIF
EOF
chmod +x eic-shell

echo " - Created custom eic-shell excecutable"
echo "Environment setup succesfull"
echo "You can start the development environment by running './eic-shell'"
