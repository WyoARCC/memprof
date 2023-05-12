#!/bin/bash
#usage: memprof.sh cmd args...

USAGE="Usage : $0 cmd [args]"

if [ "$#" -eq "0" ]
then
   echo $USAGE
   exit 1
fi

# launch cmd
#echo "cmd: [ $@ ]"
$@ &
PROCESS_PID=$!

MEMPROF_DIR=./memprof

if [ ! -d "$MEMPROF_DIR" ]; then
   mkdir $MEMPROF_DIR
fi

# Function to get the exit code for the subprocess.
non_blocking_wait() {
    PID=$1
    if [ ! -d "/proc/$PID" ]; then
        wait $PID
        CODE=$?
    else
        CODE=127
    fi
    return $CODE
}


LOG_FILE="$MEMPROF_DIR/memprof-${PROCESS_PID}.csv"
#LOG_FILE="/projects/mayo/BrainGWAS/35PhenosSelectedForTheGrant_TCX_All/memprof-${PROCESS_PID}.csv"
TMP_FILE="/tmp/memprof-${PROCESS_PID}.tmp"
TMP_FILE2=${TMP_FILE}.2
LOG_FILE2=${LOG_FILE}.2

if [ -z "$PBS_JOBID" ]; then
        echo "jobid: $PBS_JOBID" > $LOG_FILE
elif [ -z "$SLURM_JOB_ID" ]; then
        echo "jobid: $SLURM_JOB_ID" > $LOG_FILE
fi

echo "node: `uname -n`" >> $LOG_FILE
echo "# CPUs: `cat /proc/cpuinfo | grep processor | wc | awk '{print $1}'`" >> $LOG_FILE
echo "time: `date`" >> $LOG_FILE
echo "cmd: $@" >> $LOG_FILE
echo "ElapsedTime(s),Threads(#),%CPU,VmSize(kB),VmRSS(kB),rchar(bytes),wchar(bytes)" >> $LOG_FILE

PERIOD=1 # seconds
IO_READ_LAST=0
IO_WRITE_LAST=0
#IO_READ_LAST2=0
#IO_WRITE_LAST2=0
EXIT_CODE=127
ELAPSED_TIME=`date +%s`
CPU=`top -b -p $PROCESS_PID -n 1 | sed 1,7d | grep $PROCESS_PID | awk '{print $9}'`

# Monitor memory and IO usage until cmd exits
while [ -f /proc/$PROCESS_PID/exe ]
do
   cat /proc/$PROCESS_PID/status /proc/$PROCESS_PID/io > $TMP_FILE
   #cat /proc/$PROCESS_PID/task/*/io > $TMP_FILE2

   N_THREADS=`grep Threads $TMP_FILE | awk '{ print $2 }'`
   VM_SIZE=`grep VmSize $TMP_FILE | awk '{ print $2 }'`
   VM_RSS=`grep VmRSS $TMP_FILE | awk '{ print $2 }'`
   IO_READ=`grep rchar $TMP_FILE | awk '{ print $2 }'`
   IO_WRITE=`grep wchar $TMP_FILE | awk '{ print $2 }'`

   IO_READ_ACTUAL=`expr $IO_READ - $IO_READ_LAST`
   IO_WRITE_ACTUAL=`expr $IO_WRITE - $IO_WRITE_LAST`

   #IO_READ2=0
   #IO_WRITE2=0
   #for i in `cat $TMP_FILE2 | grep rchar | awk '{print $2}'`
   #do
   #   IO_READ2=`expr $IO_READ2 + $i`
   #done

   #for i in `cat $TMP_FILE2 | grep wchar | awk '{print $2}'`
   #do
   #   IO_WRITE2=`expr $IO_WRITE2 + $i`
   #done

   #IO_READ_ACTUAL2=`expr $IO_READ2 - $IO_READ_LAST2`
   #IO_WRITE_ACTUAL2=`expr $IO_WRITE2 - $IO_WRITE_LAST2`

   echo "$ELAPSED_TIME,$N_THREADS,$CPU,$VM_SIZE,$VM_RSS,$IO_READ_ACTUAL,$IO_WRITE_ACTUAL" >> $LOG_FILE

   IO_READ_LAST=$IO_READ
   IO_WRITE_LAST=$IO_WRITE

   #IO_READ_LAST2=$IO_READ2
   #IO_WRITE_LAST2=$IO_WRITE2

   CURRENT_TIME=`date +%s`
   while [ `expr $CURRENT_TIME - $ELAPSED_TIME` -lt 1 ]
   do
       sleep 0.1;
       CURRENT_TIME=`date +%s`;
   done

   ELAPSED_TIME=$CURRENT_TIME
   CPU=`top -b -p $PROCESS_PID -n 1 | sed 1,7d | grep $PROCESS_PID | awk '{print $9}'`
done
non_blocking_wait $PROCESS_PID
   TEMP_CODE=$?
   if [ $TEMP_CODE -ne 127 ]; then
       EXIT_CODE=$TEMP_CODE
  fi

#echo "DONE $PROCESS_PID"

#rm $TMP_FILE

exit $EXIT_CODE
