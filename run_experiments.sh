#Default parameters
JOBNAME=CMS
TIMELIMIT=5-00:00:00
NTASKS=20
PARTITION=zen4
CPUSPERTASK=1
MEMPERCPU=65836
MEMLIMITEXP=32768
TIMELIMITEXP=3600
MAILTYPE=NONE
EXPERIMENTNAME=""
EXECWITHPL=""
EXECWITHOUTPL=""
CHECKPROOF="no"
CHECKPREVIOUSSTEP="no"

CONFIGFILE="config.sh"
INSTANCES=""

usage () {
cat << EOF
usage: ./run_experiments.sh [ <option=value> ... ]

where '<option>' is one of the following

--help                  print this command line summary
--job-name              name of the job in slurm - Default: CMS - Mandatory
--ntasks                number of tasks running in parallel - Default 20
--experiment-name       name of the experiment 
--mailtype              send mails for changes in status. Possible values: NONE, BEGIN, END, FAIL, INVALID_DEPEND, REQUEUE, and STAGE_OUT - Default: NONE
--partition             partition on which the job needs to be run. Default: zen4.
--configfile            location of the configfile. Default: config.sh
--instances             location of the instances. Default: variable loc_instances in config file.

--exec-without-PL       executable that runs the solver without proof logging. The first argument should be the input instance.
--exec-with-PL          executable that runs the solver with proof logging. The first argument should be the input instance; the second argument should be the proof file.
--check-proof           run the VeriPB proof checker to validate the proof. No value necessary to specify.
--check-previous-step   only run next step in workflow "without PL -> with PL -> proof checker" if previous step succeeded (of if step doesn't need to be executed). No value necessary to specify.
EOF
exit 0
}

while [ $# -gt 0 ]
do
  case $1 in
    --help) usage;;
    --job-name=*) JOBNAME="`expr \"$1\" : '--job-name=\(.*\)'`";;
    --ntasks=*) NTASKS="`expr \"$1\" : '--ntasks=\(.*\)'`";;
    --experiment-name=*) EXPERIMENTNAME="`expr \"$1\" : '--experiment-name=\(.*\)'`";;
    --mailtype=*) MAILTYPE="`expr \"$1\" : '--mailtype=\(.*\)'`";;
    --partition=*) PARTITION="`expr \"$1\" : '--partition=\(.*\)'`";;
    --configfile=*) CONFIGFILE="`expr \"$1\" : '--configfile=\(.*\)'`";;
    --instances=*) INSTANCES="`expr \"$1\" : '--instances=\(.*\)'`";;
    --exec-without-PL=*) EXECWITHOUTPL="`expr \"$1\" : '--exec-without-PL=\(.*\)'`";;
    --exec-with-PL=*) EXECWITHPL="`expr \"$1\" : '--exec-with-PL=\(.*\)'`";;
    --check-proof) CHECKPROOF="yes";;
    --check-previous-step) CHECKPREVIOUSSTEP="yes";;
  esac
  shift
done

if [ -z "$EXPERIMENTNAME" ]; then
    echo "$EXPERIMENTNAME"
    echo ERROR: Experiment name is not optional.
    exit
fi

source $CONFIGFILE
source load_modules.sh

if [ -n $INSTANCES ]; then
    loc_instances=$INSTANCES
fi

# Creating folders for the experiment
if [ ! -d $loc_running_scripts/$EXPERIMENTNAME ]; then
    mkdir -p $loc_running_scripts/$EXPERIMENTNAME
fi 

if [ ! -d $loc_outputs/$EXPERIMENTNAME ]; then
    mkdir -p $loc_outputs/$EXPERIMENTNAME 
fi

if [ ! -d $loc_results/$EXPERIMENTNAME ]; then
    mkdir -p $loc_results/$EXPERIMENTNAME 
fi

if [ ! -d $loc_proofs/$EXPERIMENTNAME ]; then
    mkdir -p $loc_proofs/$EXPERIMENTNAME
fi

# Creating running scripts

instances_escaped=$(sed 's;/;\\/;g' <<< "$loc_instances")

for filename in $(ls "$loc_instances")
do 
    sed "s/TIME_L/$TIMELIMITEXP/g" single.sh > $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/MEM_L/$MEMLIMITEXP/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/FILENAME/$filename/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/CONFIGFILE/$CONFIGFILE/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/INSTANCES/$instances_escaped/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/EXPNAME/$EXPERIMENTNAME/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/WITHOUTPL/$EXECWITHOUTPL/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/WITHPL/$EXECWITHPL/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/CHECKPROOF/$CHECKPROOF/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    sed -i "s/CHECKPREVIOUSSTEP/$CHECKPREVIOUSSTEP/g" $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
    chmod +x $loc_running_scripts/$EXPERIMENTNAME/${filename}.sh
done

# Create experiment header.
resultheader="instance"
if [ -n $EXECWITHOUTPL ]; then
  resultheader+=", $res_runtime_withoutPL, $res_mem_withoutPL, $answer_withoutPL"
fi
if [ -n $EXECWITHPL ]; then
  resultheader+=", $res_runtime_withPL, $res_mem_withPL, $answer_withPL"
fi
if [ $CHECKPROOF == "yes" ]; then
  resultheader+=", $res_runtime_proofchecker, $res_mem_proofchecker, $res_proofcheck_succeeded"
fi
echo "$resultheader" > $loc_results/resultheader_$EXPERIMENTNAME.txt

# Create pbs and post the job by using sbatch.
cp slurm_run.pbs $loc_running_scripts/slurm_run_$EXPERIMENTNAME.pbs
sed -i "s/EXPNAME/$EXPERIMENTNAME/g" $loc_running_scripts/slurm_run_$EXPERIMENTNAME.pbs
if [ $CHECKPROOF == "yes" ]; then
    sed -i "s/BUILDVERIPB/yes/g" $loc_running_scripts/slurm_run_$EXPERIMENTNAME.pbs
else 
    sed -i "s/BUILDVERIPB/no/g" $loc_running_scripts/slurm_run_$EXPERIMENTNAME.pbs
fi
sbatch --job-name=$JOBNAME --time=$TIMELIMIT --ntasks=$NTASKS --partition=$PARTITION --cpus-per-task=$CPUSPERTASK --mem-per-cpu=$MEMPERCPU --mail-type=$MAILTYPE $loc_running_scripts/slurm_run_$EXPERIMENTNAME.pbs

