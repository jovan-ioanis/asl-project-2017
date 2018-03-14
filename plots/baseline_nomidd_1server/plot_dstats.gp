reset

set xlabel "Number of Clients" font ",18" offset 0,-0.7
set ylabel "Mean Traffic [KB/s]" font ",18" offset -3,0
set yrange [0:15000]

set xtics nomirror font ",15" scale 0.8 rotate by -45
set ytics nomirror font ",15" scale 0.8 
set grid xtics ytics back
set key top right vertical reverse Left font ",15" spacing 0.7
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
set output "NETWORK_READ-ONLY.pdf"
plot newhistogram "", 'dstat_memtier.csv' using 14:($14-$15):($14+$15):xtic(1) ls 1 title "memtier sent", \
newhistogram "", 'dstat_memcached.csv' using 10:($10-$11):($10+$11):xtic(1) ls 2 title "memcached received", \
newhistogram "", 'dstat_memcached.csv' using 14:($14-$15):($14+$15):xtic(1) ls 3 title "memcached sent", \
newhistogram "", 'dstat_memtier.csv' using 10:($10-$11):($10+$11):xtic(1) ls 4 title "memtier received"




reset

set xlabel "Number of Clients" font ",18" offset 0,-0.7
set ylabel "Mean Traffic [KB/s]" font ",18" offset -3,0
set yrange [0:40000]

set xtics nomirror font ",15" scale 0.8 rotate by -45
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top right vertical reverse Left font ",15" spacing 0.7
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
set output "NETWORK_WRITE-ONLY.pdf"
plot newhistogram "", 'dstat_memtier.csv' using 16:($16-$17):($16+$17):xtic(1) ls 1 title "memtier sent", \
newhistogram "", 'dstat_memcached.csv' using 12:($12-$13):($12+$13):xtic(1) ls 2 title "memcached received", \
newhistogram "", 'dstat_memcached.csv' using 16:($16-$17):($16+$17):xtic(1) ls 3 title "memcached sent", \
newhistogram "", 'dstat_memtier.csv' using 12:($12-$13):($12+$13):xtic(1) ls 4 title "memtier received"