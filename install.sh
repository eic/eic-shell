#!/bin/bash

CONTAINER="jug_xl"
VERSION="nightly"
PREFIX="$PWD"

function print_the_help {
  echo "USAGE:  ./install.sh [-p PREFIX] [-v VERSION]"
  echo "OPTIONAL ARGUMENTS:"
  echo "          -p,--prefix     Working directory to deploy the environment (D: $PREFIX)"
  echo "          -v,--version    Version to install (D: $VERSION)"
  echo "          -h,--help       Print this message"
  echo ""
  echo "  Set up containerized development environment."
  echo ""
  echo "EXAMPLE: ./install.sh" 
  exit
}

while [ $# -gt 0 ]; do
  key=$1
  case $key in
    -p|--prefix)
      PREFIX=$2
      shift
      shift
      ;;
    -v|--version)
      VERSION=$2
      shift
      shift
      ;;
    -h|--help)
      print_the_help
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $key"
      echo "use --help for more info"
      exit 1
      ;;
  esac
done

mkdir -p $PREFIX || exit 1

if [ ! -d $PREFIX ]; then
  echo "ERROR: not a valid directory: $PREFIX"
  echo "use --help for more info"
  exit 1
fi

echo "Setting up development environment for eicweb/$CONTAINER:$VERSION"

## Simple setup script that installs the container
## in your local environment under $PREFIX/local/lib
## and creates a simple top-level launcher script
## that launches the container for this working directory
## with the $ATHENA_PREFIX variable pointing
## to the $PREFIX/local directory

mkdir -p local/lib || exit 1

SINGULARITY=
## check for a singularity install
## default singularity if new enough
if [ $(type -P singularity ) ]; then
  SINGULARITY=$(which singularity)
  SINGULARITY_VERSION=`$SINGULARITY --version`
  if [ ${SINGULARITY_VERSION:0:1} = 2 ]; then
    ## too old, look for something else
    SINGULARITY=
  fi
fi
if [ -z $SINGULARITY ]; then
  ## first priority: a known good install (this one is on JLAB)
  if [ -d "/apps/singularity/3.7.1/bin/" ]; then
    SINGULARITY="/apps/singularity/3.7.1/bin/singularity"
  ## whatever is in the path is next
  elif [ $(type -P singularity ) ]; then
    SINGULARITY=$(which singularity)
  ## cvmfs singularity is last resort (sandbox mode can cause issues)
  elif [ -f "/cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity" ]; then
    SINGULARITY="/cvmfs/oasis.opensciencegrid.org/mis/singularity/bin/singularity"
  ## not good...
  else
    echo "ERROR: no singularity found, please make sure you have singularity in your \$PATH"
    exit 1
  fi
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
    ln -sf /gpfs02/eic/athena/jug_xl-3.0-stable.simg local/lib
    SIF="$PREFIX/local/lib/jug_xl-3.0-stable.simg"
  else
    echo "Attempting last-resort singularity pull for old image"
    echo "This may take a few minutes..."
    SIF="$PREFIX/local/lib/jug_xl-3.0-stable.simg"
    singularity pull --name "$SIF" docker://eicweb/$CONTAINER:$VERSION
  fi
## we are in sane territory, yay!
else
  ## check if we can just use cvmfs for the image
  if [ -d /cvmfs/singularity.opensciencegrid.org/eicweb/jug_xl:${VERSION} ]; then
    ln -sf /cvmfs/singularity.opensciencegrid.org/eicweb/jug_xl:${VERSION} local/lib
    SIF="$PREFIX/local/lib/jug_xl:${VERSION}"
  elif [ -f /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/jug_xl_v3.0-stable.sif ]; then
    ln -sf /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/jug_xl_v3.0-stable.sif local/lib
    SIF="$PREFIX/local/lib/jug_xl_v${VERSION}.sif"
  ## if not, download the container to the system
  else
    ## get the python installer and run the old-style install
    wget https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/install.py
    chmod +x install.py
    ./install.py -f -c $CONTAINER -v $VERSION $PREFIX/local
    ## Don't place eic-shell in local/bin as this may
    ## conflict with things we install inside the container
    rm $PREFIX/local/bin/eic-shell
    ## Cleanup
    rm -rf __pycache__ install.py
    SIF=$PREFIX/local/lib/${CONTAINER}.sif.${VERSION}
  fi
fi

if [ -z $SIF -o ! -f $SIF ]; then
  echo "ERROR: no singularity image found"
else
  echo " - Deployed ${CONTAINER} image: $SIF"
fi

## We want to make sure the root directory of the install directory
## is always bound. We also check for the existence of a few standard
## locations (/scratch /volatile /cache) and bind those too if found
echo " - Determining additional bind paths"
PREFIX_ROOT="/$(realpath $PREFIX | cut -d "/" -f2)"
BINDPATH=$PREFIX_ROOT
echo "   --> $PREFIX_ROOT"
for dir in /work /scratch /volatile /cache; do
  if [ -d $dir ]; then
    echo "   --> $dir"
    BINDPATH="${BINDPATH},$dir"
  fi
done

## create a new top-level eic-shell launcher script
## that sets the ATHENA_PREFIX and then starts singularity
## need different script for old singularity versions
if [ ${SINGULARITY_VERSION:0:1} != 2 ]; then
## newer singularity
cat << EOF > eic-shell
#!/bin/bash
export ATHENA_PREFIX=$PREFIX/local
export SINGULARITY_BINDPATH=$BINDPATH
$SINGULARITY run $SIF
EOF
else
## ancient singularity
cat << EOF > eic-shell
#!/bin/bash
export ATHENA_PREFIX=$PREFIX/local
export SINGULARITY_BINDPATH=$BINDPATH
$SINGULARITY exec $SIF eic-shell
EOF
fi

chmod +x eic-shell

echo " - Created custom eic-shell excecutable"
echo "Environment setup succesfull"
echo "You can start the development environment by running './eic-shell'"
