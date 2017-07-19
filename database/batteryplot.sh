#!/bin/bash

errmsg() {
	(>&2 echo $1)
}

printusage() {
	echo "$0 dbhost dbuser dbpass dbname"
	exit 255
}

DEVICEID=40F30880A7F4
MYSQL_HOST=$1
MYSQL_USER=$2
MYSQL_PASS=$3
MYSQL_DB=$4

if [ "$MYSQL_HOST" == "" ] || [ "$MYSQL_USER" == "" ] || [ "$MYSQL_PASS" == "" ] || [ "$MYSQL_DB" == "" ]; then
	errmsg "Wrong/missing database parameters"
	printusage
fi

read -r -d '' QUERY <<EOF
select TIME_FORMAT(TIME(\`on\`), '%H:%i') as start, TIME_FORMAT(TIME(\`off\`), '%H:%i') as end, batteryon, batteryoff
from devlog where deviceid='${DEVICEID}'
and off > '0000-00-00 00:00:00'
and batteryon > batteryoff
having start < end
ORDER by start, end
EOF

echo "$QUERY" | mysql -N -B -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB | gawk -F'\t' '
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

{
	TCUR=timetosec($1)
	TEND=timetosec($2)
	if (TCUR < TEND && $4 != $3) {
		RATIO=($3 - $4)/(TEND - TCUR)
		CURCHARGE=$3
		while (TCUR != TEND) {
			print sectotime(TCUR), CURCHARGE
			TCUR = TCUR + 1
			CURCHARGE = CURCHARGE - RATIO
			if (CURCHARGE < 0) {
				CURCHARGE = 0
			}
		}
	}
}' | sort | gawk -F' ' '
BEGIN {
	LASTITEM=""
	ACC=0
	CNT=0
}

{
	if (LASTITEM == "") {
		LASTITEM = $1
		ACC = $2
		CNT = 1
	} else if (LASTITEM == $1) {
		ACC = ACC + $2
		CNT = CNT + 1
	} else {
		print LASTITEM, (ACC / CNT)
		LASTITEM = $1
		ACC = $2
		CNT = 1
	}
}
' > /tmp/batteryplot.dat

gnuplot <<EOF
#!/usr/bin/gnuplot
reset
set terminal png size 800,400

set xdata time
set timefmt "%H:%M:%S"
set format x "%H:%M"
set xlabel "time"

set ylabel "battery charge"
set yrange [0:100]

set title "Battery charge per time (device ${DEVICEID})"
set key reverse Left outside
set grid

set style data lines

plot "/tmp/batteryplot.dat" using 1:2 title "Discharge-curve alg", \
	"batteryplot_nofollow.dat" using 1:2 title "Context-based alg", \
	"batteryplot_orig.dat" using 1:2 title "Basic"

EOF

rm /tmp/batteryplot.dat
