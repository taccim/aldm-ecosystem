#!/bin/bash

do_version(){
todir=$1
myPWD=$(pwd)
        [ -d "$todir" ] && [ $todir != $myPWD ] && cd $todir
        GIT_SHA=$(git log -1 --pretty=format:'%H' HEAD^..HEAD)
        GIT_REF=$(git symbolic-ref HEAD 2>/dev/null)
        GIT_BRANCH="${GIT_REF#refs/heads/}"
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

source /home/mtacci/ALDM/CODE_build/ALDM2.0/aldm-ecosystem/construct.cfg $1

echo $1:
 cat -<<EOI 
    ID=$ID
    URL=$URL
    REPO=$REPO
    DIR=$DIR
    SRC=$SRC
    KEY=$KEY
EOI

do_version $SRC

  GIT="${ID}:${REPO}.git" #git@github.ibm.com:IntelligenceAugmentation/aldm.git
  echo export GIT=$GIT
  echo source $GITSSH force $KEY
  echo ssh -T -ai $KEY $ID
  echo "git config pull.rebase false #optional"
  echo "git push --set-upstream origin <branch>"






