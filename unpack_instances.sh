#!/bin/bash

source config.sh

unzip -j $loc_instances_archive -d $loc_instances 

cd $loc_instances
for filename in $(ls .) ; do 
   echo extracting file $filename
   instance=$(basename $filename .xz)
   unxz $filename
done
chmod +r *
