#!/usr/bin/bash
# Reinitialize a Volt instance with params at run time

. ${HOME}.profile
cd $HOME

# Vars
demodbdir=$1
demo_cfg=$2
volt_ver="11.4"
log_dir="${HOME}/logs"


if [ "$demodbdir" = "" -o "$demo_cfg" = "" ] ; then
  echo Usage: $0 database_dir config.xml 
  exit 1
fi

# Track that we did this - not sure why
if [ ! -d ${log_dir} ] ; then
  mkdir -p ${log_dir} 2> /dev/null
  LOGFILE=${log_dir}/start_voltdb_if_needed`-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
else
  LOGFILE=${log_dir}/start_voltdb_if_needed`-`date '+%y%m%d'-%H%M`.log
  touch $LOGFILE
fi

echo `date` calling init | tee -a $LOGFILE
cd  voltdb-ent-${volt_ver}
pwd | tee -a $LOGFILE
voltdb init --force --dir=$demodbdir --config=$demo_cfg | tee -a $LOGFILE
