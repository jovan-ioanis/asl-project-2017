reset

set xlabel "Number of Keys in GET Request" font ",18" offset 0,-0.7
set ylabel "Response Time [ms]" font ",18" offset -3,0
set yrange [0:10]

set xtics nomirror font ",15" scale 0.8 rotate by -45
set ytics nomirror font ",15" scale 0.8 
set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 4.0
#set bars 1.8
set style data histogram
set style histogram gap 1
set style histogram errorbars gap 1 lw 6
set style fill solid 1.0
set boxwidth 1.5 relative

set style line 1 linecolor rgb '#C4B205'
set style line 2 linecolor rgb '#D43849'
set style line 3 linecolor rgb '#0B547E'
set style line 4 linecolor rgb '#63CB9D'
set style line 5 linecolor rgb '#2f1b51'

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119


set terminal pdf enhanced size 10,3.5
set output "PERCENTILES_SHARDED.pdf"

plot newhistogram "", 'response_time_and_percentiles_sharded.csv' using 4:($4-$5):($4+$5):xtic(1) ls 1 title "25th percentile", \
newhistogram "", 'response_time_and_percentiles_sharded.csv' using 6:($6-$7):($6+$7):xtic(1) ls 2 title "50th percentile", \
newhistogram "", 'response_time_and_percentiles_sharded.csv' using 8:($8-$9):($8+$9):xtic(1) ls 3 title "75th percentile", \
newhistogram "", 'response_time_and_percentiles_sharded.csv' using 10:($10-$11):($10+$11):xtic(1) ls 4 title "90th percentile", \
newhistogram "", 'response_time_and_percentiles_sharded.csv' using 12:($12-$13):($12+$13):xtic(1) ls 5 title "99th percentile"

#plot newhistogram "", 'response_time_and_percentiles_sharded.csv' using 4:xtic(1) ls 2 title "25th percentile", \
#'' using 0:4:($4-$5):($4+$5) with yerrorbars ls 5 pt 0 lw 4 title "", \
#newhistogram "", 'response_time_and_percentiles_sharded.csv' using 6:xtic(1) ls 1 title "50th percentile", \
#'' using "5.0 6.0 7.0 8.0":6:($6-$7):($6+$7) with yerrorbars ls 5 pt 0 lw 4 title "", \
#newhistogram "", 'response_time_and_percentiles_sharded.csv' using 8:xtic(1) ls 3 title "75th percentile", \
#'' using 0:8:($8-$9):($8+$9) with yerrorbars ls 5 pt 0 lw 4 title "", \
#newhistogram "", 'response_time_and_percentiles_sharded.csv' using 10:xtic(1) ls 4 title "90th percentile", \
#'' using 0:10:($10-$11):($10+$11) with yerrorbars ls 5 pt 0 lw 4 title "", \
#newhistogram "", 'response_time_and_percentiles_sharded.csv' using 12:xtic(1) ls 5 title "99th percentile", \
#'' using 0:12:($12-$13):($12+$13) with yerrorbars ls 5 pt 0 lw 4 title ""



reset

set xlabel "Number of Keys in GET Request" font ",18" offset 0,-0.7
set ylabel "Response Time [ms]" font ",18" offset -3,0
set yrange [0:10]

set xtics nomirror font ",15" scale 0.8 rotate by -45
set ytics nomirror font ",15" scale 0.8 
set grid xtics ytics back
set key top left vertical reverse Left font ",15" spacing 0.7
set border 3 lw 4
set lmargin 15.0
set bmargin 4.0
#set bars 1.8
set style data histogram
set style histogram gap 1
set style histogram errorbars gap 1 lw 6
set style fill solid 1.0
set boxwidth 1.5 relative

set style line 1 linecolor rgb '#C4B205'
set style line 2 linecolor rgb '#D43849'
set style line 3 linecolor rgb '#0B547E'
set style line 4 linecolor rgb '#63CB9D'
set style line 5 linecolor rgb '#2f1b51'

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119

set terminal pdf enhanced size 10,3.5
set output "PERCENTILES_NONSHARDED.pdf"
plot newhistogram "", 'response_time_and_percentiles_nonsharded.csv' using 4:($4-$5):($4+$5):xtic(1) ls 1 title "25th percentile", \
newhistogram "", 'response_time_and_percentiles_nonsharded.csv' using 6:($6-$7):($6+$7):xtic(1) ls 2 title "50th percentile", \
newhistogram "", 'response_time_and_percentiles_nonsharded.csv' using 8:($8-$9):($8+$9):xtic(1) ls 3 title "75th percentile", \
newhistogram "", 'response_time_and_percentiles_nonsharded.csv' using 10:($10-$11):($10+$11):xtic(1) ls 4 title "90th percentile", \
newhistogram "", 'response_time_and_percentiles_nonsharded.csv' using 12:($12-$13):($12+$13):xtic(1) ls 5 title "99th percentile"