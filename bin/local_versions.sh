#!/bin/bash
#$Id: $

[ "$(basename $PWD)" == "aldm-ecosystem" ] && [ $(id -u) -eq 0 ]  || exit 1

PKG=$1


TMPFILE=/tmp/v.txt
OUTFILE=../aldm-distribution/VERSION.log
cat $OUTFILE > ${TMPFILE}.1

printf "%s\n" "----- ${PKG:="aldm"} Ecosystem Version Information as of: $(date '+%x %X') -----" > $TMPFILE || exit 2
( cksum install-${PKG}-offORonline.sh ;ls -l ../aldm-distribution/INSTALLERS/BOX/install-${PKG}-offORonline.sh) |\
   awk '{if (NR==1) {a=$1;b=$2;n=$3;printf("NAME\t\t\t\tCKSUM\t\tSIZE\t\tDATE\n") } else { printf("%s\t%d\t%d\t%s_%s_%s\n", n,a,b,$6,$7,$8)}} ' >> $TMPFILE
printf "%s\n" "# ./install-${PKG}-offORonline.sh -version" >> $TMPFILE
 ./install-${PKG}-offORonline.sh -version >> $TMPFILE

UPKG=$(echo $PKG|tr '[a-z]' '[A-Z]')
printf "\n%s\n" "# /opt/IBM/ALDM/system/aldm-version.sh $UPKG" >> $TMPFILE
/opt/IBM/ALDM/system/aldm-version.sh $UPKG >> $TMPFILE

printf "\n" >> $TMPFILE
cat $TMPFILE ${TMPFILE}.1 > $OUTFILE
## end (mt)
