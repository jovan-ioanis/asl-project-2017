reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_1KEY_NONSHARDED.pdf"

plot 'histograms_mw_nonsharded.csv' using 1:2 with boxes ls 1 title "1 Key"



reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_3KEYS_NONSHARDED.pdf"

plot 'histograms_mw_nonsharded.csv' using 1:4 with boxes ls 2 title "3 Keys"


reset

set xlabel "Response Time at middleware [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:60000]
set xrange [0:10]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_6KEYS_NONSHARDED.pdf"

plot 'histograms_mw_nonsharded.csv' using 1:6 with boxes ls 3 title "6 Keys"


reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_9KEYS_NONSHARDED.pdf"

plot 'histograms_mw_nonsharded.csv' using 1:8 with boxes ls 4 title "9 Keys"



########################################################################################################################


reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_1KEY_SHARDED.pdf"

plot 'histograms_mw_sharded.csv' using 1:2 with boxes ls 1 title "1 Key"

reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_3KEYS_SHARDED.pdf"

plot 'histograms_mw_sharded.csv' using 1:4 with boxes ls 2 title "3 Keys"



reset

set xlabel "Response Time at middleware [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:60000]
set xrange [0:10]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_6KEYS_SHARDED.pdf"

plot 'histograms_mw_sharded.csv' using 1:6 with boxes ls 3 title "6 Keys"



reset

set xlabel "Response Time at client [ms]" font ",18" offset 0,-0.7
set ylabel "Number of GET requests" font ",18" offset -3,0
set yrange [0:80000]

set xtics nomirror out font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8 
#set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
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
set output "HISTOGRAM_MW_9KEYS_SHARDED.pdf"

plot 'histograms_mw_sharded.csv' using 1:8 with boxes ls 4 title "9 Keys"