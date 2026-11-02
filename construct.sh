#!/usr/bin/env bash
# set -x
##----------------------------------------------------------------------------------------------------------##
#@(#) $Id: construct.sh,v 1.67 2025/02/02 17:47:31 mtacci Exp $
#@(#) Description: shell script                                                                             ##
#@(#) Author: mtacci 
#@(#) Copyright: Property of IBM, Copyright (c) 2017-2019 IBM Corporation, Armonk, NY. All Rights Reserved. ##
#@(#)           Use of this material without the express consent of IBM or assignees is unlawful            ##
#@(#)           and subject to prosecution to the fullest extent of the law.                                ##
##----------------------------------------------------------------------------------------------------------##

#### ENV  DEBUG
ECHO=echo #debug


### **** DO NOT EDIT BELOW THIS LINE **** ###

### GLOBAL VARIABLES

SCRIPT_VERSION='$Revision: 1.67 $'
SCRIPT_DATE='$Date: 2025/02/02 17:47:31 $'

set -e
UXID=$(id -un)
CURRENT_PATH=$(pwd)
SCRIPT_PATH=$(cd $(dirname $0) ; pwd -P )
VALID_CONTAINERS="dce-pipeline dce-graphql dce-webapp"
VALID_CONTAINERS="$VALID_CONTAINERS aldm-ui aldm-api aldm-help"
VALID_CONTAINERS="$VALID_CONTAINERS aldm-webportal aldm-webui aldm-pipeline aldm-postgres"
VALID_CONTAINERS="$VALID_CONTAINERS mariadb derby redis db2server"
VALID_CONTAINERS="$VALID_CONTAINERS browser "
VALID_CONTAINERS="$VALID_CONTAINERS nginx "
VALID_CONTAINERS="$VALID_CONTAINERS aldm-itrix "
VALID_ALIAS_CONTAINERS="aldm-derby aldm-browser aldm-db2"
VALID_BASE_IMAGES="aldm-pipeline-base aldm-pipeline-base:perl dce-webapp-base aldm-webportal-base aldm-portal-base aldm-webui-base db2server-base aldm-db2-base"
VALID_CLONES="aldm-ecosystem aldm-scripts aldm-distribution aldm-collectors dce-scripts aldm-ansible dce aldm-documentation"
##-add clones to list
VALID_BUILDS="$VALID_CONTAINERS $VALID_ALIAS_CONTAINERS $VALID_BASE_IMAGES $VALID_CLONES"
#DEPENDENCIES="docker-ce containerd.io yarn npm java-1.8.0-openjdk git perl python"
CHKDEP=0

: ${MARIADBVER:="10.4"}  ##change to 10.4 for DCE ^


## allow for additional image build options
## https://docs.docker.com/engine/reference/commandline/image_build/
## WARNING: spme options are exprimental, must ebale daemon to support them.
##          https://github.com/docker/docker-ce/blob/master/components/cli/experimental/README.md

IMAGEBUILDOPTS="$IMAGEBUILDOPTS --no-cache --force-rm"

UNAME=$(uname -s)
#OS Derivation
major=0
if [ "$UNAME" == "Linux" ]; then
 OSRELEASEFILE="/etc/os-release"
 source $OSRELEASEFILE
 for w in ID VERSION_ID; do
    x=$(printf "$%s" ${w})
    eval $w=$x
 done
 major=${VERSION_ID%.*}; minor=${VERSION_ID#*.*}
fi

#OS/docker/app switch
 if [ $major -eq 7 ];then
        DOCKER=docker
        DOCKERDIR=/var/lib/docker
        DOCKERSOCKET=/var/run/docker.socket
	DOCKERPING="http://ping"
        DEPENDENCIES="docker-ce containerd.io java-1.8.0-openjdk git perl python"
	#Node.js 13.0.1 		2019-10-23 	7.8.279.17 	6.12.0 	79
	NPMV="6.12.0"
	NODEV="v13.0.1"
	YARNV="1.22.4"

 elif [ $major -ge 8 ];then
        DOCKER=podman
        DOCKERDIR=/var/lib/containers/storage
        DOCKERSOCKET=/run/podman/podman.sock
	DOCKERPING="http://d/_ping"
        DEPENDENCIES="podman containers-common java-1.8.0-openjdk git perl python2"
	## 12/2021
	NPMV="6.14.11"
	NODEV="v13.14.0"
	YARNV="1.22.17"
 fi
 
#PATH
alias npm='/usr/local/bin/npm'
alias node='/usr/local/bin/node'
alias yarn='/usr/local/bin/yarn'

#### ARGS 
container=$1
action=$2
option=$3
option2=$4

#### SUBS


chk_name (){
name=$1
for n in $VALID_BUILDS; do
 [ "$n" == "$name" ] && return 
done
[ "$name" == "help"  ] && return 1
return 2
}

chk_dependencies_ver(){
NPMME=""; NODEME=""; YARNVME="" 
hash npm 2>/dev/null && NPMME=$(npm -v); 
hash node 2>/dev/null && NODEME=$(node --version); 
hash yarn 2>/dev/null && YARNVME=$(yarn --version) 
[ "${NPMV%*.*}" == "${NPMME%*.*}" ]  || printf " NPM version $NPMME IS NOT $NPMV !! " 
[ "${NODEV%*.*}" == "${NODEME%*.*}" ]  || printf " NODE version $NODEME IS NOT $NODEV !! " 
[ "${YARNV%*.*}" == "${YARNVME%*.*}" ] || printf " YARN version $YARNME IS NOT $YARNV !! "

hash npm 2>/dev/null || printf "Need npm $NPMV" 
hash node 2>/dev/null || printf ",node $NODEV" 
hash yarn 2>/dev/null || printf ",yarn $YARNV" 
printf  "\n"
}

chk_dependencies(){
for n in $DEPENDENCIES; do
 rpm --quiet -q $n || DEP="$DEP $n"
done
hash node 2>/dev/null  ||  DEP="$DEP node"
hash npm  2>/dev/null ||  DEP="$DEP npm"
hash yarn  2>/dev/null ||  DEP="$DEP yarn"
echo $DEP
}

do_version(){
todir=$1
myPWD=$(pwd)
        [ -d "$todir" ] && [ $todir != $myPWD ] && cd $todir     
	GIT_SHA=$(git log -1 --pretty=format:'%H' HEAD^..HEAD)
        if [ $( git --version|awk '{split($3,a,".");print a[1]}') -gt 1 ]; then
		GIT_BRANCH=$(git branch --show-current)
	else
    		GIT_REF=$(git symbolic-ref HEAD 2>/dev/null)
		GIT_BRANCH="${GIT_REF#refs/heads/}"
	fi
    	VERSION="${GIT_BRANCH}"
        [[ -z $(git status -s|grep '^ .') ]] || VERSION="$VERSION dirty"
        [[ -z $(git cherry -v @{upstream}) ]] || VERSION="${VERSION} unpushed"

        VERSION="${VERSION} (${GIT_SHA:0:7})"
    	[ ! -d "$todir" ] &&  echo $VERSION && return
       
        cd $myPWD
        [ "$(basename $todir|cut -c-3)" = "dce" ] &&  comma="," 
        VERSION="${VERSION}${comma} [$(date '+%F %T')]"
        echo "Stamped: GIT_SHA=$(cat $todir/GIT_SHA 2>/dev/null) VERSION=$(cat $todir/VERSION 2>/dev/null)"
        if  [ "$action" == "version" ] ||  [ "$action" == "status" ]; then
          echo "Current: GIT_SHA=$GIT_SHA VERSION=$VERSION"
        elif  [ "$action" == "image" ]; then
          echo "Using: GIT_SHA=$(cat $todir/GIT_SHA 2>/dev/null) VERSION=$(cat $todir/VERSION 2>/dev/null)"
	else
          printf "${GIT_SHA}" > $todir/GIT_SHA
          printf "%s" "${VERSION}" > $todir/VERSION
          echo "NewStamp: GIT_SHA=$(cat $todir/GIT_SHA 2>/dev/null) VERSION=$(cat $todir/VERSION 2>/dev/null)"
        fi
}

do_artifactory(){
image=$1
  AID=${UXID}@us.ibm.com
  ART=${ARTDIR}.${ARTDOMAIN}
  echo -n "What is your ARTIFACTORY id [${AID}]:"; read ans
  [ -z "$ans" ] || AID=$ans
  PUSHIMAGE="${ART}/${ARTSUBDIR}/$image"
 # $SUDO $DOCKER image ls $PUSHIMAGE |grep -q $PUSHIMAGE
 # [ $? -gt 0 ] &&\
    $SUDO $DOCKER tag $image ${PUSHIMAGE}:latest
  $SUDO $DOCKER login -u $AID $ART 
  $SUDO $DOCKER push ${PUSHIMAGE}:latest
}

do_config(){
  if [ -f ${SCRIPT_PATH}/construct.cfg ] ; then 
   source ${SCRIPT_PATH}/construct.cfg	$container
   GITSSH=$SCRIPT_PATH/$GITSSH
   GIT_SSH=$SCRIPT_PATH/$GIT_SSH
   for w in URL REPO SRC DIR KEY; do #DOCKERFILE #OK
       x=$(printf "$%s" ${w})
       eval echo $w=$x
       #[ -n "${container}-$w" ] && eval $w=${container}-$w
   done 
   echo SOURCE_CODE_PATH: $SRC 
   #[ -d "$SRC" ] || [ "$action" == "clone" ] || SRC=$SCRIPT_PATH
  else
   echo "construct.cfg not found [${SCRIPT_PATH}/construct.cfg] ... exiting"
   exit 1
  fi
  echo SOURCE_CODE_PATH: $SRC
return
}

git_creds(){
  OID=$ID
  echo -n "What is your GIT id? [$ID]:"; read ans
  [ -z "$ans" ] || ID=$ans
  GIT="${ID}:${REPO}.git" #git@github.ibm.com:IntelligenceAugmentation/aldm.git
  echo ". $GITSSH force $KEY"
  source $GITSSH force $KEY
  ssh -T -ai $KEY $ID
  ret=$?
  [ $ret -le 1 ] && ret=0
  [ -z "$ans" ] || ID=$OID
  return $ret
}

do_git() {
  git_creds || exit 1
  if [ "$action" == "git" ] ; then
    GITREMOTE=$(git remote -v|awk '{if(NR>1)print $2}')
    echo REMOTE=$GIT REMOTE=$GITREMOTE
    if [ "$GIT" != "$GITREMOTE" ] || [ "$option" == "force" ] ;then
     	[ -d "$SRC" ] && cd $SRC || exit 2
     	git remote rm origin
     	git remote add origin $GIT
     	git push -u origin $(echo $(do_version branch)|cut -d' ' -f1)
        git config --global push.default current
    fi
     exit
  fi 
  [ -z "$ECHO" ] || echo "DIR=$DIR  SRC=$SRC GIT=$GIT LOCAL_REPO_ROOT=$LOCAL_REPO_ROOT"
  if [ "$action" == "gitpush" ] && [ -d "$SRC" ] && cd $SRC ;then
    do_version $SRC
    BRANCH="$(echo $(do_version branch)|cut -d' ' -f1)"
    [ "$BRANCH" !=  "master" ] && pusharg="--set-upstream origin $BRANCH" 
     git push $pusharg && return
  fi
  if [ "$action" == "gitdiff" ] && [ -d "$SRC" ] && cd $SRC ;then
    do_version $SRC
    BRANCH="$(echo $(do_version branch)|cut -d' ' -f1)"
    git fetch
    git diff $BRANCH remotes/origin/$BRANCH && return
  fi

  if [ -d "$DIR" ]; then
   cd  ${DIR}
   if [ -d "$SRC" ]; then
     cd $SRC
     CMD=pull
     #BRANCH=$(do_version branch)
     BRANCH="$(echo $(do_version branch)|cut -d' ' -f1)"
   else
     #[ -d "${DIR%/*}" ] || mkdir -p ${DIR%/*}
     cd  ${SRC%/*}
     CMD=clone
   fi
   
   if [ ! "$action" == "status" ] ;then 
     [ -z "$ECHO" ] || /bin/pwd
     echo "${CMD}ing $GIT"
    #git pull git@github.ibm.com:resiliency-tiaa-org/aldm.git  aldm20
     git $CMD $GIT ${BRANCH}
     [ "$CMD" = "pull" ] && git pull origin $BRANCH #updates the local repo commit msa: "gYour branch is ahead of 'origin/master' by n commits."
   else
      git remote update
   fi
   [ "$(echo $container|cut  -c-3)" == "dce" ] && cd $DIR
   echo ">>>>> remote [${GIT}] status <<<<<" && git status $GIT; gitstatus=$?
   cd $SRC
   [ -d "$SRC" ] && echo ">>>>> local [${SRC}] status <<<<<<" && git status 

  else
   echo "Directory: $DIR  not found "
   gitstatus=1
  fi

echo "returning git status: $gitstatus"
return $gitstatus 
}

is_docker_daemon_running() {
    curl -s --unix-socket $DOCKERSOCKET "${DOCKERPING}"  > /dev/null
    status=$?

    if [ "$status" == "7" ]; then
        printf "'$DOCKER' daemon not running, exiting\n"
    fi
    return $status
}

usage() {
error=$1
case $error in
 0|1) cat -<< EOU
 Usage: [DAYS=90] $(basename $0) container_name [build|image|push] [local|nohado]
                     container_name clone|status|gitpush             
                     container_name markit [nocommit]
                     container_name build local - local OS bits only
                     container_name image nohado - no linting Dockerfile
EOU
    ;;
 *) echo "Usage: $(basename $0) container_name " ;;
esac
if [ $error -ne 1 ] ;then
    printf "\n       containers: $VALID_CONTAINERS \n" 
    echo "       additional sources: $VALID_CLONES " 
fi
exit $error
}

do_markit(){
plusfile=$1
[ "$UNAME"  == "Linux" ] || return 1
if [ "$plusfile" == "nohado" ]; then
        plusfile=""
elif [ "$plusfile" == "commit" ];then
	git commit -a -m "committing $container src files" && return
fi
       
    [ -f "filelist" ] && export MARKITFILELIST=$SRC/filelist
     echo -n "marking $container files  "
     if [ "$plusfile" == "nocommit" ] ; then
        $SCRIPT_PATH/bin/markit none cvs
     else
        $SCRIPT_PATH/bin/markit no cvs $plusfile
     fi
}


conv_xz_files() {
        for n in $(find $DOCKERDIR/aldm -type f -name "*.xz" -print) $(find $DOCKERDIR/dce -type f -name "*.xz" -print); do
                printf "\rUnpacking %s                        " ${n##*/}
                xz -d $n
        done
        printf "\r                                                        \n"
}

do_base_image(){
 bi=$1
  if ( $SUDO $DOCKER images|awk '{print $1,$2}'|grep "$bi latest" ); then
    echo "base image found"
  elif [ -f $DOCKERDIR/aldm/$bi.xz ] || [ -f $DOCKERDIR/aldm/$bi ]; then
    echo "loading base image "
    $SUDO $DOCKER load -i $DOCKERDIR/aldm/$bi
  else
    echo "base image NOT found"
    if [ -z "$DOCKERFILE" ];then
       if [ -f "Dockerfile.base" ]; then
          DOCKERFILE=Dockerfile.base
          return 1
       elif [ -f "Dockerfile.perl" ]; then
          DOCKERFILE=Dockerfile.perl
          return 1
       else
          echo "Dockerfile.base or .perl NOT found, reverting to Dockerfile"
          DOCKERFILE=Dockerfile
       fi
    fi
  fi
 return
}

### MAIN ####
[ -z "$container" ] || [ "$container" == "help" ] && usage 0
[ "$container" == "." ] && container=$(dirname $PWD)

[ $(id -un) == "root" ] || SUDO=sudo
[ $(id -un) == "root" ] && echo "Warn: You are root, best run as user with sudo privledges" 

chk_name $container || usage $? 

do_config

[ -z "$CONTAINER" ] || container=$CONTAINER
[ -z "$ECHO" ] || echo "CONTAINER/SOURCE: $container"

if [ -d "$SRC" ] ; then
      cd $SRC
else
      echo "No container source directory $SRC ...  will attempt to clone one" #SRC
      CLONE=True
fi

case $container in
  #DCE
  dce-webapp)
    INSTRUCTIONS='rm -rf ./build; npm install; npm run build-docker'
    image_dir=dce
    image_name="dce-webapp-image"
    base_image_name="dce-webapp-base"
    CHKDEP=1
    ;;
  dce-graphql)
    INSTRUCTIONS=' rm -rf ./lib; npm install; npm run build; '
    image_dir=dce
    image_name="dce-graphql-image"
    CHKDEP=1
    ;;
  dce-pipeline)
    INSTRUCTIONS=' rm -f *.pyc; cat ../dce-signatures/perljamsigsVer1.6.csv > signatures.csv; python2 -m compileall -l .; '
    image_dir=dce
    image_name="dce-pipeline-image"
    base_image_name="dce-pipeline-base"
    ;;
  redis)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir=dce
    image_name="redis-image"
    image_src='redis:alpine'
    ;;
  #ALDM 2.0
  aldm-ui)
    INSTRUCTIONS=' yarn build '
    image_dir=aldm
    image_name="aldm-ui-image"
    CHKDEP=1
    ;;
  aldm-api)
    INSTRUCTIONS=' npm build '
    image_dir=aldm
    image_name="aldm-api-image"
    CHKDEP=1
    ;;
  #ALDM 
  aldm-pipeline)
    #MARKIT=True
    INSTRUCTIONS="[ -d $SRC/DIST ] || mkdir -p $SRC/DIST "
    INSTRUCTIONS="${INSTRUCTIONS}; [ -d /ALDM/GA2F/autoload/code/REPO/ ] || $SUDO mkdir -p /ALDM/GA2F/autoload/code/REPO "
    INSTRUCTIONS="${INSTRUCTIONS}; export SRCROOTDIR=$SRC;bin/mk_par_dist.sh \$(bin/get_parname.pl) par.list HANDSFREE ${DAYS} $option "
    INSTRUCTIONS="${INSTRUCTIONS}; bin/createExpiry.pl half $SRC/autoload/inc/end.key 2>&1 |tail -5|head -3"
    image_dir=aldm
    image_name="aldm-pipeline-image"
    base_image_name="aldm-pipeline-base"
    ;;
  aldm-db2|db2server)
    INSTRUCTIONS=" export ROOT_DIR=$DIR ; export ROOT_CODEDIR=$SRC; echo 'no build, just image creation'"
    image_dir=aldm
    image_name="db2server-image"
    base_image_name="db2server-base"
    ;;
  aldm-db2-base|db2server-base)
    INSTRUCTIONS='echo no build, just image creation'
    INSTRUCTIONS=" export ROOT_DIR=$DIR ; export ROOT_CODEDIR=$SRC; echo 'no build, just image creation'"
    image_dir=aldm
    image_name="db2server-base"
    ;;
  aldm-webui)
    INSTRUCTIONS=" export ROOT_DIR=$DIR ; export ROOT_CODEDIR=$SRC;" #$SRC/bin/mk_all.sh $option
    image_dir=aldm
    image_name="aldm-webui-image"
    base_image_name="aldm-webui-base"
    ;;
  aldm-postgres)
    INSTRUCTIONS=" export ROOT_DIR=$DIR ; export ROOT_CODEDIR=$SRC;" 
    image_dir=aldm
    image_name="postgres-image"
    ;;
  aldm-webportal)
    INSTRUCTIONS=" export ROOT_DIR=$DIR ; export ROOT_CODEDIR=$SRC;$SRC/bin/mk_all.sh $option"
    image_dir=aldm
    image_name="aldm-portal-image"
    base_image_name="aldm-portal-base"
    ;;
  aldm-derby|derby)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir=aldm
    image_name="derby-image"
    ;;
  aldm-pipeline-base*)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir=aldm
    image_name="${container}"
    ;;
  aldm-webportal-base|aldm-portal-base)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir=aldm
    image_name="aldm-portal-base"
    ;;
  aldm-distribution)
    INSTRUCTIONS='echo no build, git only'
    ;;
  aldm-documentation)
    INSTRUCTIONS='echo no build, git only'
    ;;
  aldm-collectors)
    INSTRUCTIONS="export MYSRCDIR=$SRC/src; $SRC/bin/makeall.sh"
    ;;
  aldm-ecosystem)
    INSTRUCTIONS="echo run: $(basename $0) aldm-scripts build"
    ;;
  aldm-scripts)
    INSTRUCTIONS="tar -cf aldm-scripts.tar -C $SRC/aldm-scripts aldm-start.sh deploy-config.sh ; tar -uf aldm-scripts.tar -C $SRC rpm_dependencies.sh VERSION ; gzip -f aldm-scripts.tar"
    image_dir=aldm
    image_name="aldm-scripts"
    ;;
  aldm-itrix)
    INSTRUCTIONS=' cd UI;rm -rf ./dist; npm install; npm run build; '
    image_dir=aldm
    image_name="aldm-itrix-image"
    CHKDEP=1
    ;;
 #ALDM and DCE
  mariadb)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir="aldm dce"
    image_name="mariadb-image"
    #image_src="mariadb/server:${MARIADBVER}"
    image_src="docker.io/library/mariadb:${MARIADBVER}"
    ;;
  #EXPERIMENTAL
  aldm-browser|browser)
    INSTRUCTIONS='sh mk_conf_menu.sh'
    image_dir=aldm
    image_name="browser-image"
    ;;
  nginx)
    INSTRUCTIONS='echo no build, just image creation'
    image_dir=aldm
    image_name="nginx-image"
    image_src='nginx:alpine'
    ;;
  *)  chk_name $container || usage  2 ;;
esac

if ([ "$action" = "build" ] || [ "$action" = "check" ] ) && [ "$UNAME"  == "Linux" ] && [ $CHKDEP -eq 1 ];then 

     echo "Checking dependencies ... " 
     DEPS=$(chk_dependencies) 
     echo DEPS:$DEPS
     if [ -n "$DEPS" ] ;then
            echo "Checking more dependencies ... "
            chk_dependencies_ver
	    echo "option=$option option2=$option2 cdv=$(chk_dependencies_ver)"
	    
            if [ -n "$(chk_dependencies_ver)" ] &&\
		    [ "$option" != "ignore" ] &&\
		    [ "$option2" != "ignore" ] ;then
           	 cat -<<EOH
             INSTRUCTIONS ---
                Installing Node.js:
                 # wget https://nodejs.org/download/release/$NODEV/node-${NODEV}-linux-x64.tar.gz
                 # tar -xzf node-${NODEV}-linux-x64.tar.gz
                 # cd node-${NODEV}-linux-x64
                  
                  git clone https://github.com/nodejs/node.git
                  cd node
                  ./configure
                  make -j4
                  make doc  #optional
                  make install
                  
                Installing npm@$NPMV :
		  curl -qL https://www.npmjs.com/install.sh > npm_INSTALL.sh && chmod 755 npm_INSTALL.sh
                  npm_install=$NPMV ./npm_INSTALL.sh

                Installing yarn :
                   /usr/local/bin/npm install -g yarn
EOH
           	 cat -<<EOY
                  run: $(basename $0) $@ ignore  - to ignore checks for Node and Yarn
EOY
            	echo "Exiting now ... "  && exit 2
            fi
     fi
fi
#TACCI

for idir in $image_dir; do
    echo "IMAGE DIR: $DOCKERDIR/$idir  IMAGE NAME: $image_name ACTION: $action"
done
## apply action

[ "$action" = "check" ]  && exit
if [ "$action" == "image" ] || [ "$action" == "push" ]  ;then
     echo "git step not required for $action action ... continuing"
else
     if [ -n "$image_src" ]; then
         echo "IMAGE_SRC: $image_src"
         printf "INSTRUCTIONS:" ;eval $INSTRUCTIONS
         exit 0
     fi
     [ "$action" == "version" ] || do_git || exit 4
     if [ "$action" == "gitpush" ] || [ "$action" == "status" ] || [ "$action" == "stamp" ]; then
        [ "$action" == "gitpush" ] || [ "$action" == "stamp" ] &&  [ -d $SRC ] && do_version $SRC ##need to rewrite VERSION to disk (pushed in do_git call
        echo "completed $action ... exiting" 
        exit 
     fi
     [ -z "$CLONE" ] || cd $SRC

     if [  -z "$action" ] || [ "$action" == "build" ];then
            [ -z "$MARKIT" ] || do_markit 
            echo "SRC:$SRC  PWD:$PWD "
            echo "You are building '${BRANCH}' if this is not correct, checkout the branch you prefer and start build again. The last configured branch was $CFG_BRANCH"
            printf "hit <return> to continue or any key+<CR> to exit:"; read ans
            [ -z "$ans" ] || exit
            eval $INSTRUCTIONS  #do the build!
	    ## XXX: needed to rethink commiting during the build stage
            [ "$option" = "commit" ] && git commit -a -m "updated build vers $(cat VERSION) " ###
     fi
fi

if [ "$action" == "diff" ] || [ "$action" == "pull" ]; then
   git fetch 
   b=$(basename $SRC)
   git diff --stat ${BRANCH} origin/${BRANCH}  |grep $b | awk '{ print $1 }'| tee diff.txt 
   while read n; do
    git diff ${BRANCH} origin/${BRANCH} -- ${n#*/}
    if [ "$action" == "pull" ]; then
       printf "Pull? [Y|n]:"; read ans
       if  [ -z "$ans" ] || [ "$ans" = "Y" ];then
	  git checkout -m origin/${BRANCH} ${n#*/}
	  git add ${n#*/}
          git commit
       fi
    fi
   done<diff.txt
   exit
fi

[ -d $SRC ] && do_version $SRC
[ "$action" == "version" ]  &&  exit 0

if hash $DOCKER ; then
    if [ ! is_docker_running ]; then
         echo "Docker not running, trying to start "
         if [ "$UNAME"  == "Linux" ]; then
              $SUDO systemctl start docker
              $SUDO systemctl enable docker
         fi
    fi

    if [ -z "$action" ] || [ "$action" == "image" ] || [ "$action" == "push" ]  ;then
         if [ -z "$action" ] || [ "$action" == "image" ]  ;then
            if [ "$image_name" == "aldm-scripts" ] || [ "$image_name" == "dce-scripts" ] ; then
                [ -f $SRC/${image_name}.tar.gz ] && $SUDO mv -f $SRC/${image_name}.tar.gz $DOCKERDIR/$image_dir/${image_name}.tgz
            else
                [ -z "$base_image_name" ] ||  do_base_image $base_image_name || image_name="$base_image_name"

		#adjust the dockerfile
                : ${DAYS:=90} 
                : ${DOCKERFILE:="Dockerfile"} 
                [ -z "$XTRABUILDARG" ] || XTRABUILDARG="--build-arg $XTRABUILDARG" #Name=Value pair
                DC=$(($(date +%s) + $DAYS * 24 * 3600 )) ; 
                $SUDO rm -f /tmp/$DOCKERFILE
		sed -e "s/\(DC=\)[0-9]\{10\}/\1$DC/" -e "s/1580947439/$DC/"  $DOCKERFILE > /tmp/$DOCKERFILE && DOCKERFILE=/tmp/$DOCKERFILE

                [ -z "$ECHO" ] || echo "DIR=$DIR  SRC=$SRC pwd=$PWD DOCKERFILE=$DOCKERFILE image_name=$image_name"
                if [ -n "$image_dir" ] && [ -n "$image_name" ];then
                  if [ -z "$option" ] || [ ! "$option" == "save" ] ;then
                    if [ ! "$option" == "nohado" ] ;then
                     ##https://github.com/hadolint/hadolint
		     ##https://hub.docker.com/r/hadolint/hadolint
                         if [ -f ${DOCKERFILE} ];then
                              echo "linting dockerfile $DOCKERFILE"
                              #$SUDO $DOCKER run --rm hadolint/hadolint hadolint --version
                              $SUDO $DOCKER run --rm -i docker.io/hadolint/hadolint:latest <${DOCKERFILE}
                         fi
                    else
                         echo $option $DOCKERFILE
                    fi #hado
    
		    tag_image_name="${image_name}:latest"
		    echo $image_name| grep -q ':' && tag_image_name=$image_name
                    echo "creating image $image_name and tagging $tag_image_name"
		    sleep 4
                    ## VERSION/DAYS used by DCE  ALDM pipeline
                    if [ -n "$image_src" ]; then
                          echo "inspecting $image_src"
                          $SUDO $DOCKER  inspect -f {{.Id}} $image_src 2>/dev/null || $SUDO $DOCKER pull $image_src 
                    else
			  #https://docs.podman.io/en/latest/markdown/podman-build.1.html
			  # export BUILDAH_FORMAT=docker
                          $SUDO $DOCKER build ${IMAGEBUILDOPTS}  \
				  --format docker \
                                  --build-arg VERSION="$(cat VERSION)" \
                                  --build-arg DAYS=${DAYS} $XTRABUILDARG \
                                  -t $tag_image_name -f ${DOCKERFILE:="Dockerfile"} .
                          image_src=$image_name
                    fi
	          elif [ "$option" == "save" ]; then
                          image_src=$image_name
		  fi #save
		  if [ -z "$image_src" ]; then
                    echo "inspecting $image_name"
		    $SUDO $DOCKER inspect --format '{{.ManifestType}}'  $image_name
		  fi
	          if [ "$option" != "nosave" ]; then
		    save_image_name=$(echo $image_name|sed -e 's/:/-/')
                    echo "saving $image_src to $save_image_name"
                    $SUDO  $DOCKER save --format=docker-archive $image_src|xz -9 > /tmp/${image_name}.xz 
                    for idir in $image_dir; do
                         [ "$idir" = "dce" ] && [ "$image_name" = "mariadb-image" ] && [ "$MARIADBVER" = "10.1" ] && continue #no 10.1 for dce
                         $SUDO cp -f /tmp/${image_name}.xz $DOCKERDIR/${idir}/${save_image_name}.xz 
                         [ "$image_name" = "mariadb-image" ] && continue ##no git repo copy
                         [ -d "IMAGES" ] || mkdir -p IMAGES
                         VTAG="$(cat VERSION|sed -e 's/\[.*$//' -e 's/[()]//g' -e 's/ $//' -e 's/ /-/g')"
                         save_image_name="$(echo ${save_image_name}| sed -e 's/image//')${VTAG}-image"
                         echo -n "Save copy to IMAGES/${save_image_name}.xz ? [y|N]:";read ans
                         [ "$ans" == "y" ] && cp /tmp/${image_name}.xz IMAGES/${save_image_name}.xz
                    done
                    $SUDO rm -f /tmp/${image_name}.xz
                  fi #save
                fi #dir/name
              fi #ecosystem image
         else
             echo "Warn: no image done for $container "
             echo "Use: '$(basename $0) $container  [ image ]' to complete the construction steps  "
         fi
         if [ -z "$action" ] || [ "$action" == "push" ]  ;then
             echo -n "Do you wish to push $image_name to the ARTIFACTORY? [Y|n]:"; read ans
             if [ -z "$ans" ] || [ "$ans" == "Y" ];then
                do_artifactory $image_name
             fi
         else
             echo "Warn: no push done for $container "
             echo "Use: '$(basename $0) $container  [ push ]' to complete the construction steps  "
         fi
     elif [ "$action" == "markit" ]; then
             do_markit $option &&\
             echo "Warn: no build done for $container"  &&\
             echo "Use: '$(basename $0) $container  [ build ]' to complete the construction steps  "
     elif [ "$action" == "commit" ]; then
             do_markit $action &&\
             echo "Warn: no build done for $container"  &&\
             echo "Use: '$(basename $0) $container  [ build|gitpush ]' to complete the construction steps  "
     else
             echo "Warn: no image|push done for $container "
             echo "Use: '$(basename $0) $container  [ image|push ]' to complete the construction steps  "
     fi

else
     echo "$DOCKER not installed"
     [ "$UNAME"  == "Linux" ] && $SUDO yum install docker-ce containerd.io && echo "Docker installed, try script again"
fi

#cleanup
[ "$UNAME"  == "Linux" ] && [ $(ps -ef|grep ssh-agent|wc -l|awk '{print $1}') -gt 9 ] && pkill ssh-agent
#rm -f GIT_SHA VERSION
cd "$CURRENT_PATH"
echo "..bye"
exit 0
## end - mt 2019
 
 
 
