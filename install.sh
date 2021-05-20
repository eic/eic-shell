#!/bin/bash

CONTAINER=jug_xl
VERSION=3.0.0

## Simple setup script that installs the container
## in your local environment under $PWD/local/lib
## and creates a simple top-level launcher script
## that launches the container for this working directory
## with the $ATHENA_PREFIX variable pointing
## to the $PWD/local directory

## get the python installer and run the old-style install
#cp ../../current/eic_container/install.py .
wget https://eicweb.phy.anl.gov/containers/eic_container/-/raw/master/install.py
chmod +x install.py
./install.py -c $CONTAINER -v $VERSION $PWD/local
## ensure the container is executable
chmod +x $PWD/local/lib/${CONTAINER}.sif.${VERSION}
## Don't place eic-shell in local/bin as this may
## conflict with things we install inside the container
rm $PWD/local/bin/eic-shell
## Cleanup
rm -rf __pycache__ install.py

## create a new top-level eic-shell launcher script
## that sets the ATHENA_PREFIX and then starts singularity
cat << EOF > eic-shell
#!/bin/bash
export ATHENA_PREFIX=$PWD/local
$PWD/local/lib/${CONTAINER}.sif.${VERSION}
EOF
chmod +x eic-shell
