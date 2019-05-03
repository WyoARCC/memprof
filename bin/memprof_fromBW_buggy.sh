#!/bin/bash
#usage: memprof.sh cmd args...

USAGE="Usage : $0 cmd [args]"

if [ "$#" -eq "0" ] 
then
   echo $USAGE
   exit 1
fi

MEMPROF_DIR=./

if [ ! -d "$MEMPROF_DIR" ]; then
   mkdir $MEMPROF_DIR
fi

# launch cmd
#echo "cmd: [ $@ ]"
$@ &
PROCESS_PID=$!

LOG_FILE="$MEMPROF_DIR/memprof-${PBS_JOBID}-${PROCESS_PID}.csv"
TMP_FILE1="memprof-${PBS_JOBID}-${PROCESS_PID}.tmp1"
TMP_FILE2="memprof-${PBS_JOBID}-${PROCESS_PID}.tmp2"

#cat /proc/fs/lustre/llite/snx11003-*/stats > $TMP_FILE2
IO_READ_LAST=`grep read_bytes $TMP_FILE2 | awk '{ print $7 }'`
IO_WRITE_LAST=`grep write_bytes $TMP_FILE2 | awk '{ print $7 }'`
IO_READ_OP_LAST=`grep read_bytes $TMP_FILE2 | awk '{ print $2 }'`
IO_WRITE_OP_LAST=`grep write_bytes $TMP_FILE2 | awk '{ print $2 }'`

echo "jobid: $PBS_JOBID" > $LOG_FILE
echo "node: `uname -n`" >> $LOG_FILE
echo "# CPUs: `cat /proc/cpuinfo | grep processor | wc | awk '{print $1}'`" >> $LOG_FILE
echo "time: `date`" >> $LOG_FILE
echo "cmd: $@" >> $LOG_FILE
echo "ElapsedTime(s),Threads(#),%CPU,VmSize(kB),VmRSS(kB),rchar(bytes),wchar(bytes),rchar(#ops),wchar(#ops)" >> $LOG_FILE

PERIOD=1 # seconds
LAST_TIME=`date +%s`
#CPU=`top -b -p $PROCESS_PID -n 1 | grep $PROCESS_PID | awk '{print $9}'`

# Monitor memory and IO usage until cmd exits
while [ -f /proc/$PROCESS_PID/exe ]
do

   #CPU=`top -b -p $PROCESS_PID -n 1 | grep $PROCESS_PID | awk '{print $9}'`
   #CPU_WAIT=`top -b -p $PROCESS_PID -n 1 | grep Cpu | awk '{print $6}'`
   top -b -p $PROCESS_PID -n 1 > $TMP_FILE1
   #cat /proc/$PROCESS_PID/status /proc/fs/lustre/llite/snx11003-*/stats > $TMP_FILE2
   cat /proc/$PROCESS_PID/status > $TMP_FILE2
   #cat /proc/$PROCESS_PID/status /proc/$PROCESS_PID/net/dev > $TMP_FILE1
   #cat /proc/$PROCESS_PID/task/*/io > $TMP_FILE2

   CPU=`grep $PROCESS_PID $TMP_FILE1 | awk '{print $9}'`
   #CPU_WAIT=`grep Cpu $TMP_FILE1 | awk '{print substr($5,0,index($5,"%")-1);}'`
   
   N_THREADS=`grep Threads $TMP_FILE2 | awk '{ print $2 }'`
   VM_SIZE=`grep VmSize $TMP_FILE2 | awk '{ print $2 }'`
   VM_RSS=`grep VmRSS $TMP_FILE2 | awk '{ print $2 }'`
   IO_READ=`grep read_bytes $TMP_FILE2 | awk '{ print $7 }'`
   IO_WRITE=`grep write_bytes $TMP_FILE2 | awk '{ print $7 }'`
   IO_READ_OP=`grep read_bytes $TMP_FILE2 | awk '{ print $2 }'`
   IO_WRITE_OP=`grep write_bytes $TMP_FILE2 | awk '{ print $2 }'`

   IO_READ_ACTUAL=`expr $IO_READ - $IO_READ_LAST`
   IO_WRITE_ACTUAL=`expr $IO_WRITE - $IO_WRITE_LAST`
   IO_READ_OP_ACTUAL=`expr $IO_READ_OP - $IO_READ_OP_LAST`
   IO_WRITE_OP_ACTUAL=`expr $IO_WRITE_OP - $IO_WRITE_OP_LAST`

   echo "$LAST_TIME,$N_THREADS,$CPU,$VM_SIZE,$VM_RSS,$IO_READ_ACTUAL,$IO_WRITE_ACTUAL,$IO_READ_OP_ACTUAL,$IO_WRITE_OP_ACTUAL" >> $LOG_FILE

   IO_READ_LAST=$IO_READ
   IO_WRITE_LAST=$IO_WRITE
   IO_READ_OP_LAST=$IO_READ_OP
   IO_WRITE_OP_LAST=$IO_WRITE_OP
   
   CURRENT_TIME=`date +%s`
   while [ `expr $CURRENT_TIME - $LAST_TIME` -lt 1 ]
   do
       sleep 0.1;
       CURRENT_TIME=`date +%s`;
   done

   LAST_TIME=$CURRENT_TIME
done

#echo "DONE $PROCESS_PID"

#rm $TMP_FILE1 $TMP_FILE2

#exit $?

