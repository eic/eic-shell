#!/bin/bash

## Simple setup script that installs the container
## in your local environment under $PREFIX/local/lib
## and creates a simple top-level launcher script
## that launches the container for this working directory
## with the $EIC_SHELL_PREFIX variable pointing
## to the $PREFIX/local directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ORGANIZATION="eicweb"
CONTAINER="eic_xl"
VERSION="nightly"
PREFIX="$PWD"

function print_the_help {
  echo "USAGE:  ./install.sh [-p PREFIX] [-v VERSION]"
  echo "OPTIONAL ARGUMENTS:"
  echo "          -p,--prefix        Working directory to deploy the environment (D: $PREFIX)"
  echo "          -t,--tmpdir        Change tmp directory (D: $([[ -z "$TMPDIR" ]] && echo "/tmp" || echo "$TMPDIR"))"
  echo "          -n,--no-cvmfs      Disable check for local CVMFS (D: enabled)"
  echo "          -o,--organization  Organization (D: $ORGANIZATION) (requires cvmfs)"
  echo "          -c,--container     Container family (D: $CONTAINER)"
  echo "          -v,--version       Version to install (D: $VERSION)"
  echo "          -h,--help          Print this message"
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
      PREFIX=$(realpath ${2?Missing argument. Use --help for more info.})
      shift
      shift
      ;;
    -t|--tmpdir)
      export TMPDIR=${2?Missing argument. Use --help for more info.}
      export SINGULARITY_TMPDIR=${2?Missing argument. Use --help for more info.}
      shift
      shift
      ;;
    -n|--no-cvmfs)
      DISABLE_CVMFS_USAGE=true
      shift
      ;;
    -c|--container)
      CONTAINER=${2?Missing argument. Use --help for more info.}
      shift
      shift
      ;;
    -v|--version)
      VERSION=${2?Missing argument. Use --help for more info.}
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

## create prefix if needed
mkdir -p $PREFIX || exit 1
pushd $PREFIX

if [ ! -d $PREFIX ]; then
  echo "ERROR: not a valid directory: $PREFIX"
  echo "use --help for more info"
  exit 1
fi

echo "Setting up development environment for eicweb/$CONTAINER:$VERSION"

mkdir -p $PREFIX/local/lib || exit 1

function install_singularity() {
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
    SIF="$PREFIX/local/lib/${CONTAINER}-${VERSION}.simg"

    echo "WARNING: your singularity version $SINGULARITY_VERSION is ancient, we strongly recommend using version 3.x"
    echo "We will attempt to use a fall-back SIMG image to be used with this singularity version"
    if [ -f /gpfs02/eic/athena/${CONTAINER}-${VERSION}.simg ]; then
      ln -sf /gpfs02/eic/athena/${CONTAINER}-${VERSION}.simg ${SIF}
    else
      echo "Attempting last-resort singularity pull for old image"
      echo "This may take a few minutes..."
      INSIF=`basename ${SIF}`
      singularity pull --name "${INSIF}" docker://eicweb/$CONTAINER:$VERSION
      mv ${INSIF} $SIF
      chmod +x ${SIF}
      unset INSIF
    fi
  ## we are in sane territory, yay!
  else
    ## check if we can just use cvmfs for the image
    SIF="$PREFIX/local/lib/${CONTAINER}-${VERSION}.sif"
    if [ -z "$DISABLE_CVMFS_USAGE" -a -d /cvmfs/singularity.opensciencegrid.org/${ORGANIZATION}/${CONTAINER}:${VERSION} ]; then
      SIF="$PREFIX/local/lib/${CONTAINER}-${VERSION}"
      ## need to cleanup in this case, else it will try to make a subdirectory
      rm -rf ${SIF}
      ln -sf /cvmfs/singularity.opensciencegrid.org/${ORGANIZATION}/${CONTAINER}:${VERSION} ${SIF}
    elif [ -f /cvmfs/eic.opensciencegrid.org/singularity/athena/${CONTAINER}_v${VERSION}.sif ]; then
      ln -sf /cvmfs/eic.opensciencegrid.org/singularity/athena/${CONTAINER}_v${VERSION}.sif ${SIF}
    elif [ -f /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/${CONTAINER}_v${VERSION}.sif ]; then
      ln -sf /gpfs02/cvmfst0/eic.opensciencegrid.org/singularity/athena/${CONTAINER}_v${VERSION}.sif ${SIF}
    ## check if we have an internal CI image we will use for testing purposes
    elif [ -f $PWD/.gitlab-ci/${CONTAINER}-${VERSION}.sif ]; then
      ln -sf $PWD/.gitlab-ci/${CONTAINER}-${VERSION}.sif ${SIF}
    ## if not, download the container to the system
    else
      ## get the python installer and run the old-style install
      ## work in temp directory
      tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
      pushd $tmp_dir
      wget https://eic.github.io/eic-shell/install.py
      chmod +x install.py
      ./install.py -f -c $CONTAINER -v $VERSION .
      INSIF=lib/`basename ${SIF}`
      mv $INSIF $SIF
      chmod +x ${SIF}
      ## cleanup
      popd
      rm -rf $tmp_dir
      unset INSIF
    fi
  fi

  echo $SIF
  ls $SIF 2>&1 > /dev/null && GOOD_SIF=1 
  if [ -z "$SIF" -o -z "$GOOD_SIF" ]; then
    echo "ERROR: no singularity image found"
    exit 1
  else
    echo " - Deployed ${CONTAINER} image: $SIF"
  fi

  ## We want to make sure the root directory of the install directory
  ## is always bound. We also check for the existence of a few standard
  ## locations (/scratch /volatile /cache) and bind those too if found
  echo " - Determining additional bind paths"
  BINDPATH=${SINGULARITY_BINDPATH}
  echo "   --> system bindpath: $BINDPATH"
  PREFIX_ROOT="/$(realpath $PREFIX | cut -d "/" -f2)"
  for dir in /w /work /media /scratch /volatile /cache /cvmfs /gpfs /gpfs01 /gpfs02 $PREFIX_ROOT; do
    ## only add directories once (match full path entries in comma-separated BINDPATH)
    if [[ ",$BINDPATH," == *,"$dir",* ]]; then
      continue
    fi
    if [ -d $dir ]; then
      echo "   --> $dir"
      BINDPATH=${dir}${BINDPATH:+,$BINDPATH}
    fi
  done

  ## create a new top-level eic-shell launcher script
  ## that sets the EIC_SHELL_PREFIX and then starts singularity
  export EICS_ORGANIZATION="$ORGANIZATION" EICS_CONTAINER="$CONTAINER" EICS_TMPDIR="$TMPDIR" \
    EICS_VERSION="$VERSION" EICS_PREFIX="$PREFIX" EICS_DISABLE_CVMFS_USAGE="${DISABLE_CVMFS_USAGE}" \
    EICS_SINGULARITY="$SINGULARITY" EICS_BINDPATH="$BINDPATH" EICS_SIF="$SIF"
  envsubst '${EICS_ORGANIZATION} ${EICS_CONTAINER} ${EICS_TMPDIR} ${EICS_VERSION} ${EICS_PREFIX} ${EICS_DISABLE_CVMFS_USAGE} ${EICS_SINGULARITY} ${EICS_BINDPATH} ${EICS_SIF}' < "$SCRIPT_DIR/eic-shell.singularity" > eic-shell

  chmod +x eic-shell

  echo " - Created custom eic-shell executable"
}

function install_docker() {
  ## check for docker install
  DOCKER=$(which docker)
  if [ -z ${DOCKER} ]; then
    echo "ERROR: no docker install found, docker is required for the docker-based install"
  fi
  echo " - Found docker at ${DOCKER}"

  IMG=eicweb/${CONTAINER}:${VERSION}
  docker pull ${IMG}
  echo " - Deployed ${CONTAINER} image: ${IMG}"

  ## We want to make sure the root directory of the install directory
  ## is always bound. We also check for the existence of a few standard
  ## locations (/Volumes /Users /tmp) and bind those too if found
  echo " - Determining mount paths"
  PREFIX_ROOT="/$(realpath $PREFIX | cut -d "/" -f2)"
  MOUNT=""
  echo "   --> $PREFIX_ROOT"
  for dir in /Volumes /Users /tmp; do
    ## only add directories once
    if [[ ${MOUNT} =~ $(basename $dir) ]]; then
      continue
    fi
    if [ -d $dir ]; then
      echo "   --> $dir"
      MOUNT="$MOUNT -v $dir:$dir"
    fi
  done
  echo " - Docker mount directive: '$MOUNT'"
  PLATFORM_FLAG=''
  if [ `uname -m` = 'arm64' ]; then
    PLATFORM_FLAG='--platform linux/amd64'
    echo " - Additional platform flag to run on arm64"
  fi

  ## create a new top-level eic-shell launcher script
  ## that sets the EIC_SHELL_PREFIX and then starts docker
  export EICS_CONTAINER="$CONTAINER" EICS_TMPDIR="$TMPDIR" EICS_VERSION="$VERSION" \
    EICS_PREFIX="$PREFIX" EICS_DISABLE_CVMFS_USAGE="${DISABLE_CVMFS_USAGE}" \
    EICS_IMG="$IMG" EICS_PLATFORM_FLAG="$PLATFORM_FLAG" EICS_MOUNT="$MOUNT"
  envsubst '${EICS_CONTAINER} ${EICS_TMPDIR} ${EICS_VERSION} ${EICS_PREFIX} ${EICS_DISABLE_CVMFS_USAGE} ${EICS_IMG} ${EICS_PLATFORM_FLAG} ${EICS_MOUNT}' < "$SCRIPT_DIR/eic-shell.docker" > eic-shell

  chmod +x eic-shell
  echo " - Created custom eic-shell executable"
}

## detect OS
OS=`uname -s`
CPU=`uname -m`
case ${OS} in
  Linux)
    echo " - Detected OS: Linux"
    echo " - Detected CPU: $CPU"
    if [ "$CPU" = "arm64" ]; then
      install_docker
    else
      install_singularity
    fi
    ;;
  Darwin)
    echo " - Detected OS: MacOS"
    echo " - Detected CPU: $CPU"
    install_docker
    ;;
  *)
    echo "ERROR: OS '${OS}' not currently supported"
    exit 1
    ;;
esac

popd
echo "Environment setup succesfull"
echo "You can start the development environment by running './eic-shell'"
