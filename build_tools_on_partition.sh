#!/bin/bash

usage () {
    cat << EOF

This script runs the build_tools.sh script on a specific partition.

usage: ./build_tools_on_partition.sh <option>

where <option> can be 

<partition>	        the partition on which the tools need to be built.
--help              print this help page
EOF
}

if [ -z "$1" ]; then 
    echo "ERROR: first argument missing." 
    usage
    exit 0
fi

if [ "$1" == "--help" ]; then 
    usage 
    exit 0
fi

sbatch --job-name=BUILD --ntasks=1 --partition=$1 --cpus-per-task=1  build_tools.sh
