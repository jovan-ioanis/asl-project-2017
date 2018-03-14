reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Throughput at client [reqs/s]" font ",18" offset -0.3,0
set yrange [0:35000]

set datafile separator ","
set datafile missing "-"
set xtics nomirror font ",15" scale 0.8
set ytics nomirror font ",15" scale 0.8
set grid xtics ytics back
set key bottom right reverse font ",15" spacing 2
set auto x
set border 3 lw 4
set lmargin 13.0
set bmargin 4.0
set bars 1.8

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#read-only
set style line 2 linetype 1 linecolor rgb '#000000' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#write-only
set style line 4 linetype 1 linecolor rgb '#696969' linewidth 4 pointtype 0 pointsize 0


set terminal pdf enhanced size 5,3
set output "THROUGHPUT.pdf"
plot 'source_baseline_nomidd_1server.csv' using 1:2 with linespoints linestyle 1 title "READ-ONLY", 'source_baseline_nomidd_1server.csv' using 1:6 with linespoints linestyle 3 title "WRITE-ONLY", 'source_baseline_nomidd_1server.csv' using 1:2:($2-$3):($2+$3) with yerrorbars linestyle 2 title "", 'source_baseline_nomidd_1server.csv' using 1:6:($6-$7):($6+$7) with yerrorbars linestyle 4 title ""

reset

set xlabel "Number of Clients" font ",18" offset 0,-0.3
set ylabel "Response Time at client [ms]" font ",18" offset -0.3,0
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

set style line 1 linetype 1 linecolor rgb '#D43849' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3 		#read-only
set style line 2 linetype 1 linecolor rgb '#000000' linewidth 4 pointtype 0 pointsize 0
set style line 3 linetype 1 linecolor rgb '#63CB9D' linewidth 6 pointtype 7 pointsize 0.3 pi -0.3   	#write-only
set style line 4 linetype 1 linecolor rgb '#696969' linewidth 4 pointtype 0 pointsize 0

set terminal pdf enhanced size 5,3
set output "RESPONSE_TIME.pdf"
plot 'source_baseline_nomidd_1server.csv' using 1:4 with linespoints linestyle 1 title "READ-ONLY", 'source_baseline_nomidd_1server.csv' using 1:8 with linespoints linestyle 3 title "WRITE-ONLY", 'source_baseline_nomidd_1server.csv' using 1:4:($4-$5):($4+$5) with yerrorbars linestyle 2 title "", 'source_baseline_nomidd_1server.csv' using 1:8:($8-$9):($8+$9) with yerrorbars linestyle 4 title ""
