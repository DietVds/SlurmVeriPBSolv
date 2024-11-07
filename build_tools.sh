#!/bin/bash

usage () {
    cat << EOF
usage: ./build_tools.sh [--help]

This script builds runlim and VeriPB for running experiments.

--help              print this help page
EOF
}

if [ -n "$1" ] && [ "$1" == "--help" ]; then 
    usage 
    exit 0
fi

source helper/config.sh
source helper/load_modules.sh

#Building runlim
rm $loc_bin/runlim
echo Building runlim...
cd $loc_tools
tar -xf runlim-1.10.tar.gz
cd runlim-1.10
./configure.sh && make
mv runlim $loc_bin
cd $loc_tools
rm -rf runlim-1.10
echo Finished building runlim

#Building VeriPB if necessary
rm -rf $loc_bin/pyenv
# virtualenv --system-site-packages $loc_bin/pyenv
virtualenv $loc_bin/pyenv
source $loc_bin/pyenv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools
cd $loc_tools
git clone git@gitlab.com:MIAOresearch/software/VeriPB.git
cd VeriPB
python3 -m pip install .
cd $loc_tools 
rm -rf VeriPB