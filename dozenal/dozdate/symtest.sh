#!/bin/bash

./dozdate -d"10 Apr 1187"
echo -e "Sat 11 Apr 1187 (projected)\n`./dozdate -sd"10 Apr 1187"`"
echo ""

./dozdate -d"25 Dec 1191"
echo -e "Tue 02 Irv 1191 (projected)\n`./dozdate -sd"25 Dec 1191"`"
echo ""

./dozdate -d"3 Jan 1192"
echo -e "Sat 07 Irv 1191 (projected)\n`./dozdate -sd"3 Jan 1192"`"
echo ""

./dozdate -d"4 Jan 1192"
echo -e "Sat 01 Jan 1192 (projected)\n`./dozdate -sd"4 Jan 1192"`"
echo ""

./dozdate -d"25 Dec 1191" "%b"
echo -e "Irv (projected)\n`./dozdate -sd"25 Dec 1191" "%b"`"
echo ""

./dozdate -d"25 Jan 1190" "%B"
./dozdate -sd"25 Jan 1190" "%B"
./dozdate -sd"25 Dec 1191" "%B"
