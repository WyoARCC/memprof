# memprof
Memprof is HPC Cluster Program Profiler.  It records the memory, processor, and IO usage of a process.  It will then generate a graph of the results.
* Created By Volodymyr Kindratenko (kindrtnk@illinois.edu) at NCSA (http://www.ncsa.illinois.edu/)

## Requirements 
* Imagemagick [https://imagemagick.org/](https://imagemagick.org/)
* GNUPlot [http://www.gnuplot.info/](http://www.gnuplot.info/)

## Installation
* Download a release or git clone the repository
```
git clone https://github.com/IGBIllinois/memprof.git
```

## Usage
* Run memprof.sh then the program and parameters as you normally would
```
memprof.sh PROGRAM_NAME PARAMETERS
```
* This generates a data files in the memprof directory in your current working directory in the format memprof-JOB_NUMER-PROCESS_ID  The JOB_NUMBER will be either the SLURM or PBS Torque Job Number.  The PROCESS_ID is the local node process number.  If you want it to go to a different directory set the $MEMPROF_DIR environment variable.  
```
export $MEMPROF_DIR="/home/username/memprof"
```
* To generate graph 


