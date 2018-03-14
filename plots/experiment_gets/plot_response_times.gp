reset

set xlabel "Number of Keys in GET Request" font ",18" offset 0,-0.7
set ylabel "Response Time at client [ms]" font ",18" offset -3,0
set yrange [0:5]

set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 4.0
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
set output "RESPONSE_TIME_SHARDED.pdf"

plot 'response_time_and_percentiles_sharded.csv' using 0:2:xtic(1) with boxes ls 2 title "sharded", \
'' using 0:2:($2-$3):($2+$3) with yerrorbars ls 5 pt 0 lw 6 title ""



reset

set xlabel "Number of Keys in GET Request" font ",18" offset 0,-0.7
set ylabel "Response Time at client [ms]" font ",18" offset -3,0
set yrange [0:5]

set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 4.0
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
set output "RESPONSE_TIME_NONSHARDED.pdf"

plot 'response_time_and_percentiles_nonsharded.csv' using 0:2:xtic(1) with boxes ls 4 title "non-sharded", \
'' using 0:2:($2-$3):($2+$3) with yerrorbars ls 5 pt 0 lw 6 title ""