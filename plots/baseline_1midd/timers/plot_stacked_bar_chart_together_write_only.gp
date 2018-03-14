reset

set xlabel "Number of Clients" font ",15" offset 0,-0.7
set ylabel "Response time and its constituents [ms]" font ",13" offset -0.3,0
set yrange [0:25]

set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top right horizontal reverse Left font ",15" spacing 1.7
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
#set bars 1.8
set style data histogram
set style histogram rowstacked
set style fill solid 1.0
set boxwidth 0.8 relative

set style line 1 linecolor rgb '#C4B205'
set style line 2 linecolor rgb '#D43849'
set style line 3 linecolor rgb '#0B547E'
set style line 4 linecolor rgb '#63CB9D'
set style line 5 linecolor rgb '#2f1b51'

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119

set terminal pdf enhanced size 13,4
set output "ALL_TIMES_TOGETHER_WRITE-ONLY.pdf"
plot  newhistogram "8 WORKERS", 'all_times_8workers_write-only.csv' \
   using 2 ls 1 title "Net-Thread Time", \
'' using 3 ls 2 title "Wait-In-Queue Time", \
'' using 4 ls 3 title "Worker Pre-Processing Time", \
'' using 5 ls 4 title "Servers Service Time", \
'' using 6:xtic(1) ls 5 title "Worker Post-Processing Time", \
newhistogram "16 WORKERS", 'all_times_16workers_write-only.csv' \
   using 2 ls 1 title "", \
'' using 3 ls 2 title "", \
'' using 4 ls 3 title "", \
'' using 5 ls 4 title "", \
'' using 6:xtic(1) ls 5 title "", \
newhistogram "32 WORKERS", 'all_times_32workers_write-only.csv' \
   using 2 ls 1 title "", \
'' using 3 ls 2 title "", \
'' using 4 ls 3 title "", \
'' using 5 ls 4 title "", \
'' using 6:xtic(1) ls 5 title "", \
newhistogram "64 WORKERS", 'all_times_64workers_write-only.csv' \
   using 2 ls 1 title "", \
'' using 3 ls 2 title "", \
'' using 4 ls 3 title "", \
'' using 5 ls 4 title "", \
'' using 6:xtic(1) ls 5 title ""