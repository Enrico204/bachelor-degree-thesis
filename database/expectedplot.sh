#!/bin/bash

gawk '
function timepad(t) {
	if (length(t) == 1) {
		return "0" t
	} else {
		return t
	}
}
function timetosec(t) {
	split(t, td, ":")
	return td[1]*60 + td[2]
}
function sectotime(t) {
	minutes = t % 60
	hour = ((t - minutes) / 60) % 24
	return timepad(hour) ":" timepad(minutes)
}

BEGIN {
	LAST=0
	LASTTS=0
	TCUR=timetosec("8:00")
	TEND=timetosec("20:00")
	if (TCUR < TEND) {
		RATIO=0.118
		CURCHARGE=100
		while (TCUR != TEND) {
			if (LASTTS == 0) {
				LASTTS=int(rand()*60)
				LAST=(rand()*5)*(int(rand()*10)%2==0?-1:1)
			}
            NEWVAL=CURCHARGE + 2*rand()*(int(rand()*10)%5 == 0 ? 1 : 0)*(int(rand()*10)%2 == 0 ? -1 : 1) + LAST
			print sectotime(TCUR), (NEWVAL < CURCHARGE ? CURCHARGE : NEWVAL)
			LASTTS = LASTTS - 1
			TCUR = TCUR + 1
			if (CURCHARGE - RATIO < 15) {
				RATIO=0.01
				LASTTS=-1
				LAST=0
			}
			CURCHARGE = CURCHARGE - RATIO
			if (CURCHARGE < 0) {
				CURCHARGE = 0
			}
		}
	}
}' > /tmp/expectedplot.dat

gnuplot <<EOF
#!/usr/bin/gnuplot
reset
set terminal png size 800,400

set xdata time
set timefmt "%H:%M:%S"
set format x "%H"
set xlabel "hour"

set ylabel "battery charge"
set yrange [0:100]

set title "Expected battery charge per time"
set key reverse Left outside
set grid

set style data lines

plot "expectedplot.dat" using 1:2 title "Discharge threshold" linecolor rgb "red", \
    "/tmp/expectedplot.dat" using 1:2 title "Expected discharge"

EOF

rm /tmp/expectedplot.dat
