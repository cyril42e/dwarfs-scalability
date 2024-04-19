#!/bin/sh

ARGV1=${1:-latest}

# create size

gnuplot << EOF &
set term wxt size 1024,480
set grid

set xlabel "dataset size (GiB)"
set logscale x 2
set key left top
set yrange [0.5:5.0]

set multiplot layout 1,3 title "Compression ratio wrt tar BS inf"
plot for [i=6:13] "$ARGV1/tar_create-size.csv"      u (\$2/1024**3):(column(i)/\$4) w lp pt 1 dt 1 lw 1 t sprintf("tar BS %s",      columnheader(i))
set format y ""
plot for [i=6:8]  "$ARGV1/squashfs_create-size.csv" u (\$2/1024**3):(column(i)/\$4) w lp pt 1 dt 1 lw 1 t sprintf("squashfs BS %s", columnheader(i))
set format y ""
plot for [i=6:13] "$ARGV1/dwarfs_create-size.csv"   u (\$2/1024**3):(column(i)/\$4) w lp pt 1 dt 1 lw 1 t sprintf("dwarfs BS %s",   columnheader(i))
unset multiplot

pause mouse close
EOF

# create time

gnuplot << EOF &
set term wxt size 1024,480
set grid

set xlabel "dataset size (GiB)"
set logscale x 2
set key left top
set yrange [5:55]

set multiplot layout 1,3 title "Archive creation average rate (MB/s)"
plot for [i=6:13] "$ARGV1/tar_create-time.csv"      u (\$2/1024**3):(\$2/column(i)/1024**2) w lp pt 1 t sprintf("tar BS %s",      columnheader(i))
set format y ""
plot for [i=6:8]  "$ARGV1/squashfs_create-time.csv" u (\$2/1024**3):(\$2/column(i)/1024**2) w lp pt 1 t sprintf("squashfs BS %s", columnheader(i))
set format y ""
plot for [i=6:13] "$ARGV1/dwarfs_create-time.csv"   u (\$2/1024**3):(\$2/column(i)/1024**2) w lp pt 1 t sprintf("dwarfs BS %s",   columnheader(i))
unset multiplot

pause mouse close
EOF


# read time

gnuplot << EOF &
set term wxt size 1024,480
set grid

set xlabel "dataset size (GiB)"
set logscale x 2
set logscale y 2
set yrange [0.5:8192]

set multiplot layout 1,3 title "Read time (s)"
set key left bottom
plot for [i=6:13] "$ARGV1/tar_read-time.grep.csv"     u (\$2/1024**3):(column(i)) w lp pt 1 t sprintf("tar BS %s",      columnheader(i))
set key left top
set format y ""
plot for [i=6:8] "$ARGV1/squashfs_read-time.grep.csv" u (\$2/1024**3):(column(i)) w lp pt 1 t sprintf("squashfs BS %s", columnheader(i))
set format y ""
plot for [i=6:13] "$ARGV1/dwarfs_read-time.grep.csv"  u (\$2/1024**3):(column(i)) w lp pt 1 t sprintf("dwarfs BS %s",   columnheader(i))
unset multiplot

pause mouse close
EOF
