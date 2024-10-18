usage () {
cat << EOF
usage: ./aggregate_results.sh <experiment-name> [ <outfile> ] 

where 

<experiment-name>	name of the experiment
<outfile>			file to where the results are written. Default: $VSC_DATA/results_<experiment-name>.csv
EOF
}

if [ -z $1 ]; then 
	echo "ERROR: Argument missing. Correct usage: "
	usage
	exit 0
fi

if [[ "$1" == "--help" ]]; then 
	usage
	exit 0
fi

experiment_name=$1

if [ -z $2 ]; then
	outfile=$VSC_DATA/results_$experiment_name.csv
else
	outfile=$2
fi

source helper/config.sh
#TODO: Use the file $loc_results/resultheader_$EXPERIMENTNAME.txt
cat $loc_results/resultheader_$experiment_name.txt > $outfile
cat $loc_results/$experiment_name/* >> $outfile
echo "Results can be found at: $outfile"