# SlurmVeriPBSolv

This repository contains some scripts to allow for running experiments on proof logging with the VeriPB proof format using the slurm workload manager.

# Scripts

## build_tools.sh

usage: ./build_tools.sh [--help]

This script builds runlim and VeriPB for running experiments.

--help              print this help page

## build_tools_on_partition.sh

This script runs the build_tools.sh script on a specific partition.

usage: ./build_tools_on_partition.sh <option>

where <option> can be 

<partition>	        the partition on which the tools need to be built.
--help              print this help page

## run_experiments.sh

Posts the job to run experiments. 

usage: ./run_experiments.sh [ <option=value> ... ]

where '<option>' is one of the following

--help                  print this command line summary
--job-name              name of the job in slurm - Default: CMS - Mandatory
--ntasks                number of tasks running in parallel - Default 20
--experiment-name       name of the experiment 
--mailtype              send mails for changes in status. Possible values: NONE, BEGIN, END, FAIL, INVALID_DEPEND, REQUEUE, and STAGE_OUT - Default: NONE
--partition             partition on which the job needs to be run. Default: zen4.
--configfile            location of the configfile. Default: helper/config.sh
--instances             location of the instances. Default: variable loc_instances in config file.

--exec-without-PL       executable that runs the solver without proof logging. The first argument should be the input instance.
--exec-with-PL          executable that runs the solver with proof logging. The first argument should be the input instance; the second argument should be the proof file.
--check-proof           run the VeriPB proof checker to validate the proof. No value necessary to specify.
--check-previous-step   only run next step in workflow "without PL -> with PL -> proof checker" if previous step succeeded (of if step doesn't need to be executed). No value necessary to specify.

## aggregate_results.sh

Combines the results from an experiment after it has finished running.

usage: ./aggregate_results.sh <experiment-name> [ <outfile> ] 

where 

<experiment-name>	name of the experiment
<outfile>			file to where the results are written. Default: /results_<experiment-name>.csv

## cleanup_files.sh

Removes all temporary files related to an experiment (or all experiments).

usage: ./cleanup_files.sh <experiment-name> | --help | --all

where 

<experiment-name>	name of the experiment. If empty, all files in /outputs, /proofs, /results and /running_scripts will be removed. Otherwise only folders with the experiment-name will be removed.
--help              print this help page
--all               cleanup files from all experiments

# References

Slurm: https://slurm.schedmd.com/ 
VeriPB: https://gitlab.com/MIAOresearch/software/VeriPB 
Runlim: 


