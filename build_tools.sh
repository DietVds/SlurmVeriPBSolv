#!/bin/bash

usage () {
    cat << EOF

This script builds runlim and VeriPB for running experiments.

usage: ./build_tools.sh [--help]

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
echo Building runlim...
rm $loc_bin/runlim
git clone https://github.com/arminbiere/runlim.git
cd runlim
./configure.sh && make
cd ..
rm -rf runlim-1.10
echo Done building runlim

#Building VeriPB
echo Builing VeriPB..
module load Rust/1.91.1-GCCcore-14.2.0
git clone git@gitlab.com:MIAOresearch/software/VeriPB.git
cd VeriPB
cargo install --path .
cp $VSC_HOME/.cargo/bin/veripb $loc_bin
cd ..
rm -rf VeriPB
echo Done building VeriPB