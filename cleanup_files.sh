source helper/config.sh

usage () {
    cat << EOF
usage: ./cleanup_files.sh <experiment-name> | --help | --all

where 

<experiment-name>	name of the experiment. If empty, all files in $loc_outputs, $loc_proofs, $loc_results and $loc_running_scripts will be removed. Otherwise only folders with the experiment-name will be removed.
--help              print this help page
--all               cleanup files from all experiments
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

if [ "$1" ==  "--all"]; then
    rm -r $loc_outputs/*
    rm -r $loc_proofs/*
    rm -r $loc_running_scripts/*
    rm -r $loc_results/*
    rm runtask_*.log
else 
    rm -r $loc_outputs/$1
    rm -r $loc_proofs/$1
    rm -r $loc_running_scripts/$1
    rm -r $loc_results/$1
    rm -r $loc_results/resultheader_$1.txt
    rm $loc_running_scripts/slurm_run_$1.pbs
    rm runtask_$1.log
fi

rm slurm-*
