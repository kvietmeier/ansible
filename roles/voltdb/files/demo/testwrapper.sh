#!/usr/bin/bash
###============================================================================================###
###                                                                                            ###
###   Wrapper for runbenchmark.sh                                                              ###
###                                                                                            ###
###                                                                                            ###
###                                                                                            ###
###                                                                                            ###
###                                                                                            ###
###============================================================================================###

###---
start_tps = 130
max_tps = 150
increment = 1
usercount = 4000000

# Output file
results_dir={HOME}/scripts/output
log_file_name="benchmark_run"

function test_output () {
  # Create logfile of benchmark run
  if [ ! -d $result_dir ] ; then
    mkdir $result_dir 2> /dev/null
  fi

  RESULTSFILE=${results_dir}/${log_file_name}`date '+%y%m%d'`.log
  touch $RESULTSFILE

}
test_output

#  Run bmark with default values
./runbenchmark.sh $start_tps $max_tps $increment $usercount >> $RESULTSFILE 2>&1 &