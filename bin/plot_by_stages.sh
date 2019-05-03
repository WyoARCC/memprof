#!/bin/bash

USAGE="Usage : $0 <datafile> <Title of Graph>"

if [ "$#" -eq "0" ] 
then
   echo $USAGE
   exit 1
fi

input=$1
data=${input}.dat
tmp=${input}.tmp
plot=${input}.gp
epsfig=${input}.eps

tail -n +7 $input | tr "," " " > $tmp
sed ':a;N;$!ba;s/buffers\n//g' $tmp > $tmp.new
sed ':a;N;$!ba;s/cached\n//g' $tmp.new > $tmp
#mv $tmp.new $tmp
rm $tmp.new 
size=`wc $tmp | awk '{ print $1 }'`
start_t=`head -n 1 $tmp | awk '{ print $1 }'`
end_t=`tail -n 1 $tmp | awk '{ print $1 }'`
#title=`grep cmd $input | awk '{ print $2 }'`
#title=`echo "$input : $title"`
title=$2 #new
cat $tmp | awk -v start_t=$start_t '{ print ($1-start_t) " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 }' > $data

xr_max=`tail -n 1 $data | awk '{ print $1 }'`

echo "#gplot file" > $plot
echo "set term postscript eps size 35,35 color solid font 'Helvetica,90'" >> $plot
#echo "set xlabel font \"Helvetica,15\"" >> $plot
#echo "set ylabel font \"Helvetica,18\"" >> $plot
echo "set output \"$epsfig\"" >> $plot

echo "set multiplot layout 3,1 title \"${title}\" " >> $plot
echo "set tmargin 1" >> $plot
echo "unset xtics" >> $plot
echo "set xrange [0:$xr_max]" >> $plot
#echo "set yrange [0:4.5e+06]" >> $plot
echo "set lmarg 32.5" >> $plot
echo "set rmarg 35" >> $plot
echo "set xlabel \"time (s)\" font \"Helvetica,100\" offset 0,1.5" >> $plot
echo "set xtics out nomirror rotate font \"Helvetica,64\"" >> $plot
echo "set ylabel offset 3,0" >> $plot
echo "set key center right outside nobox" >> $plot

echo "set ytics font \"Helvetica,64\"" >> $plot
echo "set y2tics font \"Helvetica,64\"" >> $plot
echo "set ylabel \"Memory usage (kB)\"" >> $plot
echo "plot '$data' using 1:4 with lines lw 5 title \"VmSize (kB)\", '$data' using 1:5 with lines lw 5 lt 2 title \"VmRSS (kB)\"" >> $plot

#echo "set key center right outside nobox" >> $plot
echo "set ytics" >> $plot
echo "set y2tics" >> $plot
#echo "set yrange [0:6e+08]" >> $plot
echo "set ylabel \"I/O (bytes/sec)\"" >> $plot
echo "plot '$data' using 1:6 with lines lw 5 title \"rchar(bytes/sec)\", '$data' using 1:7 with lines lw 5 lt 2 title \"wchar(bytes/sec)\"" >> $plot

echo "set key center right outside nobox" >> $plot
echo "set ytics nomirror" >> $plot
echo "set y2tics" >> $plot
echo "set yrange [0:100]" >> $plot
echo "set ylabel \"# of threads\"" >> $plot
echo "set autoscale y2" >> $plot
echo "set y2label \"CPU load (%)\"" >> $plot
echo "set xtics out nomirror rotate font \"Helvetica,64\"" >> $plot
echo "set xlabel \"time (s)\" font \"Helvetica,100\"" >> $plot
echo "plot '$data' using 1:2 with lines lw 5 title \"# threads\" axes x1y1, '$data' using 1:3 with lines lw 3 lt 2 title \"% CPU\" axes x1y2" >> $plot

echo "unset multiplot" >> $plot

gnuplot $plot
convert $epsfig $input.png 
