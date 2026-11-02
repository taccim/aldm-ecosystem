#!/bin/bash
what=$1
ver=$2
minor=$3  #4.6 or 46
: ${what:="aldm"}

if [ -n "$ver" ];then
  ./rpm_dependencies.sh list ${what} $ver  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/8/,' |grep '\.rpm$' > /tmp/t.lst

elif [ "$1" == "both" ];then 
  ./rpm_dependencies.sh list aldm 8  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/8/,' |grep '\.rpm$' > /tmp/t1.lst
  ./rpm_dependencies.sh list aldm 7  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/7/,' |grep '\.rpm$' >> /tmp/t1.lst
  ./rpm_dependencies.sh list dce 8  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/8/,' |grep '\.rpm$' > /tmp/t2.lst
  ./rpm_dependencies.sh list dce 7  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/7/,' |grep '\.rpm$' >> /tmp/t2.lst
   cat /tmp/t1.lst /tmp/t2.lst |sort -u > /tmp/t.lst
else
  ./rpm_dependencies.sh list ${what} 8 $minor |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/8/,' |grep '\.rpm$' > /tmp/t.lst
  [ "$1" != "devel" ] &&\
  ./rpm_dependencies.sh list ${what} 7  |\
	  sed -e 's/$/ /' -e 's/ /.rpm /g' -e 'y/ /\n/'  |\
	  sort -u |sed -e 's,^,rpms/7/,' |grep '\.rpm$' >> /tmp/t.lst
fi

#grep -v '\.rpm' /tmp/t.lst

tar -cvzf RPMS/dependencies-${what}${ver}.tgz -C /tmp -T /tmp/t.lst
[ "$1" == "both" ] && cp RPMS/dependencies-${what}${ver}.tgz  dependencies.tgz
