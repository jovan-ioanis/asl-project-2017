reset

set xlabel "Server Service Time at middleware [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:60000]
set xrange [0:10]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top right vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 5.0
#set bars 1.8
set style data histogram
set style histogram gap 1
#set style histogram errorbars gap 1 lw 6
set style fill solid 1.0
set boxwidth 0.5 relative

set style line 1 linecolor rgb '#C4B205'
set style line 2 linecolor rgb '#D43849'
set style line 3 linecolor rgb '#0B547E'
set style line 4 linecolor rgb '#63CB9D'
set style line 5 linecolor rgb '#2f1b51'

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119

set terminal pdf enhanced size 5,3.5
set output "HISTOGRAM_MW_6KEYS_NONSHARDED_SST.pdf"

plot 'histogram_mw_6keys_nonsharded_sst.csv' using 1:2 with boxes ls 3 title "6 Keys"



reset

set xlabel "Server Service Time at middleware [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:60000]
set xrange [0:10]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top right vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 5.0
#set bars 1.8
set style data histogram
set style histogram gap 1
#set style histogram errorbars gap 1 lw 6
set style fill solid 1.0
set boxwidth 0.5 relative

set style line 1 linecolor rgb '#C4B205'
set style line 2 linecolor rgb '#D43849'
set style line 3 linecolor rgb '#0B547E'
set style line 4 linecolor rgb '#63CB9D'
set style line 5 linecolor rgb '#2f1b51'

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119

set terminal pdf enhanced size 5,3.5
set output "HISTOGRAM_MW_6KEYS_SHARDED_SST.pdf"

plot 'histogram_mw_6keys_sharded_sst.csv' using 1:2 with boxes ls 3 title "6 Keys"