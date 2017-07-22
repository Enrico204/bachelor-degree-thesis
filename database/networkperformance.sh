#!/bin/bash

# http://dev.chromium.org/spdy/spdy-whitepaper
# http://stephendnicholas.com/posts/power-profiling-mqtt-vs-https

gnuplot > networkperformance.png <<EOF
#!/usr/bin/gnuplot
reset
set terminal png size 400,800

set key at graph 1, 1 horizontal samplen 0.1
set auto x
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9
set xtic rotate by 90 scale 0
#set title "MQTT vs HTTP comparison"
set ytics rotate
set y2tics rotate
set ylabel "% battery discharge per hour"
set y2label "messages / hour"
set xtics nomirror rotate scale 0
set key outside

plot "networkperformance.dat" \
       using 2:xtic(1)title "% Discharge per hour (Wi-Fi)", \
    "" using 3 title "% Discharge per hour (3G)", \
    "" using 4 title "Messages per hour (Wi-Fi)" axes x1y2, \
    "" using 5 title "Messages per hour (3G)" axes x1y2

EOF
