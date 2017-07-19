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
select avg(a.alivetime), avg(a.totaltime), avg(a.totaltime) - avg(a.alivetime) from
(select min(\`on\`), max(\`off\`), SUM(\`alivetime\`) as alivetime,
UNIX_TIMESTAMP(max(\`off\`)) - UNIX_TIMESTAMP(min(\`on\`)) as totaltime
from devlog where deviceid='${DEVICEID}'
and off > '0000-00-00 00:00:00'
and date(\`on\`) = date(\`off\`)
group by date(\`on\`)) as a
EOF

# Array values: ACTIVE TIME (avg), TOTAL TIME (avg), MOVE TIME (avg)
RIS=($(echo "$QUERY" | mysql -N -B -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB | tr '\t' ' '))
BLACK=$(echo "86400 - ${RIS[1]}" | bc)
echo "Context-based ${RIS[0]} ${RIS[2]} ${BLACK}" > /tmp/usageplot.dat
echo "Basic  ${RIS[1]} 0 ${BLACK}" >> /tmp/usageplot.dat
#echo "Total time: ${RIS[1]}"
#echo "Alive time: ${RIS[0]}"

gnuplot <<EOF
#!/usr/bin/gnuplot
reset
set terminal png size 800,400

set ylabel "Time spent"
set yrange [0:86400]

set title "CPU and sensor activity (device ${DEVICEID})"
set key invert reverse Left outside
unset ytics
set grid y
set border 3
set style data histograms
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.75

plot "/tmp/usageplot.dat" using 2:xtic(1) title "Active usage" linecolor rgbcolor "#FF5555", \
	"/tmp/usageplot.dat" using 3:xtic(1) title "Sleep/inactive" linecolor rgbcolor "#4444DD", \
	"/tmp/usageplot.dat" using 4:xtic(1) title "Phone off" linecolor rgbcolor "#666666",

EOF

#rm /tmp/usageplot.dat
