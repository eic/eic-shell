#!/bin/bash

## Simple setup script that installs the container
## in your local environment under $PREFIX/local/lib
## and creates a simple top-level launcher script
## that launches the container for this working directory
## with the $EIC_SHELL_PREFIX variable pointing
## to the $PREFIX/local directory

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
cat << EOF > eic-shell
#!/bin/bash

## capture environment setup for upgrades
ORGANIZATION=$ORGANIZATION
CONTAINER=$CONTAINER
TMPDIR=$TMPDIR
VERSION=$VERSION
PREFIX=$PREFIX
DISABLE_CVMFS_USAGE=${DISABLE_CVMFS_USAGE}

## version check configuration
EIC_SHELL_REPO="eic/eic-shell"
INSTALL_URL="https://get.epic-eic.org"
CHECK_INTERVAL_DAYS=1
NETWORK_TIMEOUT=5

function read_metadata() {
  local metadata_file="\${PREFIX}/.eic-shell-metadata"
  if [ -f "\${metadata_file}" ]; then
    source "\${metadata_file}"
  fi
}

function check_local_modifications() {
  local eic_shell_script="\${PREFIX}/eic-shell"
  if [ -z "\${EIC_SHELL_ORIGINAL_MTIME}" ]; then
    return 1
  fi
  local current_mtime
  current_mtime=\$(stat -c %Y "\${eic_shell_script}" 2>/dev/null || stat -f %m "\${eic_shell_script}" 2>/dev/null || echo 0)
  if [ "\${current_mtime}" != "\${EIC_SHELL_ORIGINAL_MTIME}" ]; then
    return 0
  fi
  return 1
}

function should_check_version() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ ! -f "\${cache_file}" ]; then
    return 0
  fi
  local last_check
  last_check=\$(grep '^LAST_CHECK=' "\${cache_file}" 2>/dev/null | cut -d= -f2)
  last_check=\${last_check:-0}
  local now
  now=\$(date +%s)
  local age=\$(( now - last_check ))
  if [ \$age -ge \$(( CHECK_INTERVAL_DAYS * 86400 )) ]; then
    return 0
  fi
  return 1
}

function fetch_latest_release() {
  local result
  result=\$(curl -s --connect-timeout \${NETWORK_TIMEOUT} --max-time \${NETWORK_TIMEOUT} \
    "https://api.github.com/repos/\${EIC_SHELL_REPO}/releases/latest" 2>/dev/null \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ "\${result}" =~ ^[0-9a-zA-Z._-]+\$ ]]; then
    echo "\${result}"
  fi
}

function cache_version_check() {
  local latest_version="\$1"
  local check_status="\$2"
  local has_local_mods="\$3"
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  {
    echo "LAST_CHECK=\$(date +%s)"
    echo "LAST_CHECK_DATE=\"\$(date)\""
    echo "LATEST_VERSION=\${latest_version}"
    echo "CHECK_STATUS=\${check_status}"
    echo "HAS_LOCAL_MODIFICATIONS=\${has_local_mods}"
  } > "\${cache_file}"
}

function read_cached_version() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ -f "\${cache_file}" ]; then
    grep '^LATEST_VERSION=' "\${cache_file}" 2>/dev/null | cut -d= -f2
  fi
}

function read_cached_modification_status() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ -f "\${cache_file}" ]; then
    grep '^HAS_LOCAL_MODIFICATIONS=' "\${cache_file}" 2>/dev/null | cut -d= -f2
  fi
}

function display_update_notification() {
  local current="\$1"
  local latest="\$2"
  local has_mods="\$3"
  if [ "\${has_mods}" = "yes" ]; then
    echo "eic-shell update available (\${current} -> \${latest}), but local modifications detected. Reinstall with: curl -L \${INSTALL_URL} | bash"
  else
    echo "eic-shell update available (\${current} -> \${latest}). Run './eic-shell --upgrade' to update."
  fi
}

function check_for_updates() {
  read_metadata
  local current_version="\${INSTALLED_VERSION:-unknown}"
  local has_mods="no"
  if check_local_modifications; then
    has_mods="yes"
  fi
  if ! should_check_version; then
    local cached_latest
    cached_latest=\$(read_cached_version)
    local cached_mods
    cached_mods=\$(read_cached_modification_status)
    if [ -n "\${cached_latest}" ] && [ "\${cached_latest}" != "\${current_version}" ] && [ "\${current_version}" != "unknown" ]; then
      display_update_notification "\${current_version}" "\${cached_latest}" "\${cached_mods:-\${has_mods}}"
    fi
    return
  fi
  local latest_version
  latest_version=\$(fetch_latest_release)
  if [ -n "\${latest_version}" ]; then
    cache_version_check "\${latest_version}" "success" "\${has_mods}"
    if [ "\${latest_version}" != "\${current_version}" ] && [ "\${current_version}" != "unknown" ]; then
      display_update_notification "\${current_version}" "\${latest_version}" "\${has_mods}"
    fi
  else
    cache_version_check "" "offline" "\${has_mods}"
  fi
}

function check_for_updates_async() {
  ( check_for_updates 2>/dev/null & )
}

function print_the_help {
  echo "USAGE:  ./eic-shell [OPTIONS] [ -- COMMAND ]"
  echo "OPTIONAL ARGUMENTS:"
  echo "          -u,--upgrade       Upgrade eic-shell to the latest version"
  echo "          --check-updates    Check for available eic-shell updates"
  echo "          -n,--no-cvmfs      Disable check for local CVMFS when updating. (D: enabled)"
  echo "          -o,--organization  Organization (D: \$ORGANIZATION) (requires cvmfs)"
  echo "          -c,--container     Container family (D: \$CONTAINER) (requires cvmfs)"
  echo "          -v,--version       Version to install (D: \$VERSION) (requires cvmfs)"
  echo "          -h,--help          Print this message"
  echo ""
  echo "  Start the eic-shell containerized software environment (Singularity version)."
  echo ""
  echo "ENVIRONMENT VARIABLES:"
  echo "          SINGULARITY        Path to the singularity executable (D: detected during installation)"
  echo "          SINGULARITY_OPTIONS  Additional options to pass to singularity exec (D: none)"
  echo ""
  echo "EXAMPLES: "
  echo "  - Start an interactive shell: ./eic-shell" 
  echo "  - Upgrade eic-shell:          ./eic-shell --upgrade"
  echo "  - Check for updates:          ./eic-shell --check-updates"
  echo "  - Use different version:      ./eic-shell --version \$(date +%y.%m).0-stable"
  echo "  - Execute a single command:   ./eic-shell -- <COMMAND>"
  echo "  - Use custom singularity:     SINGULARITY=/path/to/singularity ./eic-shell"
  echo "  - Pass singularity options:   SINGULARITY_OPTIONS='--nv' ./eic-shell"
  echo ""
  exit
}

UPGRADE=
CHECK_UPDATES=

while [ \$# -gt 0 ]; do
  key=\$1
  case \$key in
    -u|--upgrade)
      UPGRADE=1
      shift
      ;;
    --check-updates)
      CHECK_UPDATES=1
      shift
      ;;
    -n|--no-cvmfs)
      DISABLE_CVMFS_USAGE=true
      shift
      ;;
    -c|--container)
      CONTAINER=\${2?Missing argument. Use --help for more info.}
      export SIF=/cvmfs/singularity.opensciencegrid.org/\${ORGANIZATION}/\${CONTAINER}:\${VERSION}
      shift
      shift
      ;;
    -v|--version)
      VERSION=\${2?Missing argument. Use --help for more info.}
      export SIF=/cvmfs/singularity.opensciencegrid.org/\${ORGANIZATION}/\${CONTAINER}:\${VERSION}
      shift
      shift
      ;;
    -h|--help)
      print_the_help
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "ERROR: unknown argument: \$key"
      echo "use --help for more info"
      exit 1
      ;;
  esac
done

if [ -n "\${CHECK_UPDATES}" ]; then
  read_metadata
  rm -f "\${PREFIX}/.eic-shell-version-check"
  current_version="\${INSTALLED_VERSION:-unknown}"
  latest_version=\$(fetch_latest_release)
  if [ -n "\${latest_version}" ]; then
    if [ "\${latest_version}" = "\${current_version}" ]; then
      echo "eic-shell is up to date (version: \${current_version})"
    elif [ "\${current_version}" = "unknown" ]; then
      echo "eic-shell latest version: \${latest_version} (installed version unknown)"
    else
      has_mods="no"
      if check_local_modifications; then
        has_mods="yes"
      fi
      display_update_notification "\${current_version}" "\${latest_version}" "\${has_mods}"
    fi
  else
    echo "eic-shell update check failed (network unavailable). Current version: \${current_version}"
  fi
  exit 0
fi

if [ ! -z \${UPGRADE} ]; then
  read_metadata
  if check_local_modifications; then
    echo "ERROR: Local modifications to eic-shell detected. Cannot upgrade automatically."
    echo "Reinstall with: curl -L \${INSTALL_URL} | bash"
    exit 1
  fi
  echo "Upgrading eic-shell..."
  if [ -z "\$DISABLE_CVMFS_USAGE" -a -d /cvmfs/singularity.opensciencegrid.org/\${ORGANIZATION}/\${CONTAINER}:\${VERSION} ]; then
    echo ""
    echo "Note: You cannot manually update the container as you are using the CVMFS version."
    echo "      The container will automatically update every 24 hours."
    echo "      You can override this by setting the '--no-cvmfs' flag, which will"
    echo "      instantiate a local version."
    echo "      This is only recommended for expert usage."
    echo ""
    echo "This will only upgrade the eic-shell script itself."
    echo ""
  fi
  FLAGS="-p \${PREFIX} -v \${VERSION} -c \${CONTAINER}"
  if [ ! -z \${TMPDIR} ]; then
    FLAGS="\${FLAGS} -t \${TMPDIR}"
  fi
  if [ ! -z \${DISABLE_CVMFS_USAGE} ]; then
    FLAGS="\${FLAGS} --no-cvmfs"
  fi
  curl -L \${INSTALL_URL} \
    | bash -s -- \${FLAGS}
  echo "eic-shell upgrade successful"
  exit 0
fi

check_for_updates_async

export EIC_SHELL_PREFIX=$PREFIX/local
export SINGULARITY_BINDPATH=$BINDPATH
\${SINGULARITY:-$SINGULARITY} exec \${SINGULARITY_OPTIONS:-} \${SIF:-$SIF} eic-shell \$@
EOF

  chmod +x eic-shell

  echo " - Created custom eic-shell excecutable"
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
cat << EOF > eic-shell
#!/bin/bash

## capture environment setup for upgrades
CONTAINER=$CONTAINER
TMPDIR=$TMPDIR
VERSION=$VERSION
PREFIX=$PREFIX
DISABLE_CVMFS_USAGE=${DISABLE_CVMFS_USAGE}

## version check configuration
EIC_SHELL_REPO="eic/eic-shell"
INSTALL_URL="https://get.epic-eic.org"
CHECK_INTERVAL_DAYS=1
NETWORK_TIMEOUT=5

function read_metadata() {
  local metadata_file="\${PREFIX}/.eic-shell-metadata"
  if [ -f "\${metadata_file}" ]; then
    source "\${metadata_file}"
  fi
}

function check_local_modifications() {
  local eic_shell_script="\${PREFIX}/eic-shell"
  if [ -z "\${EIC_SHELL_ORIGINAL_MTIME}" ]; then
    return 1
  fi
  local current_mtime
  current_mtime=\$(stat -c %Y "\${eic_shell_script}" 2>/dev/null || stat -f %m "\${eic_shell_script}" 2>/dev/null || echo 0)
  if [ "\${current_mtime}" != "\${EIC_SHELL_ORIGINAL_MTIME}" ]; then
    return 0
  fi
  return 1
}

function should_check_version() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ ! -f "\${cache_file}" ]; then
    return 0
  fi
  local last_check
  last_check=\$(grep '^LAST_CHECK=' "\${cache_file}" 2>/dev/null | cut -d= -f2)
  last_check=\${last_check:-0}
  local now
  now=\$(date +%s)
  local age=\$(( now - last_check ))
  if [ \$age -ge \$(( CHECK_INTERVAL_DAYS * 86400 )) ]; then
    return 0
  fi
  return 1
}

function fetch_latest_release() {
  local result
  result=\$(curl -s --connect-timeout \${NETWORK_TIMEOUT} --max-time \${NETWORK_TIMEOUT} \
    "https://api.github.com/repos/\${EIC_SHELL_REPO}/releases/latest" 2>/dev/null \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ "\${result}" =~ ^[0-9a-zA-Z._-]+\$ ]]; then
    echo "\${result}"
  fi
}

function cache_version_check() {
  local latest_version="\$1"
  local check_status="\$2"
  local has_local_mods="\$3"
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  {
    echo "LAST_CHECK=\$(date +%s)"
    echo "LAST_CHECK_DATE=\"\$(date)\""
    echo "LATEST_VERSION=\${latest_version}"
    echo "CHECK_STATUS=\${check_status}"
    echo "HAS_LOCAL_MODIFICATIONS=\${has_local_mods}"
  } > "\${cache_file}"
}

function read_cached_version() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ -f "\${cache_file}" ]; then
    grep '^LATEST_VERSION=' "\${cache_file}" 2>/dev/null | cut -d= -f2
  fi
}

function read_cached_modification_status() {
  local cache_file="\${PREFIX}/.eic-shell-version-check"
  if [ -f "\${cache_file}" ]; then
    grep '^HAS_LOCAL_MODIFICATIONS=' "\${cache_file}" 2>/dev/null | cut -d= -f2
  fi
}

function display_update_notification() {
  local current="\$1"
  local latest="\$2"
  local has_mods="\$3"
  if [ "\${has_mods}" = "yes" ]; then
    echo "eic-shell update available (\${current} -> \${latest}), but local modifications detected. Reinstall with: curl -L \${INSTALL_URL} | bash"
  else
    echo "eic-shell update available (\${current} -> \${latest}). Run './eic-shell --upgrade' to update."
  fi
}

function check_for_updates() {
  read_metadata
  local current_version="\${INSTALLED_VERSION:-unknown}"
  local has_mods="no"
  if check_local_modifications; then
    has_mods="yes"
  fi
  if ! should_check_version; then
    local cached_latest
    cached_latest=\$(read_cached_version)
    local cached_mods
    cached_mods=\$(read_cached_modification_status)
    if [ -n "\${cached_latest}" ] && [ "\${cached_latest}" != "\${current_version}" ] && [ "\${current_version}" != "unknown" ]; then
      display_update_notification "\${current_version}" "\${cached_latest}" "\${cached_mods:-\${has_mods}}"
    fi
    return
  fi
  local latest_version
  latest_version=\$(fetch_latest_release)
  if [ -n "\${latest_version}" ]; then
    cache_version_check "\${latest_version}" "success" "\${has_mods}"
    if [ "\${latest_version}" != "\${current_version}" ] && [ "\${current_version}" != "unknown" ]; then
      display_update_notification "\${current_version}" "\${latest_version}" "\${has_mods}"
    fi
  else
    cache_version_check "" "offline" "\${has_mods}"
  fi
}

function check_for_updates_async() {
  ( check_for_updates 2>/dev/null & )
}

function print_the_help {
  echo "USAGE:  ./eic-shell [OPTIONS] [ -- COMMAND ]"
  echo "OPTIONAL ARGUMENTS:"
  echo "          -u,--upgrade    Upgrade eic-shell to the latest version"
  echo "          --check-updates Check for available eic-shell updates"
  echo "          --noX           Disable X11 forwarding on macOS"
  echo "          -h,--help       Print this message"
  echo ""
  echo "  Start the eic-shell containerized software environment (Docker version)."
  echo ""
  echo "EXAMPLES: "
  echo "  - Start an interactive shell: ./eic-shell" 
  echo "  - Upgrade eic-shell:          ./eic-shell --upgrade"
  echo "  - Check for updates:          ./eic-shell --check-updates"
  echo "  - Execute a single command:   ./eic-shell -- <COMMAND>"
  echo ""
  exit
}

UPGRADE=
CHECK_UPDATES=
NOX=
while [ \$# -gt 0 ]; do
  key=\$1
  case \$key in
    -u|--upgrade)
      UPGRADE=1
      shift
      ;;
    --check-updates)
      CHECK_UPDATES=1
      shift
      ;;
    --noX)
      NOX=1
      shift
      ;;
    -h|--help)
      print_the_help
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "ERROR: unknown argument: \$key"
      echo "use --help for more info"
      exit 1
      ;;
  esac
done

if [ x\${DISPLAY} == "x" ] ; then
  echo "No X11 display detected, disabling X11"
  NOX=1
fi

if [ -n "\${CHECK_UPDATES}" ]; then
  read_metadata
  rm -f "\${PREFIX}/.eic-shell-version-check"
  current_version="\${INSTALLED_VERSION:-unknown}"
  latest_version=\$(fetch_latest_release)
  if [ -n "\${latest_version}" ]; then
    if [ "\${latest_version}" = "\${current_version}" ]; then
      echo "eic-shell is up to date (version: \${current_version})"
    elif [ "\${current_version}" = "unknown" ]; then
      echo "eic-shell latest version: \${latest_version} (installed version unknown)"
    else
      has_mods="no"
      if check_local_modifications; then
        has_mods="yes"
      fi
      display_update_notification "\${current_version}" "\${latest_version}" "\${has_mods}"
    fi
  else
    echo "eic-shell update check failed (network unavailable). Current version: \${current_version}"
  fi
  exit 0
fi

if [ ! -z \${UPGRADE} ]; then
  read_metadata
  if check_local_modifications; then
    echo "ERROR: Local modifications to eic-shell detected. Cannot upgrade automatically."
    echo "Reinstall with: curl -L \${INSTALL_URL} | bash"
    exit 1
  fi
  echo "Upgrading eic-shell..."
  FLAGS="-p \${PREFIX} -v \${VERSION} -c \${CONTAINER}"
  if [ ! -z \${TMPDIR} ]; then
    FLAGS="\${FLAGS} -t \${TMPDIR}"
  fi
  curl -L \${INSTALL_URL} \
    | bash -s -- \${FLAGS}
  echo "eic-shell upgrade successful"
  exit 0
fi

check_for_updates_async

EOF

  if [ `uname -s` = 'Darwin' ]; then
      echo 'if [ ! ${NOX} ]; then' >> eic-shell
      echo ' nolisten=`defaults find nolisten_tcp | grep nolisten | head -n 1 | awk ' "'{print" '$3}'"'" '|cut -b 1 `' >> eic-shell
      echo ' [[ $nolisten -ne 0 ]] && echo "For X support: In XQuartz settings --> Security --> enable \"Allow connections from network clients\" and restart (should be only once)."' >> eic-shell
      ## getting the following single and double quotes, escapes and backticks right was a nightmare
      ## But with a heredoc it was worse
      echo '  xhost +localhost' >> eic-shell
      echo '  dispnum=`ps -e |grep Xquartz | grep listen | grep -v xinit |awk ' "'{print" '$5}'"'" '`' >> eic-shell
      echo '  XSTUFF="-e DISPLAY=host.docker.internal${dispnum} -v /tmp/.X11-unix:/tmp/.X11-unix"' >> eic-shell
      echo 'fi' >> eic-shell
  fi
  echo "docker run $PLATFORM_FLAG $MOUNT \$XSTUFF -w=$PWD -it --rm -e EIC_SHELL_PREFIX=$PREFIX/local $IMG eic-shell \$@" >> eic-shell

  chmod +x eic-shell
  echo " - Created custom eic-shell excecutable"
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

## create metadata file for version tracking
EIC_SHELL_MTIME=$(stat -c %Y "${PREFIX}/eic-shell" 2>/dev/null || stat -f %m "${PREFIX}/eic-shell" 2>/dev/null || echo 0)
INSTALLED_VERSION=$(curl -s --connect-timeout 5 --max-time 5 \
  "https://api.github.com/repos/eic/eic-shell/releases/latest" 2>/dev/null \
  | grep '"tag_name":' \
  | sed -E 's/.*"([^"]+)".*/\1/')
if [[ ! "$INSTALLED_VERSION" =~ ^[0-9a-zA-Z._-]+$ ]]; then
  INSTALLED_VERSION="unknown"
fi
{
  echo "INSTALLED_VERSION=$INSTALLED_VERSION"
  echo "INSTALLED_DATE=$(date +%s)"
  echo "CONTAINER=$CONTAINER"
  echo "ORGANIZATION=$ORGANIZATION"
  echo "EIC_SHELL_ORIGINAL_MTIME=$EIC_SHELL_MTIME"
} > "${PREFIX}/.eic-shell-metadata"
echo " - Installed eic-shell version: $INSTALLED_VERSION"

popd
echo "Environment setup successful"
echo "You can start the development environment by running './eic-shell'"
