reset

set xlabel "Number of Clients" font ",13" offset 0,-0.3
set ylabel "Throughput on client-side [req/s]" font ",13" offset -0.3,0
set yrange [0:35000]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",12" scale 0.8
set ytics nomirror font ",12" scale 0.8
set grid xtics ytics back
set key top right font ",13" spacing 2
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


set terminal pdf enhanced size 5,5
set output "THROUGHPUT AT MEMTIER - WRITE-ONLY.pdf"
plot 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:6 with linespoints linestyle 3 title "16 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:10 with linespoints linestyle 5 title "32 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:14 with linespoints linestyle 7 title "64 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 4 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:10:($10-$11):($10+$11) with yerrorbars linestyle 6 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:14:($14-$15):($14+$15) with yerrorbars linestyle 8 title ""



reset

set xlabel "Number of Clients" font ",13" offset 0,-0.3
set ylabel "Throughput on client-side [req/s]" font ",13" offset -0.3,0
set yrange [0:35000]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",12" scale 0.8
set ytics nomirror font ",12" scale 0.8
set grid xtics ytics back
set key top right font ",13" spacing 2
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


set terminal pdf enhanced size 5,5
set output "THROUGHPUT AT MEMTIER - READ-ONLY.pdf"
plot 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:6 with linespoints linestyle 3 title "16 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:10 with linespoints linestyle 5 title "32 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:14 with linespoints linestyle 7 title "64 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 4 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:10:($10-$11):($10+$11) with yerrorbars linestyle 6 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:14:($14-$15):($14+$15) with yerrorbars linestyle 8 title ""


#####################################################################################################################



reset

set xlabel "Number of Clients" font ",13" offset 0,-0.3
set ylabel "Response Time on client-side [ms]" font ",13" offset -0.3,0
set yrange [0:38]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",12" scale 0.8
set ytics nomirror font ",12" scale 0.8
set grid xtics ytics back
set key top left font ",13" spacing 2
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

set terminal pdf enhanced size 5,5
set output "RESPONSE TIME AT MEMTIER - WRITE-ONLY.pdf"
plot 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:4 with linespoints linestyle 1 title "8 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:8 with linespoints linestyle 3 title "16 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:12 with linespoints linestyle 5 title "32 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:16 with linespoints linestyle 7 title "64 WORKERS", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 2 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 4 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:12:($12-$13):($12+$13) with yerrorbars linestyle 6 title "", 'memtier_logs_baseline_1midd_WRITE-ONLY.csv' using 1:16:($16-$17):($16+$17) with yerrorbars linestyle 8 title ""





reset

set xlabel "Number of Clients" font ",13" offset 0,-0.3
set ylabel "Response Time on client-side [ms]" font ",13" offset -0.3,0
set yrange [0:38]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",12" scale 0.8
set ytics nomirror font ",12" scale 0.8
set grid xtics ytics back
set key top left font ",13" spacing 2
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

set terminal pdf enhanced size 5,5
set output "RESPONSE TIME AT MEMTIER - READ-ONLY.pdf"
plot 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:4 with linespoints linestyle 1 title "8 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:8 with linespoints linestyle 3 title "16 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:12 with linespoints linestyle 5 title "32 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:16 with linespoints linestyle 7 title "64 WORKERS", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 2 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 4 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:12:($12-$13):($12+$13) with yerrorbars linestyle 6 title "", 'memtier_logs_baseline_1midd_READ-ONLY.csv' using 1:16:($16-$17):($16+$17) with yerrorbars linestyle 8 title ""
