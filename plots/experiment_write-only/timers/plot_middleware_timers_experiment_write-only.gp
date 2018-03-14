reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Response Time at Midleware [ms]" font ",17" offset -0.3,0
set yrange [0:55]

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
set output "RESPONSE_TIME_WRITE-ONLY.pdf"
plot 'response_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""


##########################################################################################################################################

reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Net Thread Processing Time [ms]" font ",18" offset -0.3,0
set yrange [0:1]

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
set output "NET-THREAD_PROCESSING_TIME_WRITE-ONLY.pdf"
plot 'netthread_processing_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""



##########################################################################################################################################




reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Wait-In-Queue Time [ms]" font ",18" offset -0.3,0
set yrange [0:55]

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
set output "WAIT-IN-QUEUE_TIME_WRITE-ONLY.pdf"
plot 'wait_in_queue_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""



##########################################################################################################################################



reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Worker Pre-Processing Time [ms]" font ",18" offset -0.3,0
set yrange [0:1]

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
set output "WORKER_PRE-PROCESSING_TIME_WRITE-ONLY.pdf"
plot 'worker_preprocessing_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""



##########################################################################################################################################



reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Server Service Time [ms]" font ",18" offset -0.3,0
set yrange [0:55]

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
set output "SERVER_SERVICE_TIME_WRITE-ONLY.pdf"
plot 'server_service_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""



##########################################################################################################################################


reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Worker Post-Processing Time [ms]" font ",18" offset -0.3,0
set yrange [0:1]

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
set output "WORKER_POST-PROCESSING_TIME_WRITE-ONLY.pdf"
plot 'worker_postprocessing_time_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""


##########################################################################################################################################



reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Queue Size" font ",18" offset -0.3,0
set yrange [0:200]

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
set output "QUEUE_SIZE_WRITE-ONLY.pdf"
plot 'queue_size_write-only.csv' using 1:2 with linespoints linestyle 1 title "8 WORKERS", \
'' using 1:4 with linespoints linestyle 3 title "16 WORKERS", \
'' using 1:6 with linespoints linestyle 5 title "32 WORKERS", \
'' using 1:8 with linespoints linestyle 7 title "64 WORKERS", \
'' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", \
'' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 4 title "", \
'' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 6 title "", \
'' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 8 title ""

