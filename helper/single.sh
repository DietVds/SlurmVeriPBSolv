#!/bin/bash
configfile=CONFIGFILE

source $configfile
source $loc_scripts/helper/load_modules.sh

instances=INSTANCES
filename=FILENAME
extension="${filename##*.}"
filename="${filename%.*}"

TIMEOUT_SOLVER=TIME_L
#TODO: TIMEOUT_SOLVER_PL=$TIMEOUT_SOLVER
TIMEOUT_VERIPB=$(echo 10*$TIMEOUT_SOLVER / 1 | bc)

MEMOUT_SOLVER=MEM_L
#TODO: MEMOUT_SOLVER_PL=$MEMOUT_SOLVER
MEMOUT_VERIPB=$(echo 2*$MEMOUT_SOLVER / 1 | bc)


experiment_name=EXPNAME

script_without_PL=WITHOUTPL
script_with_PL=WITHPL
script_calculate_checksum=CALCULATECHECKSUM
checkproof=CHECKPROOF
checkpreviousstep=CHECKPREVIOUSSTEP

res_runtime_withoutPL=""
res_mem_withoutPL=""
answer_withoutPL=""
status_withoutPL=""
checksum_withoutPL=""
res_proofsize=""
res_runtime_withPL=""
res_mem_withPL=""
answer_withPL=""
status_withPL=""
checksum_withPL=""
res_runtime_proofchecker=""
res_mem_proofchecker=""
res_proofcheck_succeeded=""

# Read the instance once, to not have overhead in the parsing for the first solver call.
instance=/dev/shm/${filename}.${extension}
cp $instances/${filename}.${extension} $instance

if [ -n "$script_without_PL" ]; then
  # run solver without prooflogging
  $loc_bin/runlim -r $TIMEOUT_SOLVER -s $MEMOUT_SOLVER -o $loc_outputs/$experiment_name/${filename}_vanilla_out.txt $script_without_PL $instance > $loc_outputs/$experiment_name/${filename}_vanilla_solveroutput.txt 2>&1
  
  # extract results
  res_runtime_withoutPL=$(cat $loc_outputs/$experiment_name/${filename}_vanilla_out.txt | grep 'real:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');
  res_mem_withoutPL=$(cat $loc_outputs/$experiment_name/${filename}_vanilla_out.txt | grep 'space:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');
  status_withoutPL=$(cat $loc_outputs/$experiment_name/${filename}_vanilla_out.txt | grep 'status:' | awk '{print $3}');

  if grep -q "UNSATISFIABLE" $loc_outputs/$experiment_name/${filename}_vanilla_solveroutput.txt
  then
    answer_withoutPL="UNSAT"
  elif grep -q "OPTIMUM FOUND" $loc_outputs/$experiment_name/${filename}_vanilla_solveroutput.txt
  then
    answer_withoutPL="SAT"
  else
    answer_withoutPL="NONE"
  fi

  if [ -n "$script_calculate_checksum" ]; then
    checksum_withoutPL=$($script_calculate_checksum $loc_outputs/$experiment_name/${filename}_vanilla_solveroutput.txt)
  fi
else 
  status_withoutPL=ok
fi

if [ -n "$script_with_PL" ] && ([ "$status_withoutPL" == "ok" ] || [ "$checkpreviousstep" == "no" ]); then
  # run solver with prooflogging
  $loc_bin/runlim -r $TIMEOUT_SOLVER -s $MEMOUT_SOLVER -o $loc_outputs/$experiment_name/${filename}_pl_out.txt $script_with_PL $instance $loc_proofs/$experiment_name/${filename}_proof.pbp > $loc_outputs/$experiment_name/${filename}_pl_solveroutput.txt 2>&1
  
  # extract results
  res_runtime_withPL=$(cat $loc_outputs/$experiment_name/${filename}_pl_out.txt | grep 'real:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');
  res_mem_withPL=$(cat $loc_outputs/$experiment_name/${filename}_pl_out.txt | grep 'space:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');
  status_withPL=$(cat $loc_outputs/$experiment_name/${filename}_pl_out.txt | grep 'status:' | awk '{print $3}');
  res_proofsize=$(stat --printf="%s" $loc_proofs/$experiment_name/${filename}_proof.pbp)
  if [[ "$res_proofsize" == "" ]] ;  then
      res_proofsize=""
  fi


  if grep -q "UNSATISFIABLE" $loc_outputs/$experiment_name/${filename}_pl_solveroutput.txt
  then
    answer_withPL="UNSAT"
  elif grep -q "OPTIMUM FOUND" $loc_outputs/$experiment_name/${filename}_pl_solveroutput.txt
  then
    answer_withPL="SAT"
  else
    answer_withPL="NONE"
  fi

  if [ -n "$script_calculate_checksum" ]; then
    checksum_withPL=$($script_calculate_checksum $loc_outputs/$experiment_name/${filename}_pl_solveroutput.txt)
  fi
elif [ "$status_withoutPL" != "ok" ]; then
  status_withPL="notok"
else 
  status_withPL=ok
fi

if [ "$checkproof" == "yes" ] && ([ "$status_withPL" == "ok" ] || [ "$checkpreviousstep" == "no" ]); then
  # run proof checker
  source $loc_bin/pyenv/bin/activate
  $loc_bin/runlim -r $TIMEOUT_VERIPB -s $MEMOUT_VERIPB -o $loc_outputs/$experiment_name/${filename}_verification.txt python -m veripb --stats --checkDeletion --wcnf $instance $loc_proofs/$experiment_name/${filename}_proof.pbp > $loc_outputs/$experiment_name/${filename}_veripb_output.txt 2>&1

  # extract results
  res_runtime_proofchecker=$(cat $loc_outputs/$experiment_name/${filename}_verification.txt | grep 'real:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');
  res_mem_proofchecker=$(cat $loc_outputs/$experiment_name/${filename}_verification.txt | grep 'space:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?');


  if grep -q "succeeded" $loc_outputs/$experiment_name/${filename}_veripb_output.txt; then
    res_proofcheck_succeeded=1
  else
        res_proofcheck_succeeded=0	
        # cp $instance $loc_verification_failed
        # cp $loc_outputs/${filename}_vanilla.txt $loc_verification_failed
        # cp $loc_outputs/${filename}_verification.txt $loc_verification_failed
        # cp $loc_proofs/${filename}_proof.pbp $loc_verification_failed
        # cp $loc_running_scripts/${filename}.${extension}.sh $loc_verification_failed
  fi
fi

resultline="$filename"
if [ -n "$script_without_PL" ]; then
  resultline+=", $res_runtime_withoutPL, $res_mem_withoutPL, $answer_withoutPL"
  if [ -n "$script_calculate_checksum" ]; then
    resultline+=", $checksum_withoutPL"
  fi
fi
if [ -n "$script_with_PL" ]; then
  resultline+=", $res_runtime_withPL, $res_mem_withPL, $answer_withPL, $res_proofsize"
  if [ -n "$script_calculate_checksum" ]; then
    resultline+=", $checksum_withPL"
  fi
fi
if [ "$checkproof" == "yes" ]; then
  resultline+=", $res_runtime_proofchecker, $res_mem_proofchecker, $res_proofcheck_succeeded"
fi
echo "$resultline" >> $loc_results/$experiment_name/"$filename"_result.csv

# rm $loc_outputs/${filename}*
rm $instance
rm $loc_proofs/$experiment_name/${filename}*
rm $loc_running_scripts/$experiment_name/${filename}*
