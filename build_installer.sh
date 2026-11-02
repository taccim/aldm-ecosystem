#!/usr/bin/env bash
##------------------------------------------------------------------------------------------## 
# PROGRAM: build_installer.sh                                                                #
# $Id: build_installer.sh,v 1.44 2025/02/05 00:10:37 mtacci Exp $
# AUTHOR: mtacci@us.ibm.com                                                                  #
# Copyright © IBM Corp. 2018, 2019. All Rights Reserved                                      #
#                                                                                            #
# The source code for this program is not published or                                       #
# otherwise divested of its trade secrets, irrespective of                                   #
# what has been deposited with the U.S. Copyright Office.                                    #
#                                                                                            #
##------------------------------------------------------------------------------------------## 

##user environment

ECOBASEDIR="/home/mtacci/ALDM/CODE_build/ALDM2.0"
BASEDIR="$ECOBASEDIR/aldm-ecosystem"
SCRIPT="instance_install.sh"
RPMSCRIPT="rpm_dependencies.sh"

RUNSCRIPTSDIR="$BASEDIR/aldm-scripts"
RUNSCRIPTS="aldm-start.sh deploy-config.sh"
SQLSCRIPTSDIR="$ECOBASEDIR/aldm-pipeline/MYSQL"
SQLSCRIPTS="dbpurge.sh"

DCEBASEDIR="$ECOBASEDIR/aldm"
DCERUNSCRIPTSDIR="$DCEBASEDIR/dce-scripts"
DCERUNSCRIPTS="dce-start.sh dce-container-versions.sh dce-generate-reports.sh dce-nuke-all.sh dce-process-data.sh dce-reset-data.sh dce-stop.sh dce-uninstall.sh"

ALDM_DECODE_NAMES="PIPELINE2 DERBY PORTAL BROWSER"
ALDM_IMAGE_NAMES="aldm-pipeline derby aldm-portal browser"
ALDM_SRC_NAMES="aldm-pipeline aldm-derby aldm-webportal aldm-browser"

DCE_DECODE_NAMES="PIPELINE GRAPHQL WEBAPP REDIS"
DCE_IMAGE_NAMES="dce-pipeline dce-graphql dce-webapp redis"
DCE_SRC_NAMES="dce-pipeline dce-graphql-server dce-app-web redis"

MOVE=mv

### ******************************  DO NOT EDIT BELOW THIS LINE ***********************************####

## ENV
HERE=$(pwd)
PKG=$1; : ${PKG:="aldm"}
RPM=$2
NOARCHIVE=$3
hash uuencode|alias uuencode=base64

#OS Derivation
 OSRELEASEFILE="/etc/os-release"
 source $OSRELEASEFILE
 for w in ID VERSION_ID; do
    x=$(printf "$%s" ${w})
    eval $w=$x
 done
 unset VERSION
 major=${VERSION_ID%.*}; minor=${VERSION_ID#*.*}

#docker switch
 if [ $major -eq 7 ];then
        DOCKER=docker
        DOCKERDIR=/var/lib/docker
        DOCKERSOCKET=/var/run/docker.socket
 elif [ $major -eq 8 ] || [ $major -eq 22 ] ;then
        DOCKER=podman
        DOCKERDIR=/var/lib/containers/storage
        DOCKERSOCKET=/run/podman/podman.sock
 fi
DOCKERROOTDIR=$DOCKERDIR
DOCKERPKGDIR="${DOCKERDIR}/$PKG"

BUILDSCRIPT="install-${PKG}-offORonline.sh"
[ $(id -un) == "root" ] || SUDO=sudo
[ "$RPM" = "UPDATE" ] && UPDATE=true && RPM=""
[ "$RPM" = "TAG" ] && TAG="$3" && NOARCHIVE=$4 && RPM=""
[ "$RPM" = "COPY" ] && MOVE=cp && RPM=""

## SUBS
use_rpms(){
printf  "Use existing dependencies bundle? [Y|n]:"; read ans
if [ -z "$ans" ] || [ "$ans" = "Y" ]; then
  #[ -f RPMS/dependencies-${PKG}.tgz ]  && cp RPMS/dependencies-${PKG}.tgz dependencies.tgz
  if  [ -f dependencies.tgz ] ; then
     printf  "expand the local file [y|N]:"; read ans
     [ -z "$ans" ] || [ "$ans" = "N" ] || tar --directory=/tmp -xzf dependencies.tgz
  else
     return 1
  fi
else
  return 2
fi
return
}

get_rpms(){
#get  major 7 rpms
> /tmp/t.lst
r=0; q=0 t="$(echo $RPMLISTM7|awk '{print NF}')"
for n in $RPMLISTM7; do
 p=$(echo $n|sed -e 's/\(^[a-zA-Z2-9.\-]*\)\-[0-9].*/\1/')
 ((r++))
 printf " %d" $r
 if [ -f /tmp/rpms/7/${n}.rpm ];then
	 echo rpms/7/${n}.rpm >> /tmp/t.lst
 else
  #[ -f /tmp/r.lst ] || ./$RPMSCRIPT rhel fetch 
  ((r--))
  ((q++))
  #printf "+$p "; #((q++))
  #yum list installed $p >/dev/null 2>&1 && re=re 
  #$SUDO yum ${re}install -y --enablerepo=epel --quiet --downloadonly --downloaddir=/tmp/rpms $n 2>/dev/null
 fi
done; echo " of $t rhel7 rpms" 
T=$t
#get  major 8 rpms
r=0; t="$(echo $RPMLISTM8|awk '{print NF}')"
T=`expr $T + $t`
for n in $RPMLISTM8; do
 p=$(echo $n|sed -e 's/\(^[a-zA-Z2-9.\-]*\)\-[0-9].*/\1/')
 ((r++))
 printf " %d" $r
 if [ -f /tmp/rpms/8/${n}.rpm ];then
	 echo rpms/8/${n}.rpm >> /tmp/t.lst
 else
  ((r--))
  ((q++))
 fi
done; echo " of $t rhel8 rpms and $T total" 
[ $q -gt 0 ] && [ $q -lt $r ] || [ -n "$RPM" ] || [ ! -f dependencies.tgz ] &&\
  tar -cvzf dependencies.tgz -C /tmp -T /tmp/t.lst #&& git add dependencies.tgz 
}

get_version () {
 IDVERSION="$(awk ' $2 ~ /Id:/ {print $4}' instance_install.sh)"
 if [ -f VERSION ] ; then
  VERSION=$(cat VERSION)
 else
   GIT_SHA=$(git log --pretty=format:'%H' HEAD^..HEAD)
   GIT_REF=$(git symbolic-ref HEAD 2>/dev/null)
   GIT_BRANCH="${GIT_REF#refs/heads/}"
   VERSION="${GIT_BRANCH}"
   [[ -z $(git status -s|grep '^ .') ]] || VERSION="$VERSION, dirty"
   [[ -z $(git cherry -v @{upstream}) ]] || VERSION="${VERSION}, with unpushed"
   VERSION="${VERSION} (${GIT_SHA:0:7})"
 fi
 printf "${GIT_SHA}" > GIT_SHA
 printf "%s" "${VERSION}" > VERSION
 echo "$VERSION Version:$IDVERSION" #return string
}

mk_scripts () {
if [ "$1" == "aldm" ]; then 
 [ -d system ] || mkdir -p system
 [ -d mysql ] || mkdir -p mysql
 #tar -cf aldm-scripts.tar -C $RUNSCRIPTSDIR $RUNSCRIPTS
 #tar -uf aldm-scripts.tar -C $BASEDIR $RPMSCRIPT #VERSION
 #tar -uf aldm-scripts.tar -C $SQLSCRIPTSDIR $SQLSCRIPTS
 for n in $RUNSCRIPTS; do cp $RUNSCRIPTSDIR/$n system/$n; done
 for n in $RPMSCRIPT; do cp $BASEDIR/$n system/$n; done
 for n in $SQLSCRIPTS; do cp $SQLSCRIPTSDIR/$n mysql/$n; done
 tar -cf aldm-scripts.tar system mysql #VERSION
 rm -fr system mysql
 gzip aldm-scripts.tar && mv aldm-scripts.tar.gz aldm-scripts.tgz && echo "aldm-scripts.tgz created."
elif [ "$1" == "dce" ]; then 
 tar -cf dce-scripts.tar -C $DCERUNSCRIPTSDIR $DCERUNSCRIPTS
 gzip dce-scripts.tar && mv dce-scripts.tar.gz dce-scripts.tgz && echo "dce-scripts.tgz created."
fi
}


### MAIN ### 

if [ "$PKG" == "aldm" ]; then
  DECODE_NAMES="MARIADB $ALDM_DECODE_NAMES"
  IMAGE_NAMES="mariadb $ALDM_IMAGE_NAMES"
  SRC_NAMES="mariadb $ALDM_SRC_NAMES"
elif [ "$PKG" == "dce" ]; then
  DECODE_NAMES="MARIADB $DCE_DECODE_NAMES"
  IMAGE_NAMES="mariadb $DCE_IMAGE_NAMES"
  SRC_NAMES="mariadb $DCE_SRC_NAMES"
elif [ "$PKG" == "prod" ]; then
  DECODE_NAMES="MARIADB $ALDM_DECODE_NAMES $DCE_DECODE_NAMES"
  IMAGE_NAMES="mariadb $ALDM_IMAGE_NAMES $DCE_IMAGE_NAMES"
  SRC_NAMES="mariadb $ALDM_SRC_NAMES $DCE_SRC_NAMES"
elif [ "$PKG" == "scripts" ]; then
 mk_scripts aldm && $SUDO $MOVE aldm-scripts.tgz ${DOCKERROOTDIR}/aldm/aldm-scripts.tgz 
 mk_scripts dce  && $SUDO $MOVE dce-scripts.tgz ${DOCKERROOTDIR}/dce/dce-scripts.tgz
 exit 
elif [ "$PKG" == "help" ]; then
	cat -<<EOH
 USAGE: $(basename $0) aldm|dce|scripts|help [UPDATE|TAG Tagname]
                           prod|devel RPM

				aldm - create aldm installer
				dce  - create dce installer
				scripts  - repackage aldm + dce scripts archive
				help  - this help file

				UPDATE - Use with Caution!!  Updates local OS and repolist
				TAG - Tag the build version

                           	prod|devel RPM - creates dependencies tarball for prod or devel
EOH
elif [ "$PKG" != "devel" ]; then
  echo "non supported package type: $PKG"
  exit 1
fi

if [ -z "$RPM" ]; then
$SUDO [ -f $BASEDIR/$SCRIPT ]  && $SUDO [ -d $DOCKERPKGDIR ] || exit 2

##archive existing script
if [ -f $BASEDIR/$BUILDSCRIPT ]; then
 OVERSION=$VERSION
 eval `grep Version= install-aldm-offORonline.sh` 
 av="_`echo $Version|sed -e 's/ /_/g'`"
 VERSION=$OVERSION
 if [ ! -f ../aldm-distribution/INSTALLERS/ARCHIVE/${BUILDSCRIPT}$av ] && [ -z "$NOARCHIVE" ] ;then
  printf "archiving $PKG installer to ../aldm-distribution/INSTALLERS/ARCHIVE/${BUILDSCRIPT}${av}.gz ... "
  [ -f ../aldm-distribution/INSTALLERS/ARCHIVE/${BUILDSCRIPT}${av}.gz ] ||\
  cp -fp $BASEDIR/$BUILDSCRIPT ../aldm-distribution/INSTALLERS/ARCHIVE/${BUILDSCRIPT}$av &&\
   gzip "../aldm-distribution/INSTALLERS/ARCHIVE/${BUILDSCRIPT}$av" 
  printf "done\n"
 fi
else
 echo "Warning: $BASEDIR/$BUILDSCRIPT does not exist"
fi

## concatenate 
mstart=$(grep -n  '^### MAIN ###' $BASEDIR/$SCRIPT|cut -d: -f1)
mstart=$(expr $mstart - 1)
len=$(wc -l $BASEDIR/$SCRIPT |awk '{print $1}')
mend=$(expr $len - $mstart)
versionstr="Version='$(get_version)'" ; echo "$versionstr" ;read junk
printf  "Save Version info to local build machine? [Y|n]:"; read ans
[ -z "$ans" ] || [ "$ans" = "Y" ] && $SUDO sh -c "echo $versionstr > /opt/IBM/ALDM/$(echo ${PKG}| tr 'a-z' 'A-Z')VERSION "

head -$mstart $BASEDIR/$SCRIPT |sed -e 's|^IBM=1|IBM=0|' -e "s|^Version=[^#]*|$versionstr |" -e "s|\(^TAG=\)[^#]*|\1$TAG |" > $BASEDIR/$BUILDSCRIPT
cat $BASEDIR/$RPMSCRIPT >> $BASEDIR/$BUILDSCRIPT
tail -$mend   $BASEDIR/$SCRIPT >> $BASEDIR/$BUILDSCRIPT
cat -<< EOC  >> $BASEDIR/$BUILDSCRIPT
## -------------------- attach encoding here ---------------------- ###
EOC

##create log
echo $versionstr >installer_build.log
grep '^# $Id:' instance_install.sh rpm_dependencies.sh >>installer_build.log
chmod 666 installer_build.log


##mk scripts bundle
mk_scripts aldm
uuencode aldm-scripts.tgz ${DOCKERROOTDIR}/aldm/aldm-scripts.tgz > aldm-scripts.uu 
if [ "$PKG" == "dce" ]; then
 mk_scripts dce
 uuencode dce-scripts.tgz ${DOCKERPKGDIR}/dce-scripts.tgz > dce-scripts.uu 
fi
#cksum aldm-scripts.tgz >> installer_build.log

##root only from here in 
if [ ! "$(id -un)" == "root" ]; then
 echo "you will need to elevate your privs to  root"
 $SUDO echo "thanks"
fi
fi #RPM test



if [ "$UPDATE" = "true" ]; then
 if [ $major -eq 7 ] ;then 
   if ! (yum list installed epel-release >/dev/null 2>&1 && yum repolist epel|grep -q epel) ;then
       rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
       $SUDO yum update
       $SUDO yum info epel-release
   fi
 elif [ $major -eq 8 ] ;then 
       $SUDO dnf update
 fi
fi

## dependncies 5 step sequence
## 1. get rpm list 
[ -d /tmp/rpms/$major ] || mkdir -p /tmp/rpms/$major
[ "$RPM" == "RPM" ] && [ "$PKG" == "prod" ] 
if [ -x $BASEDIR/rpm_dependencies.sh ]; then 
    RPMLISTM7=$($BASEDIR/rpm_dependencies.sh list $PKG 7)
    RPMLISTM8=$($BASEDIR/rpm_dependencies.sh list $PKG 8)
else
    RPMLISTM7=$(gen_rpm_dependencies $PKG 7)
    RPMLISTM8=$(gen_rpm_dependencies $PKG 8)
fi

## 2. get rpms
use_rpms || get_rpms 
[ -f dependencies.tgz ] || exit 1
cp dependencies.tgz RPMS/dependencies-${PKG}.tgz	
[ -n "$RPM" ] && ls -l RPMS/dependencies-${PKG}.tgz

## 3. mk dependencies bundle
# how to add padding: #echo "$str"==== | fold -w 4 | sed '$ d' | tr -d '\n' | base64 --decode
base64 dependencies.tgz  > dependencies.base64 
ls -l dependencies.base64
[ -z "$RPM" ] || exit

## 4. take a local copy 
echo -n "Would you like to locally update ${DOCKERROOTDIR}/aldm/dependencies.tgz ? [Y|n]" ;read ans
[ -z "$ans" ] &&  [ "$1" != "devel" ] && $SUDO cp dependencies.tgz $DOCKERROOTDIR/aldm &&\
[ -n "$RPM" ] && ls -l $DOCKERROOTDIR/aldm/dependencies.tgz

## 5. add encoded later (last)

##add uuencoded data to buildscript and apply their cksums
printf "\rAdding aldm-scripts                                                " 
echo "ALDM-SCRIPTS:" >> $BASEDIR/$BUILDSCRIPT
cat aldm-scripts.uu >> $BASEDIR/$BUILDSCRIPT
rm -f aldm-scripts.uu

if [ "$PKG" == "dce" ]; then
 printf "\rAdding dce-scripts                                                 " 
 echo "DCE-SCRIPTS:" >> $BASEDIR/$BUILDSCRIPT
 cat dce-scripts.uu >> $BASEDIR/$BUILDSCRIPT
 rm -f dce-scripts.uu
fi

echo "CKSUM SIZE FILE DATE "  >> installer_build.log
for n in instance_install.sh rpm_dependencies.sh ${DOCKERPKGDIR}/${PKG}-scripts.tgz  $DOCKERROOTDIR/aldm/aldm-scripts.tgz ;do
        CKSUMSTR=$( $SUDO cksum  $n|sed -e "s,${DOCKERPKGDIR}/,,")
        CKSUMDATE=$( $SUDO  ls -l $n |awk '{print $6,$7,$8}')
        echo $CKSUMSTR $CKSUMDATE >> installer_build.log
done

#finish scripts
$SUDO cp ${PKG}-scripts.tgz dependencies.tgz ${DOCKERPKGDIR}/
$SUDO cp aldm-scripts.tgz $DOCKERROOTDIR/aldm
[ -f aldm-scripts.tgz ] && cp -f aldm-scripts.tgz SCRIPTS/ENGINE
[ -f dce-scripts.tgz ] && cp -f dce-scripts.tgz SCRIPTS/ENGINE




##add the images and apply their chksums
declare -a D=(${DECODE_NAMES})
declare -a I=(${IMAGE_NAMES})
declare -a S=(${SRC_NAMES})
nlimit=$(echo $DECODE_NAMES|awk '{print NF}')

for (( n=0; n<${nlimit}; n++ ));do
	sleep .5; printf "\rAdding ${I[$n]}-image                                                                               " 
	echo "${D[$n]}-DOCKER-IMAGE:" >> $BASEDIR/$BUILDSCRIPT
        if $SUDO [ ! -f ${DOCKERPKGDIR}/${I[$n]}-image.xz ]; then
                sleep .5; printf  "\r Warn: ${DOCKERPKGDIR}/${I[$n]}-image.xz not found                                        "
       		if $SUDO [ -f ${DOCKERPKGDIR}/${I[$n]}-image ] ;then
                        sleep 1; printf  "\r Packing ${DOCKERPKGDIR}/${I[$n]}-image                                           "
			$SUDO	xz -9 ${DOCKERPKGDIR}/${I[$n]}-image
		else
                	continue
		fi
        fi
	$SUDO [ -f ${DOCKERPKGDIR}/${I[$n]}-image.uu ] && printf  "\rWarn: ${DOCKERPKGDIR}/${I[$n]}-image.uu exists                             "
        $SUDO sh -c "uuencode ${DOCKERPKGDIR}/${I[$n]}-image.xz ${DOCKERPKGDIR}/${I[$n]}-image.xz > ${DOCKERPKGDIR}/${I[$n]}-image.uu"
        $SUDO sh -c "cat ${DOCKERPKGDIR}/${I[$n]}-image.uu >> $BASEDIR/$BUILDSCRIPT"
        $SUDO rm ${DOCKERPKGDIR}/${I[$n]}-image.uu 
        CKSUMSTR=$( $SUDO cksum  ${DOCKERPKGDIR}/${I[$n]}-image.xz|sed -e "s,${DOCKERPKGDIR}/,,")
        CKSUMDATE=$( $SUDO  ls -l ${DOCKERPKGDIR}/${I[$n]}-image.xz |awk '{print $6,$7,$8}')
        MYVERSION=$(cat $ECOBASEDIR/${S[$n]}/VERSION 2>/dev/null)
        echo $CKSUMSTR $CKSUMDATE $MYVERSION >> installer_build.log
done

##add the dependencies and apply their chksums
# dependeciesmust be last due to base64 encoding
printf "\rAdding dependencies                                                  " 
echo "DEPENDENCIES:" >> $BASEDIR/$BUILDSCRIPT
cat dependencies.base64 >> $BASEDIR/$BUILDSCRIPT
#rm th rm #debug
#rm -f dependencies.base64
for n in ${DOCKERPKGDIR}/dependencies.tgz ;do
        CKSUMSTR=$( $SUDO cksum  $n|sed -e "s,${DOCKERPKGDIR}/,,")
        CKSUMDATE=$( $SUDO  ls -l $n |awk '{print $6,$7,$8}')
        echo $CKSUMSTR $CKSUMDATE >> installer_build.log
done
printf "\n done with script  $BASEDIR/$BUILDSCRIPT \n"

#apply chksum of the installer script
BUILDSCRIPTLINK=$(ls -l $BUILDSCRIPT |awk '{print $NF}')
CKSUMSTR=$(cksum  $BUILDSCRIPT)
CKSUMDATE=$(ls -l $BUILDSCRIPTLINK |awk '{print $6,$7,$8}')
echo $CKSUMSTR $CKSUMDATE >> installer_build.log


## +x and show
chmod 755  $BASEDIR/$BUILDSCRIPT
printf "INDEX:IMAGENAME:LENGTH\n"
grep -n '\(SCRIPTS\|IMAGE\|DEPENDENCIES\):$' $BASEDIR/$BUILDSCRIPT >/tmp/sid.lst 
awk -F: '{ if (NR>1) {printf("%d\n",$1-i)}; printf("%d:%s:",$1,$2); i=$1; if (NR==c) {printf("%d\n",l-i)}; }' \
        	c=$(wc -l /tmp/sid.lst |cut -d" " -f1) l=$(wc -l $BASEDIR/$BUILDSCRIPT |cut -d" " -f1) /tmp/sid.lst
rm -f /tmp/sid.lst



## complete log
#printf  "\n--- installer_build.log ---\n" >> installer_build.log  ; git hist installer_build.log >> installer_build.log
printf  "\n--- instance_install.sh ---\n " >> installer_build.log  ; git hist instance_install.sh  >> installer_build.log
printf  "\n--- rpm_dependencies.sh  ---\n " >> installer_build.log  ; git hist rpm_dependencies.sh  >> installer_build.log
printf "\n done! $(date) \n" >> installer_build.log
#git add installer_build.log; git commit -m "new build done $(date)"

## copy the log and the base scripts
echo "copying log and base scripts to ../aldm-distribution/INSTALLERS"
cp instance_install.sh  rpm_dependencies.sh ../aldm-distribution/INSTALLERS
#cp installer_build.log ../aldm-distribution/INSTALLERS/BOX

#clean up
#rm -f GIT_SHA VERSION aldm-scripts.tgz dce-scripts.tgz #dependencies.tgz  ##keep the depend bundle instead of rebuilding everytime
rm -f aldm-scripts.tgz dce-scripts.tgz #dependencies.tgz  ##keep the depend bundle instead of rebuilding everytime,and keep the stamped version until new one arrives


## end -mt 2019
