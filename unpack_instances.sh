#!/bin/bash

usage () {
cat << EOF
usage: ./run_experiments.sh <instances_archive> <out>

where 

   <instances_archive>  is an archive containing instances
   <out>                is the folder where the instances needs to be placed

call ./run_experiments.sh --help to show this help page.
EOF
exit 0
}

if [ -z $1 ] || [ -z $2 ]; then 
	echo "ERROR: Argument missing. Correct usage: "
	usage
	exit 0
fi

if [[ "$1" == "--help" ]]; then 
	usage
	exit 0
fi

if [[ ! -d $instances ]]; then
   mkdir -p $instances
fi

instances_archive=$1
instances=$2

unzip -j $instances_archive -d $instances 

cd $instances
for filename in $(ls .) ; do 
   echo extracting file $filename
   instance=$(basename $filename .xz)
   unxz $filename
done
chmod +r *
