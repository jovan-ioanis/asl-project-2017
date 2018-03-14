reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Throughput at Middleware [req/s]" font ",17" offset -0.3,0
set yrange [0:35000]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top left Left reverse font ",13" spacing 1.2
set auto x
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
set bars 1.8

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#8
set style line 2 linetype 1 linecolor rgb '#D43849' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#16
set style line 4 linetype 1 linecolor rgb '#63CB9D' linewidth 4 pointtype 0 pointsize 0
set style line 5 linetype 1 linecolor rgb '#0B547E' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#32
set style line 6 linetype 1 linecolor rgb '#0B547E' linewidth 4 pointtype 0 pointsize 0
set style line 7 linetype 1 linecolor rgb '#C4B205' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#64
set style line 8 linetype 1 linecolor rgb '#C4B205' linewidth 4 pointtype 0 pointsize 0


set terminal pdf enhanced size 5,3
set output "THROUGHPUT AT MIDDLEWARE - WRITE-ONLY.pdf"
plot 'throughput_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", 'throughput_write-only.csv' using 1:5 with linespoints linestyle 3 title "16 WORKERS", 'throughput_write-only.csv' using 1:8 with linespoints linestyle 5 title "32 WORKERS", 'throughput_write-only.csv' using 1:11 with linespoints linestyle 7 title "64 WORKERS", 'throughput_write-only.csv' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", 'throughput_write-only.csv' using 1:5:($5-$6):($5+$6) with yerrorbars linestyle 4 title "", 'throughput_write-only.csv' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 6 title "", 'throughput_write-only.csv' using 1:11:($11-$12):($11+$12) with yerrorbars linestyle 8 title ""



reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Throughput at Middleware [req/s]" font ",17" offset -0.3,0
set yrange [0:35000]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top left Left reverse font ",13" spacing 1.2
set auto x
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
set bars 1.8

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#8
set style line 2 linetype 1 linecolor rgb '#D43849' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#16
set style line 4 linetype 1 linecolor rgb '#63CB9D' linewidth 4 pointtype 0 pointsize 0
set style line 5 linetype 1 linecolor rgb '#0B547E' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#32
set style line 6 linetype 1 linecolor rgb '#0B547E' linewidth 4 pointtype 0 pointsize 0
set style line 7 linetype 1 linecolor rgb '#C4B205' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#64
set style line 8 linetype 1 linecolor rgb '#C4B205' linewidth 4 pointtype 0 pointsize 0


set terminal pdf enhanced size 5,3
set output "THROUGHPUT AT MIDDLEWARE - READ-ONLY.pdf"
plot 'throughput_read-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", 'throughput_read-only.csv' using 1:5 with linespoints linestyle 3 title "16 WORKERS", 'throughput_read-only.csv' using 1:8 with linespoints linestyle 5 title "32 WORKERS", 'throughput_read-only.csv' using 1:11 with linespoints linestyle 7 title "64 WORKERS", 'throughput_read-only.csv' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", 'throughput_read-only.csv' using 1:5:($5-$6):($5+$6) with yerrorbars linestyle 4 title "", 'throughput_read-only.csv' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 6 title "", 'throughput_read-only.csv' using 1:11:($11-$12):($11+$12) with yerrorbars linestyle 8 title ""



###########################################################################################################################


reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Response Time at Middleware [ms]" font ",18" offset -0.3,0
set yrange [0:38]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top left Left reverse font ",15" spacing 2
set auto x
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
set bars 1.8

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#8
set style line 2 linetype 1 linecolor rgb '#D43849' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#16
set style line 4 linetype 1 linecolor rgb '#63CB9D' linewidth 4 pointtype 0 pointsize 0
set style line 5 linetype 1 linecolor rgb '#0B547E' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#32
set style line 6 linetype 1 linecolor rgb '#0B547E' linewidth 4 pointtype 0 pointsize 0
set style line 7 linetype 1 linecolor rgb '#C4B205' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#64
set style line 8 linetype 1 linecolor rgb '#C4B205' linewidth 4 pointtype 0 pointsize 0

set terminal pdf enhanced size 5,3
set output "RESPONSE TIME AT MIDDLEWARE (from throughput) - WRITE-ONLY.pdf"
plot 'throughput_write-only.csv' using 1:4 with linespoints linestyle 1 title "8 WORKERS", 'throughput_write-only.csv' using 1:7 with linespoints linestyle 3 title "16 WORKERS", 'throughput_write-only.csv' using 1:10 with linespoints linestyle 5 title "32 WORKERS", 'throughput_write-only.csv' using 1:13 with linespoints linestyle 7 title "64 WORKERS"


reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Response Time at Middleware [ms]" font ",18" offset -0.3,0
set yrange [0:38]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key top left Left reverse font ",15" spacing 2
set auto x
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
set bars 1.8

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#8
set style line 2 linetype 1 linecolor rgb '#D43849' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#16
set style line 4 linetype 1 linecolor rgb '#63CB9D' linewidth 4 pointtype 0 pointsize 0
set style line 5 linetype 1 linecolor rgb '#0B547E' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#32
set style line 6 linetype 1 linecolor rgb '#0B547E' linewidth 4 pointtype 0 pointsize 0
set style line 7 linetype 1 linecolor rgb '#C4B205' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#64
set style line 8 linetype 1 linecolor rgb '#C4B205' linewidth 4 pointtype 0 pointsize 0

set terminal pdf enhanced size 5,3
set output "RESPONSE TIME AT MIDDLEWARE (from throughput) - READ-ONLY.pdf"
plot 'throughput_read-only.csv' using 1:4 with linespoints linestyle 1 title "8 WORKERS", 'throughput_read-only.csv' using 1:7 with linespoints linestyle 3 title "16 WORKERS", 'throughput_read-only.csv' using 1:10 with linespoints linestyle 5 title "32 WORKERS", 'throughput_read-only.csv' using 1:13 with linespoints linestyle 7 title "64 WORKERS"