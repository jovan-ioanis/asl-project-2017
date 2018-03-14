reset

set boxwidth 0.8 absolute
set style fill   solid 1.00 noborder
set grid xtics ytics back

set xlabel "Number of Clients" 
set xlabel  offset character 0, -2, 0 font "" textcolor lt -1 norotate
set ylabel "Time" 
set yrange [0.000:25.] noreverse nowriteback

set grid layerdefault   lt 0 linecolor 0 linewidth 0.500,  lt 0 linecolor 0 linewidth 0.500
set key bmargin center horizontal Left reverse noenhanced autotitle columnhead nobox
set style histogram rowstacked title textcolor lt -1 offset character 2, 0.25
set datafile missing '-'
set style data histograms
set xtics border in scale 0,0 nomirror rotate by -45  autojustify
set xtics norangelimit  font ",8"
set xtics   ()
set ytics border in scale 0,0 mirror norotate  autojustify
set ytics  norangelimit autofreq  font ",8"
set ztics border in scale 0,0 nomirror norotate  autojustify
set cbtics border in scale 0,0 mirror norotate  autojustify
set rtics axis in scale 0,0 nomirror norotate  autojustify

DEBUG_TERM_HTIC = 119
DEBUG_TERM_VTIC = 119


set terminal pdf enhanced size 5,5
set output "immigration.pdf"
plot newhistogram "8", 'all_times_8workers_read_only.csv' using "MNT":xtic(1) with boxes lc rgb '#C4B205' t "Net Thread Time", '' u "WIQ" with boxes lc rgb '#D43849' t "Wait In Queue", '' u "PeP" with boxes lc rgb '#0B547E' t "Preprocessing", '' u "SST" with boxes lc rgb '#63CB9D' t "Server Service", '' u "PsP" with boxes lc rgb '#2f1b51' t "Postprocessing", newhistogram "16", 'all_times_16workers_read_only.csv' using "MNT":xtic(1) t "Net Thread Time", '' u "WIQ" t "Wait In Queue", '' u "PeP" t "Preprocessing", '' u "SST" t "Server Service", '' u "PsP" t "Postprocessing", newhistogram "32", 'all_times_32workers_read_only.csv' using "MNT":xtic(1) t "Net Thread Time", '' u "WIQ" t "Wait In Queue", '' u "PeP" t "Preprocessing", '' u "SST" t "Server Service", '' u "PsP" t "Postprocessing", newhistogram "64", 'all_times_64workers_read_only.csv' using "MNT":xtic(1) t "Net Thread Time", '' u "WIQ" t "Wait In Queue", '' u "PeP" t "Preprocessing", '' u "SST" t "Server Service", '' u "PsP" t "Postprocessing"