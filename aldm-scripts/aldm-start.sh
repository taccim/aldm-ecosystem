#!/usr/bin/env bash

##----------------------------------------------------------------------------------------------------------##
#@(#) $Id: aldm-start.sh,v 1.80 2025/02/04 20:53:42 mtacci Exp $
#@(#) Description: shell script                                                                             ##
#@(#) Author: mtacci 
#@(#) Copyright: Property of IBM, Copyright © 2017-2019 IBM Corporation, Armonk, NY. All Rights Reserved.   ##
#@(#)     The source code for this program is not published or otherwise divested of its trade secrets,     ##
#@(#)     irrespective of # what has been deposited with the U.S. Copyright Office.                         ##
#@(#)     Use of this material without the express consent of IBM or assignees is unlawful and subject to   ##
#@(#)     prosecution to the fullest extent of the law.                                                     ##
##----------------------------------------------------------------------------------------------------------##

#### ENVIRONMENT  ####
ALDM_VER=1                                   # 1|2  default:1
ALDM_HOST_DOMAINNAME=''                      #default: aldm.sl.edst.ibm.com
IBM=0

### ******************** DO NOT EDIT BELOW THIS LINE  *********************** ###
REVISION=$(echo '$Revision: 1.80 $'|awk '{print $2}')

# Global variables

DCE_GRAPHQL_CONTAINER_NAME='dce-graphql-container'
DCE_WEBAPP_CONTAINER_NAME='dce-webapp-container'
DCE_PIPELINE_CONTAINER_NAME='dce-pipeline-container'
REDIS_CONTAINER_NAME='redis-container'
MARIADB_CONTAINER_NAME='mariadb-container'
ALDM_PIPELINE_CONTAINER_NAME="aldm-pipeline-container"

ALDM_PORTAL_CONTAINER_NAME="aldm-portal-container"
DERBY_CONTAINER_NAME='derby-container'
ALDM_WEBUI_CONTAINER_NAME="aldm-webui-container"   #ALDM2.0
POSTGRES_CONTAINER_NAME='postgres-container'  #ALDM2.0
DB2SERVER_CONTAINER_NAME="db2server-container"   #ALDM1.5

ALDM_UI_CONTAINER_NAME='aldm-ui-container'
ALDM_API_CONTAINER_NAME='aldm-api-container'
COUCHDB_CONTAINER_NAME='couchdb-container'

BROWSER_CONTAINER_NAME='browser-container'

DCE_NETWORK='172.18.0.0/28'
MARIADB_CONTAINER_IP='172.18.0.10' 	#DCE_DB_HOST
REDIS_CONTAINER_IP='172.18.0.11' 	#DCE_REDIS_HOST
DCE_PIPELINE_CONTAINER_IP='172.18.0.13'
DCE_GRAPHQL_CONTAINER_IP='172.18.0.12'
DCE_WEBAPP_CONTAINER_IP='172.18.0.14'   

ALDM_PIPELINE_CONTAINER_IP='172.18.0.9' #ALDM-HOST
ALDM_PORTAL_CONTAINER_IP='172.18.0.8'   #PORTAL-HOST
ALDM_WEBUI_CONTAINER_IP='172.18.0.8'    #WEBUI-HOST
DERBY_CONTAINER_IP='172.18.0.7' 	#DERBY-HOST
POSTGRES_CONTAINER_IP='172.18.0.7' 	#POSTGRES-HOST

ALDM_UI_CONTAINER_IP='172.18.0.8' 
COUCHDB_CONTAINER_IP='172.18.0.7' 
ALDM_API_CONTAINER_IP='172.18.0.6' 

DB2SERVER_CONTAINER_IP='172.18.0.5'     #DB2-HOST   
                                       #.4 RESERVED
BROWSER_CONTAINER_IP='172.18.0.3' 
                                       #.2 docker generate
                                       #.1 default
##comm paths
#ALDM-HOST --> DCE_DB_HOST:3306
#ALDM_PORTAL_CONTAINER_IP(B1215-8) -+<-> DERBY-HOST:1527 
#                                     +--> ALDM-HOST:1837

ALDM_PORTAL_PORT1='80'
ALDM_PORTAL_PORT2='443'
ALDM_PORTAL_PORT3='1835'
ALDM_PORTAL_PORT4='1836'
ALDM_WEBUI_PORT3='8000'
ALDM_WEBUI_PORT4='8083'
ALDM_PORTAL_HOSTNAME="$(hostname -s)-8"
ALDM_UI_HOSTNAME="$(hostname -s)-8"
ALDM_WEBUI_HOSTNAME="$(hostname -s)-8"
ALDM_PIPELINE_HOSTNAME="$(hostname -s)-9"
DB2SERVER_HOSTNAME="$(hostname -s)-5"

SMASHDIRS="/dce/target/data/reports /dce/tmp /dce/DB2/autoload/data /dce/DB2/autoload/staging /dce/dbs"
REMAKEDIRS="/dce/target/data/reports /dce/tmp/tomcat /dce/mysql /dce/dbs"

#Local Variables
FRIENDS="exec stop remove restart status nuke reset version"
ARG1=$1
ARG2=$2 #aldmversion 1|2 |port
ARG3=$3 #nowait or 0|1 iguana
ALIAS=""

#Dynamic vairiables

[ -z $DOMAINNAME ] || ALDM_HOST_DOMAINNAME=".$DOMAINNAME"
: ${MARIADBVER:="10.4"}  ##changed to 10.4 for DCE ^
: ${IBM:=0}  

EDST=$(hostname -f |xargs printf "%s."|awk -F. '{n=0;if($2 == "aldm")n++;print n}')
ALIST0="$ALDM_PIPELINE_CONTAINER_NAME"
ALIST1="$ALDM_PORTAL_CONTAINER_NAME $DERBY_CONTAINER_NAME"
ALIST2="$ALDM_WEBUI_CONTAINER_NAME $POSTGRES_CONTAINER_NAME"
ALIST3="$COUCHDB_CONTAINER_NAME $ALDM_UI_CONTAINER_NAME $ALDM_API_CONTAINER_NAME" #Mark Lindsey code

ALIST="$ALIST0 " #replace 1 with 2 when we go to ALDM2.0
if [ ${ARG2:-0} = 2 ] ;then
	ALIST="$ALIST $ALIST2"
elif [ ${ARG2:-0} = 3 ] ;then
	ALIST="$ALIST $ALIST3"
else
	ALIST="$ALIST $ALIST1"
fi
DLIST="$REDIS_CONTAINER_NAME $DCE_PIPELINE_CONTAINER_NAME $DCE_GRAPHQL_CONTAINER_NAME $DCE_WEBAPP_CONTAINER_NAME"

#OS Derivation
 OSRELEASEFILE="/etc/os-release"
 source $OSRELEASEFILE
 for w in ID VERSION_ID; do
    x=$(printf "$%s" ${w})
    eval $w=$x
 done
 major=${VERSION_ID%.*}; minor=${VERSION_ID#*.*}
####SUBROUTINES ####
usage(){

if [ "$(basename $0)" = "aldm-exec.sh" ];then
 cat -<< EOF
   Usage: $(basename $0)  start [ALDM|DCE|all] |stop|remove|restart|status|version|backupdb
			  start ALDM|DCE|all - starts ALDM|DCE|all containers
			  stop - stops all containers
			  remove - removes all containers
			  restart - restarts all containers
			  status - shows status of all containers
			  version - shows version of all containers code
			  backupdb [aldm|dce] - database backup 
                          help - this message
EOF
else
 cat -<< EOFF
   Usage: $(basename $0) container-name 
   Containers: mariadb aldm-pipeline
               derby aldm-portal
               couchdb aldm-ui aldm-api
               db2server
               browser
               redis dce-pipeline dce-graphql dce-webapp
EOFF
fi
}

# Functions
#DOCKER control

###################

get_docker_socket() {
 svcscript=$1
 socket=/dev/null
 [ -z "$XDG_RUNTIME_DIR" ]  && XDG_RUNTIME_DIR="/run"
 if [ -f  /usr/lib/systemd/system/${svcscript} ]; then
 	eval $(grep ListenStream /usr/lib/systemd/system/${svcscript})
	socket=$(echo $ListenStream|sed -e "s,%t,${XDG_RUNTIME_DIR},")
 fi
 if [ -S $socket ]; then
        echo $socket
 elif [ $major -eq 7 ]; then
     	echo "/var/run/docker.sock"
 elif [ $major -ge 8 ]; then
	([ -S  $XDG_RUNTIME_DIR/podman/podman.sock ] && echo "$XDG_RUNTIME_DIR/podman/podman.sock" ) ||\
	echo "/run/podman/podman.sock" 
 elif [ $major -eq 22 ] && [ "$ID" = "ubuntu" ]  ;then  #22.04 unbuntu
	echo "/mnt/wslg/runtime-dir/podman/podman.sock" 
 fi
}

is_docker_daemon_running() {
 if [ "$(get_docker_daemon_status)" -gt 0 ] ; then
        printf "'$DOCKER' daemon not running \n"
        return 1
 fi

}

function get_docker_daemon_status  {
    $(curl -s --unix-socket $DOCKERSOCKET $DOCKERPING > /dev/null)
    status=$?
    echo $status
}

function init_podman {
 [ "$(get_docker_daemon_status)" == "0" ] || FORCE=FORCE
 #if [ ! -f /etc/containers/policy.json ] || [ -n "$FORCE" ] ;then
 #       [ $IBM -eq 1 ] &&\
 #              mk_policy_file /etc/containers/policy.json
 #              mk_registries_file /etc/containers/registries.conf
 #              mk_storage_file /etc/containers/storage.conf
 #fi
 if [ $major -eq 22 ] && [ "$ID" = "ubuntu" ]  ;then  #22.04 unbuntu
	 [ -d /mnt/wslg/runtime-dir/podman ]  || mkdir -p  -d /mnt/wslg/runtime-dir/podman  
	  podman system service --time=30 unix://$DOCKERSOCKET &
	  return 
 fi
 systemctl daemon-reload;sleep 2
 systemctl start podman.service;sleep 2
 systemctl enable --now podman.socket;sleep 2
 systemctl stop podman.socket;sleep 2
 systemctl start podman.socket;sleep 2
 systemctl status podman.socket|cat -
}

function init_docker {
 [ "$(get_docker_daemon_status)" == "0" ] || FORCE=FORCE
 #if [ ! -d /etc/docker ] || [ -n "$FORCE" ] ;then
 #       mkdir -p /etc/docker
 #       [ $IBM -eq 1 ] &&\
 #               mk_daemon_file /etc/docker/daemon.json
 #
 #fi
 systemctl daemon-reload
 systemctl start docker
 systemctl enable docker || return 1
}

init_docker_daemon(){
	echo "attempting to start daemon"
	case $DOCKER in 
		docker) init_docker ;;
		podman) init_podman ;;
	esac
}

################
wait_for_service(){
SVCPORT=$1
SVCIP=$2
 [ $major -eq 7 ] && while ! curl --output /dev/null --silent --head --fail  ${SVCIP:=127.0.0.1}:${SVCPORT}; do sleep 1 && printf "."; done
 [ $major -ge 8 ] && until  [ $(curl --output /dev/null --silent --head --fail  ${SVCIP:=127.0.0.1}:${SVCPORT};echo $?) -eq 8 ];do sleep 1 && printf "."; done
 [ $major -eq 22 ] && printf "."&& sleep 16 && printf "."
 sleep 2
 return
}

update_database(){
    CONTAINER=$1
    ACTION=$2
    myDBNAME=$3
    dbscript="/opt/IBM/ALDM/mysql/aldm-database-build.sh"
    purge="/opt/IBM/ALDM/mysql/dbpurge.sh"
    echo "applying database ${ACTION-"action"}    "
    case $ACTION in
	create) script=$dbscript ;;
	purge)  script=$purge; purgeOpt=$myDBNAME ;;
        drop)   COMMAND="mysql -e 'drop database ${myDBNAME:-"aldm"};' -u root -pmypass" ;;
	backup) 
		while [ -z "$myDBNAME" ];do 
 			echo -n "Backup what?  aldm|dcedb  [${myDBNAME:-"aldm"}]:"; read myDBNAME
       			[ -z "$myDBNAME" ] && myDBNAME='aldm'
		done	
                [ -d /dce/mysqlbkup ] || mkdir -p /dce/mysqlbkup
	        COMMAND="mysqldump -uroot -pmypass -C $myDBNAME > /dce/mysqlbkup/${myDBNAME}_$(date +%y%m%d) " ;;
	*) 	return ;;
    esac

    [ -n "$COMMAND" ] || COMMAND="[ -x $script ] && $script mypass DCE_DB_HOST $purgeOpt" 
    $DOCKER exec -it ${CONTAINER} /bin/sh -c "$COMMAND"
}

start_container() {
    CONTAINER=$1;shift
    CONTAINER_OPTIONS=$@
   
    #https://docs.podman.io/en/latest/markdown/podman-run.1.html
    if [ "$DOCKER" == "docker" ]; then
	 SECURITY_OPTIONS="--security-opt=no-new-privileges "
    elif [ "$DOCKER" == "podman" ]; then
	 SECURITY_OPTIONS="--security-opt=no-new-privileges --security-opt=label=disable "
    fi
    RUN_OPTIONS="$SECURITY_OPTIONS --privileged=false"
    [ $major -eq 22 ] && RUN_OPTIONS="$RUN_OPTIONS --no-healthcheck "  #change later for the detection of systemd
    [ $CONTAINER = "db2server" ] && RUN_OPTIONS="$RUN_OPTIONS --no-healthcheck "  

    case $CONTAINER in
        aldm_pipeline) 	start_aldm_pipeline $CONTAINER_OPTIONS $RUN_OPTIONS;;
        aldm_portal) 	start_aldm_portal $CONTAINER_OPTIONS $RUN_OPTIONS;;
	aldm_webui) 	start_aldm_webui $CONTAINER_OPTIONS $RUN_OPTIONS;;
	postgresdb) 	start_postgresdb $CONTAINER_OPTIONS $RUN_OPTIONS;;
	db2server) 	start_db2server $CONTAINER_OPTIONS $RUN_OPTIONS;;
        derbydb) 	start_derbydb $CONTAINER_OPTIONS $RUN_OPTIONS;;
        browser) 	start_browser $CONTAINER_OPTIONS $RUN_OPTIONS;;
        couchdb) 	start_couchdb $CONTAINER_OPTIONS $RUN_OPTIONS;;
        aldm_ui) 	start_aldm_ui $CONTAINER_OPTIONS $RUN_OPTIONS;;
        aldm_api) 	start_aldm_api $CONTAINER_OPTIONS $RUN_OPTIONS;;
        redis) 		start_redis $CONTAINER_OPTIONS $RUN_OPTIONS;;
        dce_pipeline) 	start_dce_pipeline $CONTAINER_OPTIONS $RUN_OPTIONS;;
        dce_graphql_server) 	start_graphql_server $CONTAINER_OPTIONS $RUN_OPTIONS;;
        dce_web_app) 	start_dce_web_app $CONTAINER_OPTIONS $RUN_OPTIONS;;
        mariadb) 	start_mariadb $CONTAINER_OPTIONS $RUN_OPTIONS;;
	*) 	return ;;
    esac
}

start_db2server() {
docker_opts="$@"

    # If a DB2 container already exists, start it; if it does not exist, run it
    if [ "$($DOCKER ps -a | grep ${DB2SERVER_CONTAINER_NAME})" ]; then
    	printf "Starting ALDM DB2 database in network 'dce'…\n"
        $DOCKER start ${DB2SERVER_CONTAINER_NAME}
        printf "\n"
    else
    	[ "$($DOCKER image ls | grep db2server-image)" ] || return 1
    	printf "Running ALDM DB2 database in network 'dce'…\n"
    	ImageName="$($DOCKER image ls | grep db2server-image|awk '{printf("%s:%s", $1,$2)}')" 
    

     $DOCKER run \
        $docker_opts \
	--volume=/dce/tmp:/tmp:rw \
	--volume=/dce/DB2:/DB2:rw \
	--volume=/dce/db2:/database:rw \
        --name ${DB2SERVER_CONTAINER_NAME} \
         -h ${DB2SERVER_HOSTNAME}${ALDM_HOST_DOMAINNAME} \
        --network=dce --ip=${DB2SERVER_CONTAINER_IP} -p 50000:50000 -p 50001:50001 \
        -it -d $ImageName
        #-it -d db2server-image  
    fi
       
}

start_aldm_pipeline() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep aldm-pipeline-image)" ] || return 1
    printf "Running ALDM Pipeline in network 'dce'…\n"
    ImageName="$($DOCKER image ls | grep aldm-pipeline-image|awk '{printf("%s:%s", $1,$2)}')" 
    
    # Just in case remove any running containers with the same name
    #for di in `$DOCKER ps -f name=${ALDM_PIPELINE_CONTAINER_NAME} -a -q`; do #all
    for di in `$DOCKER ps -f name=${ALDM_PIPELINE_CONTAINER_NAME} -q`; do  #running
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${ALDM_PIPELINE_CONTAINER_NAME} was removed"; 
    done
    sleep 3;

     $DOCKER run \
        $docker_opts \
	--volume=/dce/tmp:/tmp:rw \
	--volume=/dce/DB2:/DB2:rw \
	--volume=/dce/source:/DCESOURCE:rw \
        --volume=/dce/target/data/reports:/reports:rw \
        --add-host=DCE_DB_HOST:${MARIADB_CONTAINER_IP} \
        --add-host=DB2-HOST:${DB2SERVER_CONTAINER_IP} \
        --name ${ALDM_PIPELINE_CONTAINER_NAME} \
         -h ${ALDM_PIPELINE_HOSTNAME}${ALDM_HOST_DOMAINNAME} \
        --network=dce --ip=${ALDM_PIPELINE_CONTAINER_IP} \
        -it -d $ImageName
        #-it -d aldm-pipeline-image  
        #--network=dce --ip=${ALDM_PIPELINE_CONTAINER_IP}  -p 1837:1837 \
         $DOCKER exec -it aldm-pipeline-container sh -c "/aldm_init.sh time"
         sleep 6;
         echo "Updating ALDM database" 
         update_database ${ALDM_PIPELINE_CONTAINER_NAME} create
}

start_aldm_webui() {
PORT=$1: shift
docker_opts="$@"

    [ "$($DOCKER image ls | grep aldm-webui-${BASE:="image"})" ] || return 1
    ImageName="$($DOCKER image ls | grep aldm-webui-${BASE:="image"}|awk '{printf("%s:%s", $1,$2)}')" 
    if [ -z "$PORT" ] ; then
          PORTSTRING="-p ${ALDM_PORTAL_PORT1}:${ALDM_WEBUI_PORT3}" 
##          PORTSTRING="$PORTSTRING ${ALDM_PORTAL_PORT2}:${ALDM_WEBUI_PORT4}" 
        PORTS="${ALDM_PORTAL_PORT1} " #${ALDM_PORTAL_PORT2}"
    else
        if [ "$PORT" -eq ${ALDM_PORTAL_PORT1} ] ; then
          PORTSTRING="-p ${ALDM_PORTAL_PORT1}:${ALDM_WEBUI_PORT3}" 
        elif [ "$PORT" -eq ${ALDM_PORTAL_PORT2} ] ; then
          PORTSTRING="-p ${ALDM_PORTAL_PORT2}:${ALDM_WEBUI_PORT4}" 
	else
  	  PORTSTRING="-p ${PORT}:${PORT}" #not currenlty an option 
    	fi
    fi
    printf "Checking for Running  Derby container\n" 
    printf "Waiting "
    wait_for_service 1527
    printf "\n"
    printf "Running ALDM WebUI in network 'dce'… on port(s): $PORTS $PORT\n"

    # Just in case remove any running containers with the same name
    for di in `$DOCKER ps -f name=${ALDM_WEBUI_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${ALDM_WEBUI_CONTAINER_NAME} was removed"; 
    done
    $DOCKER run \
        $docker_opts \
        --volume=/dce/tmp:/tmp:rw \
        --volume=/dce:/dce:rw  \
        --add-host=POSTGRES-HOST:${POSTGRES_CONTAINER_IP} \
        --add-host=ALDM-HOST:${ALDM_PIPELINE_CONTAINER_IP} \
        --add-host=DCE_DB_HOST:${MARIADB_CONTAINER_IP} \ 
	--name ${ALDM_WEBUI_CONTAINER_NAME} \
         -h ${ALDM_WEBUI_HOSTNAME}${ALDM_HOST_DOMAINNAME} \
 	--network=dce --ip=${ALDM_WEBUI_CONTAINER_IP} ${PORTSTRING} \
	-it -d $ImageName
    check_ports ${ALDM_WEBUI_PORT3} ${ALDM_WEBUI_PORT4}
}

start_aldm_portal() {
PORT=$1: shift
docker_opts="$@"

    [ "$($DOCKER image ls | grep aldm-portal-${BASE:="image"})" ] || return 1
    ImageName="$($DOCKER image ls | grep aldm-portal-${BASE:="image"}|awk '{printf("%s:%s", $1,$2)}')" 
    if [ -z "$PORT" ] ; then
  	PORTSTRING="-p ${ALDM_PORTAL_PORT1}:${ALDM_PORTAL_PORT3}  -p ${ALDM_PORTAL_PORT2}:${ALDM_PORTAL_PORT4}"
        PORTS="${ALDM_PORTAL_PORT1} ${ALDM_PORTAL_PORT2}"
        #[ -n "$PORT" ] && PORTSTRING="${PORTSTRING} -p ${PORT}:${PORT}"
    else
        if [ "$PORT" -eq ${ALDM_PORTAL_PORT1} ] ; then
          PORTSTRING="-p ${ALDM_PORTAL_PORT1}:${ALDM_PORTAL_PORT3}" 
        elif [ "$PORT" -eq ${ALDM_PORTAL_PORT2} ] ; then
          PORTSTRING="-p ${ALDM_PORTAL_PORT2}:${ALDM_PORTAL_PORT4}" 
	else
  	  PORTSTRING="-p ${PORT}:${PORT}" #not currenlty an option outised of 1835/1836
    	fi
    fi

    printf "Checking for Running  Derby container\n" 
    printf "Waiting "
    wait_for_service 1527
    printf "\n"
    printf "Running ALDM Portal in network 'dce'… on port(s): $PORTS $PORT\n"


    # Just in case remove any running containers with the same name
    for di in `$DOCKER ps -f name=${ALDM_PORTAL_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${ALDM_PORTAL_CONTAINER_NAME} was removed"; 
    done
    $DOCKER run \
        $docker_opts \
        --volume=/dce/tmp:/tmp:rw \
	--volume=/dce/DB2:/DB2:rw \
        --volume=/dce/target/data/reports:/reports:rw \
        --add-host=DERBY-HOST:${DERBY_CONTAINER_IP} \
        --add-host=ALDM-HOST:${ALDM_PIPELINE_CONTAINER_IP} \
	--name ${ALDM_PORTAL_CONTAINER_NAME} \
         -h ${ALDM_PORTAL_HOSTNAME}${ALDM_HOST_DOMAINNAME} \
 	--network=dce --ip=${ALDM_PORTAL_CONTAINER_IP} ${PORTSTRING} \
	-it -d $ImageName
	#-it -d aldm-portal-${BASE:="image"}

    ## have to adjust the webxml params post build
    #sleep 6;
    #echo "Updating TOMCAT configs"
    #docker exec -it ${ALDM_PORTAL_CONTAINER_NAME} sh -c "cd /opt/IBM/ALDM/tomcat; ./tomcat_container_install.sh UPDATE"

    #may have to adjust iptables if port1 != port2
    check_ports ${ALDM_PORTAL_PORT3} ${ALDM_PORTAL_PORT4}

}
check_ports(){
myPort3=$1
myPort4=$2
    set +e
    if [ -z "$PORT" ] || [ "$PORT" -eq ${ALDM_PORTAL_PORT1} ] ; then
    	RULE80='INPUT -p tcp -m tcp --dport 80 -j ACCEPT'
    	[ ${ALDM_PORTAL_PORT1} -ne ${myPort3} ] && printf "Checking port 80 " &&  iptables -C $RULE80 || iptables  -A $RULE80
    fi
    if [ -z "$PORT" ] || [ "$PORT" -eq ${ALDM_PORTAL_PORT2} ] ; then
    	RULE443='INPUT -p tcp -m tcp --dport 443 -j ACCEPT'
    	[ ${ALDM_PORTAL_PORT2} -ne ${myPort4} ] && printf "Checking port 443 " && iptables -C $RULE443 || iptables -A $RULE443
    fi
    printf "\n"
    set -e
}

start_postgresdb() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep postgres-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep postgres-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running postgres in network 'dce'…\n"
      for di in `$DOCKER ps -f name=${POSTGRES_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${POSTGRES_CONTAINER_NAME} was removed"; 
      done

      $DOCKER run \
        $docker_opts \
        --name ${POSTGRES_CONTAINER_NAME} -e DBNAME=aldm \
        --network=dce --ip=${POSTGRES_CONTAINER_IP} \
        --volume=/dce/dbs:/dbs:rw \
        -it -d $ImageName

        printf "Waiting "
        #wait_for_service 5432
        printf "\n"
        echo "Updating postgres data "
        $DOCKER exec -it ${POSTGRES_CONTAINER_IP} sh -c "echo INIT"
}

start_derbydb() {
docker_opts="$@"

   #https://github.com/aditosoftware/docker-derby/blob/master/README.md
    [ "$($DOCKER image ls | grep derby-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep derby-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running derby in network 'dce'…\n"
      for di in `$DOCKER ps -f name=${DERBY_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${DERBY_CONTAINER_NAME} was removed"; 
      done

       #/dce/dbs should be private use  :z,rw option or Z.rw for private
       #echo " $DOCKER run $docker_opts --volume=/dce/dbs:/dbs:rw --name ${DERBY_CONTAINER_NAME} -e DBNAME=aldm.derby --network=dce --ip=${DERBY_CONTAINER_IP} -p 1527:1527 -it -d $ImageName " #debug
      
      $DOCKER run \
        $docker_opts \
        --volume=/dce/dbs:/dbs:rw \
        --name ${DERBY_CONTAINER_NAME} -e DBNAME=aldm.derby \
        --network=dce --ip=${DERBY_CONTAINER_IP} -p 1527:1527 \
        -it -d $ImageName
        #-it -d derby-image

        printf "Waiting "
        wait_for_service 1527
        printf "\n"
        echo "Updating derby data "
        $DOCKER exec -it ${DERBY_CONTAINER_NAME} sh -c "/opt/IBM/ALDM/derby/derby_container_install.sh INIT"
}

start_browser() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep browser-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep browser-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running browser in host network \n"
      for di in `$DOCKER ps -f name=${BROWSER_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${BROWSER_CONTAINER_NAME} was removed"; 
      done
      $DOCKER run \
        $docker_opts \
        --add-host=portal${ALDM_HOST_DOMAINNAME}:172.18.0.1 \
        --name ${BROWSER_CONTAINER_NAME} \
        --network=dce --ip=${BROWSER_CONTAINER_IP} -p 5901:5900 \
        -it -d $ImageName
}

## ALDM2.0 couchdb,ui,api START ----------------------------------
start_couchdb() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep couch-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep couch-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running couchdb in network 'dce'…\n"
      for di in `$DOCKER ps -f name=${COUCHDB_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${COUCHDB_CONTAINER_NAME} was removed"; 
      done
      $DOCKER run \
        $docker_opts \
        --name ${COUCHDB_CONTAINER_NAME} -e  \
        --network=dce --ip=${COUCHDB_CONTAINER_IP} -p 5984:5984 \
        -it -d $ImageName
        printf "\n"
}

start_aldm_ui() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep aldm-ui-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep aldm-ui-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running aldm-ui in network 'dce'…\n"
      for di in `$DOCKER ps -f name=${ALDM_UI_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${ALDM_UI_CONTAINER_NAME} was removed"; 
      done
      $DOCKER run \
        $docker_opts \
        --name ${ALDM_UI_CONTAINER_NAME} -e  \
        --network=dce --ip=${ALDM_UI_CONTAINER_IP} -p 443:9999 \
        -it -d $ImageName
        printf "\n"
}

start_aldm_api() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep aldm-api-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep aldm-api-image|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running aldm-api in network 'dce'…\n"
      for di in `$DOCKER ps -f name=${ALDM_API_CONTAINER_NAME} -a -q`; do 
         $DOCKER rm -f ${di} && echo "Container  $di tagged as  ${ALDM_API_CONTAINER_NAME} was removed"; 
      done
      $DOCKER run \
        $docker_opts \
        --name ${ALDM_API_CONTAINER_NAME} -e \
        --network=dce --ip=${ALDM_API_CONTAINER_IP} -p 9443:9443 \
        -it -d $ImageName
        printf "\n"
}


## ALDM2.0 couchdb,ui,api END ---------------------------------- 
## AA - research - BEGIN
start_redis() {
docker_opts="$@"

    # If a Redis container already exists, start it; if it does not exist, run it
    if [ "$($DOCKER ps -a | grep redis-container)" ]; then
        printf "Starting Redis in network 'dce'…\n"
        $DOCKER start redis-container
        printf "\n"
    else
 
      [ "$($DOCKER image ls | grep redis)" ] || load_redis || return 1
      ImageName="$($DOCKER image ls | grep redis|awk '{printf("%s:%s", $1,$2)}')" 
      printf "Running Redis in network 'dce'…\n"
      $DOCKER run \
        $docker_opts \
        --name ${REDIS_CONTAINER_NAME} \
        --network=dce --ip=${REDIS_CONTAINER_IP} -p 127.0.0.1:6379:6379 \
        -it -d $ImageName
        #-it -d ${DOCKERLOCAL}redis:alpine
        printf "\n"
    fi
}

start_dce_pipeline() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep dce-pipeline-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep dce-pipeline-image|awk '{printf("%s:%s", $1,$2)}')" 
    printf "Running DCE Pipeline in network 'dce'…\n"

    # Just in case remove any running containers with the same name
    for di in `$DOCKER ps -f name=${DCE_PIPELINE_CONTAINER_NAME} -a -q`; do $DOCKER rm -f ${di}; done

      $DOCKER run \
        $docker_opts \
        --volume=/dce:/dce:rw --add-host=DCE_DB_HOST:${MARIADB_CONTAINER_IP} --name ${DCE_PIPELINE_CONTAINER_NAME} \
        --network=dce --ip=${DCE_PIPELINE_CONTAINER_IP} -p 9090:9090 \
        -it -d $ImageName

    printf "\n"
}

start_graphql_server() {
docker_opts="$@"

    [ "$($DOCKER image ls | grep dce-graphql-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep dce-graphql-image|awk '{printf("%s:%s", $1,$2)}')" 
    printf "Running DCE GraphQL server in network 'dce'…\n"

    # Just in case remove any running containers with the same name
    for di in `$DOCKER ps -f name=${DCE_GRAPHQL_CONTAINER_NAME} -a -q`; do $DOCKER rm -f ${di}; done

      $DOCKER run \
        $docker_opts \
    	--volume=/dce:/dce:rw \
    	--add-host=DCE_DB_HOST:${MARIADB_CONTAINER_IP} \
    	--add-host=DCE_REDIS_HOST:${REDIS_CONTAINER_IP} \
    	--name ${DCE_GRAPHQL_CONTAINER_NAME} \
    	--network=dce --ip=${DCE_GRAPHQL_CONTAINER_IP} -p 8080:8080 \
        -it -d $ImageName
    printf "\n"
    set +e ; interface_firewall eth1 8080 ; set -e
}

interface_firewall() {
[ $IBM -eq 1 ] &&  [ $EDST -eq 1 ] || return
##do this before $DOCKER in SL
interface=$1
FWPORT=$2

#temp disable error fault
set +e 
    printf "Adjusting local firewall rules for interface: $interface \n"
    #ports="88 8080"
    ports="88 488 8080"
    for port in $ports; do
      [ "$port" = $FWPORT ] || [ "$FWPORT" = "ALL" ] || continue
      rule="DOCKER-USER -i ${interface:="eth1"} -p tcp --dport $port -j DROP"
      (iptables -C $rule 2>/dev/null) ||  iptables -I $rule
    done 
    iptables --numeric -t filter -L DOCKER-USER
    printf "\n"
set -e
}

start_dce_web_app() {
PORT=$1; shift
SPORT=$1; shift
docker_opts="$@"

    [ "$($DOCKER image ls | grep dce-webapp-image)" ] || return 1
    ImageName="$($DOCKER image ls | grep dce-webapp-image|awk '{printf("%s:%s", $1,$2)}')" 
    printf "Running DCE web app in network 'dce'… on port:  ${PORT:=88}\n"
    printf "Running Secure DCE web app in network 'dce'… on port:  ${SPORT:=488}\n"

    # Just in case remove any running containers with the same name
    for di in `$DOCKER ps -f name=${DCE_WEBAPP_CONTAINER_NAME} -a -q`; do $DOCKER rm -f ${di}; done

      $DOCKER run \
        $docker_opts \
    	--volume=/dce:/dce:rw \
    	--add-host=DCE_DB_HOST:${MARIADB_CONTAINER_IP} \
    	--name ${DCE_WEBAPP_CONTAINER_NAME} \
    	--network=dce --ip=${DCE_WEBAPP_CONTAINER_IP} -p ${PORT:=88}:80 -p ${SPORT:=488}:443 \
        -it -d $ImageName
    	#--network=dce --ip=${DCE_WEBAPP_CONTAINER_IP} -p ${PORT:=88}:80  \

    printf "\n"
    set +e ; interface_firewall eth1 $PORT ; set -e
}

start_mariadb() {
myDBNAME=$1;shift
docker_opts="$@"
NEEDRESTART=0

    #--bind-address=0.0.0.0
    # If a MariaDB container already exists, start it; if it does not exist, run it
       ## dont remove this one it may be bust with another consumer
    if [ "$($DOCKER ps -a | grep mariadb-container)" ]; then
        printf "Starting MariaDB v${MARIADBVER} in network 'dce'…\n"
        $DOCKER start mariadb-container
        printf "\n"
    else
        USEDBIMAGE=$($DOCKER images |grep "mariadb[/]*.*${MARIADBVER} "|awk '{printf("%s:%s", $1,v)}' v=${MARIADBVER})
        [ "$($DOCKER image ls | grep mariadb)" ] || load_mariadb || return 1

        printf "Running MariaDB v${MARIADBVER} in network 'dce'…\n"
        rm -f /dce/tmp/config.sh
        #USEDBIMAGE="mariadb/server:${MARIADBVER}"
       #podman run --security-opt=no-new-privileges --security-opt=label=disable --privileged=false --volume=/dce/target/data/reports:/reports:rw --volume=/dce/mysql:/var/lib/mysql:rw --volume=/dce/tmp:/tmp:rw --name mariadb-container -e MYSQL_ROOT_PASSWORD=mypass --network=dce --ip=172.18.0.10 -p 127.0.0.1:3306:3306 -it -d localhost/mariadb/server:10.4

       #/dce/mysql should be private use  :z,rw option or Z.rw for private
       $DOCKER run \
        $docker_opts \
        --volume=/dce/tmp:/tmp:rw \
        --volume=/dce/mysql:/var/lib/mysql:rw \
        --volume=/dce/target/data/reports:/reports:rw \
        --name ${MARIADB_CONTAINER_NAME} -e MYSQL_ROOT_PASSWORD=mypass \
        --network=dce --ip=${MARIADB_CONTAINER_IP} -p 127.0.0.1:3306:3306 \
        -it -d $USEDBIMAGE
        #--volume=/dce/initdb.d:/docker-entrypoint-initdb.d:ro \
        #-it -d mariadb #mariad latest 10.4
        # Wait for MariaDB to start up, then set global variables
        #this method does not wrk between containers, only from the $DOCKER host
        printf "Waiting "
        if [ "$ARG3" = "nowait" ];then
           printf " 8 seconds"
           sleep 8
        else
           wait_for_service 3306
        fi
        printf "\n"
        configure_mariadb $myDBNAME || echo "configuration of MariaDB failed"
    fi

    # Wait for MariaDB to start up, then make db if necessary
    printf "Waiting for MariaDB v${MARIADBVER} "
    if [ "$ARG3" = "nowait" ];then
      printf " 8 seconds"
      sleep 8
    else
      wait_for_service 3306
    fi
    printf "\n"
    make_db $myDBNAME && echo "$myDBNAME database built or located successfully"
    show_mariadb
    if [ $NEEDRESTART -eq 1 ]; then
         printf "Restarting ... "
	 $DOCKER container stop ${MARIADB_CONTAINER_NAME} && sleep 2
	 $DOCKER start ${MARIADB_CONTAINER_NAME}
         printf "Waiting for MariaDB again"
         if [ "$ARG3" = "nowait" ];then
           printf " 24 seconds"
           sleep 24
         else
           wait_for_service 3306
         fi
         printf "\n"
         show_mariadb
    fi 
}

make_db(){
myDBNAME=$1
MAKE_DB=0
      curl --output /dev/null --silent --head --fail  127.0.0.1:3306 ; res=$?
      if [ $res -eq 0 ] || [ $res -eq 8 ] || [ "$ARG3" = "nowait" ]; then
        echo "Looking for db $myDBNAME"
        echo $($DOCKER exec -it mariadb-container mysql -u root -pmypass -qs -N -e  'show databases;')|grep -q $myDBNAME && echo "Found it" && return
        echo "Didn't find it ... will try to build"
        if [ "$myDBNAME" == "aldm" ] ;then
          $DOCKER exec -it mariadb-container sh -c \
             "mysql -h localhost -e 'CREATE DATABASE IF NOT EXISTS aldm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' -u root -pmypass" ||\
              echo "Unable to create db $myDBNAME"
        elif [ "$myDBNAME" == "dcedb" ] ;then
              echo "Skipping create db $myDBNAME ; will complete during processing"
        else
           echo "Warn! Can not build db $myDBNAME"
        fi
      else
        echo "error: database not listening, unable to check or build $myDBNAME"
        return 1
      fi 
}

upgrade_mariadb() {
#https://mariadb.com/kb/en/library/mysql_upgrade/
        echo "Checking for upgrade needs "
         MAJOR=$($DOCKER inspect $($DOCKER images|awk ' $1 ~ /mariadb/ {print $3}')  --format='{{ .Config.Env}}'|awk -F= '{split($NF,a,".");printf("%d%d%d",a[1],a[2],a[3])}')
        echo "MAJOR=$MAJOR"
        if [ $MAJOR -ge 103 ];then
         printf "Upgrading MariaDB"
         for d in $(ls -1F /dce/mysql|grep '/'|sed -e 's/.$//') ;do
	   $DOCKER exec -it ${MARIADB_CONTAINER_NAME} sh -c "mysqlcheck --no-defaults --check-upgrade --auto-repair --databases $d -pmypass"
         done
	 $DOCKER exec -it ${MARIADB_CONTAINER_NAME} mysql_upgrade -uroot -pmypass 
         printf "\n\n"
        else
         echo " No need for upgrade"
        fi
}

drop_mariadb() {
   case $1 in
     ALDM) DBS="aldm" ;;
     DCE) DBS="dcedb" ;;
     *) DBS="aldm dcedb" ;;
   esac

   echo "dropping databases: $DBS"
   c="mariadb-container" 
   for db in $DBS; do
    if [ -n "$($DOCKER ps -f name=$c -a -q)" ]; then  
       echo $($DOCKER exec -it $c mysql -u root -pmypass -qs -N -e  'show databases;')|grep -q $db || continue
         $DOCKER exec -it $c /bin/bash -c "mysql -sN -uroot -pmypass -e 'DROP DATABASE $db;'"
    fi
   done
}

show_mariadb() {
    printf "Config info MariaDB: "
    for C in max_connections innodb_buffer_pool_size innodb_log_file_size innodb_log_files_in_group log_error innodb_log_buffer_size innodb_file_per_table innodb_open_files innodb_io_capacity innodb_flush_method max_allowed_packet sort_buffer_size bulk_insert_buffer_size tmp_table_size max_heap_table_size skip-name-resolve query_cache_limit query_cache_size slow_query_log slow_query_log_file; do
      CMDS="$CMDS show variables LIKE '$C' ;" 
    done
    $DOCKER exec -it $MARIADB_CONTAINER_NAME mysql -uroot -pmypass -sNe 'SELECT VERSION();'
    $DOCKER exec -it $MARIADB_CONTAINER_NAME mysql -uroot -pmypass -sNe "$CMDS"
}

configure_mariadb() {
myDBNAME=$1
    # https://mariadb.com/kb/en/library/mariadb-memory-allocation/

    printf "Configuring MariaDB"
    $DOCKER exec -d mariadb-container chown mysql:mysql /reports
    
    [ -f /dce/tmp/config.sh ] || [ -x /opt/IBM/ALDM/system/deploy-config.sh ] && sh /opt/IBM/ALDM/system/deploy-config.sh 
    $DOCKER exec -d mariadb-container /bin/sh -c "[ -x /tmp/config.sh ] && /tmp/config.sh" || return 1
    NEEDRESTART=1
    printf "\n\n" 
    return
}

version_all() {
c=$1
stat=$2

: ${c:="ALDM"}
[ $stat -eq $stat ] 2>/dev/null && stat="" #remove numerics

$DOCKER container ls >/tmp/containers.lst
if [ "$c" = "ALL" ] || [ "$c" = "ALDM" ] || [ "$c" = "DCE" ]  ;then
   echo "versioning bundles: "
   [ -f /opt/IBM/ALDM/ALDMVERSION ] && echo " ALDM: $(cat /opt/IBM/ALDM/ALDMVERSION)"
   [ -f /opt/IBM/ALDM/DCEVERSION ] && echo " DCE: $(cat /opt/IBM/ALDM/DCEVERSION)"
   [ -f /opt/IBM/ALDM/system/aldm-start.sh ] && echo " start/execute scripts: $(/opt/IBM/ALDM/system/aldm-start.sh -version)"
   [ -f /opt/IBM/ALDM/system/instance_install.sh ] && echo " IBM ALDM 2.0 Cloud Installer: $(/opt/IBM/ALDM/system/instance_install.sh -v)"
   echo "versioning containers: "
   [ "$c" = "ALL" ] && list="$ALIST $DLIST"
   [ "$c" = "ALDM" ] &&  list=$ALIST
   [ "$c" = "DCE" ] &&  list=$DLIST
   for c in $MARIADB_CONTAINER_NAME $list; do
        version=$(version_all $c)
        [ "$version" = "<no value>" ] && [ "$c" != "$REDIS_CONTAINER_NAME" ] && version=$($DOCKER exec -it $c cat VERSION 2>/dev/null )
        $DOCKER container ls -a|grep $c >/dev/null 2>&1 && printf " %s: %s\n" $c "$version"
   done
   echo "versioning images: "
   for c in $MARIADB_CONTAINER_NAME $list; do
       i=$(echo $c|sed -e 's/-container/-image/')
       s=$(echo $i|sed -e 's/-image//')
       x=$(awk '{if($NF==c) print $2}' c=$c /tmp/containers.lst)
       version=$($DOCKER inspect --format '{{.Config.Labels.VERSION}}' $i 2>/dev/null || echo '')
       [ "$version" = "<no value>" ] && version=$($DOCKER inspect --format '{{.Config.Labels.version}}' $i 2>/dev/null || echo '')
       [  -z "$version"  ] && version=$($DOCKER inspect --format '{{.Config.Labels.version}}' $x 2>/dev/null || echo '')
       manifest=$($DOCKER inspect --format '{{.ManifestType}}' $i 2>/dev/null || echo '')
       [  -z "$manifest"  ] && manifest=$($DOCKER inspect --format '{{.ManifestType}}' $x 2>/dev/null || echo '')
       for d in $($DOCKER images |awk '{if (NR>1) print $1}');do
        #if ( echo $d |grep "\($i\|${x%:*}\|$s\)" >/dev/null 2>&1 ); then
        if ( echo $d |grep "$s" >/dev/null 2>&1 ); then
	  t=$($DOCKER images |awk '{if ($1==d) print $2}' d=$d)
	  [  -z "$version"  ] &&\
	     version=$($DOCKER inspect --format '{{.Config.Labels.version}}' $d 2>/dev/null || echo '') &&\
	     manifest=$($DOCKER inspect --format '{{.ManifestType}}' $d 2>/dev/null || echo '')
	  [  -z "$version"  ] && version=$t
        fi 
       done
       printf " %s: %s type:%s\n" $i "$version" "$manifest"
   done
else
   (echo $c |grep -q 'container')|| c="$c-container"
   if [ "$($DOCKER container ls -a|awk '$NF == c {print "true"}' c=$c)" = "true" ];then
    version="$($DOCKER inspect --format '{{.Config.Labels.VERSION}}' $c 2>/dev/null || echo '')"
    [ "$version" = "<no value>" ] && version=$($DOCKER inspect --format '{{.Config.Labels.version}}' $c 2>/dev/null || echo '')

    if [ "$c" == "$MARIADB_CONTAINER_NAME" ] ;then
      if [ $($DOCKER inspect -f '{{.State.Running}}' $c) = "true" ]; then
        v1="Release:" 
        s1="$($DOCKER exec -it $c mysql -sN -uroot -pmypass -e 'SELECT VERSION();')"
      fi
        [ "$DOCKER" == "docker" ] && version="$(docker inspect -f '{{ index ( .Config.Env) 0 }}' $c 2>/dev/null || echo '')"
        [ "$DOCKER" == "podman" ] && version="$(podman inspect -f '{{ index ( .Config.Env) 4 }}' $c 2>/dev/null || echo '')"
        version="$version $(printf "%s%s" "$v1" "$s1")"
    fi

    if [ "$c" == "$ALDM_PIPELINE_CONTAINER_NAME" ] ;then
      if [ $($DOCKER inspect -f '{{.State.Running}}' $c) = "true" ]; then
        v1="Release:" 
        r2="$($DOCKER exec -it $c awk ' $3 ~ /Revision:/ {printf("rel2=%s", $4)}' /ALDM/GA2F/RELEASE2.txt)"
        r3="$($DOCKER exec -it $c awk ' $3 ~ /Revision:/ {printf("rel3=%s", $4)}' /ALDM/GA2F/RELEASE3.txt)"
        e1="$($DOCKER exec -it $c /aldm_init.sh expire)"
        l1="$($DOCKER exec -it $c ls -l /ALDM/lic.key 2>/dev/null| awk '$5 ~ /[[:digit:]]/ {printf("lic_cdate=%s %s %s", $6,$7,$8)}')"
	p1="$($DOCKER exec -it $c perl -e 'use Config;my $parname2 = sprintf("%s-%s-%s-%s",(splice(@{[ split /\./,$Config{'osvers'}]},-2,1))[0],(split /-/,$Config{'archname'})[0],$Config{'version'},"aldm.par");print $parname2,$/;')"
      fi
        version="$version $(printf "%s%s %s" "$v1" "$r2" "$r3" ) $e1"
        [ "$stat" == "expire" ] && stat="" && version="$e1" 
        [ "$stat" == "par" ] && stat="" && version="$p1" 

    elif [ "$c" == "$DCE_PIPELINE_CONTAINER_NAME" ] ;then
        e1="$($DOCKER exec -it $c /dce_init.sh expire)"
        version="$version $e1"
    fi
   else
    version="Unknown"
   fi
   [ -z "$stat" ] && echo "$version"
fi
#rm -f /tmp/containers.lst
}

status_all() {
set +e
WHAT=$1
: "${WHAT:="ALDM"}" 

echo "statusing containers: "

if [ "${WHAT}" == "ALL" ] ; then
 list="$ALIST $DLIST"
elif [ "${WHAT}" == "ALDM" ] ; then
 list="$ALIST"
elif [ "${WHAT}" == "DCE" ] ; then
 list="$DLIST"
fi
for c in $MARIADB_CONTAINER_NAME $list; do
     if [ "$($DOCKER container ls -a|awk '$NF == c {print "true"}' c=$c)" = "true" ];then
        if [ "$c" == "$MARIADB_CONTAINER_NAME" ] || [ "$WHAT" != "ALDM" ] ;then
 	  status=$($DOCKER inspect --format '{{.State.Status}}' $c)
        else
 	  [ $major -eq 7 ] && status=$($DOCKER inspect --format '{{.State.Status}}+{{.State.Health.Status}}' $c)
 	  [ $major -ge 8 ] && status=$($DOCKER inspect --format '{{.State.Status}}+{{.State.Healthcheck.Status}}' $c)
        fi
     else
        status="NotFound"
     fi
     expire=" ";
     [ "$c" == "$ALDM_PIPELINE_CONTAINER_NAME" ] && expire="$(version_all $c 'expire' )"
     printf " %s:%s %s\n" $c $status "$expire" 
done
set -e
}


reset_all(){
WHAT=$1
: "${WHAT:="ALDM"}" 
 if [ "${WHAT}" == "ALL" ] || [ "${WHAT}" == "ALDM" ] ; then
  echo "Stoping the ALDM pipeline process and purging all temporary and permanent data"
  stop_all pause ${ALDM_PIPELINE_CONTAINER_NAME} 
  cd /dce/tmp && rm -fr $(ls -1 Project* 2>/dev/null|sed -e 's/^Project_\([^.]*\).csv/\1/') Project_*.csv aldm*.lck
  restart_all ALDM
  update_database ${ALDM_PIPELINE_CONTAINER_NAME} purge  
 fi
 if [ "${WHAT}" == "ALL" ] || [ "${WHAT}" == "DCE" ] ; then
  echo "Stoping the DCE pipeline process and purging all temporary and permanent data"
  stop_all pause ${DCE_PIPELINE_CONTAINER_NAME} 
  [ -f /root/dce-reset-data.sh ] && sh /root/dce-reset-data.sh
  restart_all DCE
 fi
}

restart_all(){
WHAT=$1
: "${WHAT:="ALDM"}" 
 echo "restarting containers: "
 if [ "${WHAT}" == "ALL" ] || [ "${WHAT}" == "ALDM" ] ; then
  for c in $MARIADB_CONTAINER_NAME $ALIST;do
    	[ -n "$($DOCKER ps -f name=$c -a -q)" ]  && [ -z "$($DOCKER ps -f name=$c -q)" ] &&  $DOCKER container start $c 
  done
 fi
 if [ "${WHAT}" == "ALL" ] || [ "${WHAT}" == "DCE" ] ; then
  for c in $MARIADB_CONTAINER_NAME $ALIST ; do
    	[ -n "$($DOCKER ps -f name=$c -a -q)" ]  && [ -z "$($DOCKER ps -f name=$c -q)" ] &&  $DOCKER container start $c 
  done
 fi
}

stop_all(){
ACTION=$1
WHAT=$2
DROPDB=1
 case $WHAT in
    ALDM) CLIST="$ALIST0 $ALIST1 $ALIST2"
          MYSQLDIRS="/dce/mysql/aldm" 
          ;;
    DCE) CLIST=$DLIST 
          MYSQLDIRS="/dce/mysql/dcedb" 
          SMASHDIRS="$SMASHDIRS /dce/target"
          ;;
    *DB) CLIST="$MARIADB_CONTAINER_NAME" 
          MYSQLDIRS="/dce/mysql/aldm /dce/mysql/dcedb" 
          SMASHDIRS="/dce/mysql"
          DROPDB=0
          ;;
    *) CLIST="$MARIADB_CONTAINER_NAME $ALIST0 $ALIST1 $ALIST2 $DLIST" 
          MYSQLDIRS="/dce/mysql/aldm /dce/mysql/dcedb" 
          SMASHDIRS="$SMASHDIRS /dce/target /dce/mysql"
          WHAT="ALL"
          ;;
 esac

 if  [ "$ACTION" == "nuke" ] ;then
        echo -n "You are about to nuke $WHAT containers, images and data. Proceed ? [y|N]:"; read nuke
        [ "$nuke" = "y" ] || [ "$nuke" = "Y" ] || exit
 	#drop db
 	[ $DROPDB -gt 0 ] && drop_mariadb $WHAT 
 
 	#rm containers 
 	stop_all rm $WHAT

 	echo "removing images"
  	for c in $CLIST;do
    		 i=$(echo $c|sed -e 's/container/image/') 
         	if ( $DOCKER images |grep "^$i " >/dev/null 2>&1 ); then
           		$DOCKER rmi $i
         	elif ( $DOCKER images |grep "^${i%-image}" >/dev/null 2>&1 ); then
           		ii=$($DOCKER images|grep "^${i%-image}"|awk '{print $3}')
           		$DOCKER rmi $ii
         	fi
                ([ "$WHAT" == "ALL" ] || [ "$WHAT" == "ALDM" ]) && [ -f $DOCKERDIR/aldm/${i}${XZ} ] && rm -f $DOCKERDIR/aldm/${i}${XZ}  
                ([ "$WHAT" == "ALL" ] || [ "$WHAT" == "DCE" ]) && [ -f $DOCKERDIR/dce/${i}${XZ} ] && rm -f $DOCKERDIR/dce/${i}${XZ}  
        done
        $DOCKER system prune -af
   
        echo  "remove data from directories " 
  	for c in $SMASHDIRS ; do rm -fr $c/* ;done
  	for c in $REMAKEDIRS ; do [ -d $c ] || mkdir -p $c ;done
        if [ "$WHAT" == "ALL" ];then
            echo "remove and remake required directories" 
  	    for c in $SMASHDIRS ; do rm -fr $c ;done
  	    for c in $SMASHDIRS $REMAKEDIRS ; do [ -d $c ] || mkdir -p $c ;done
            for f in $FRIENDS;do
                  [ -h $(dirname $0)/aldm-${f}.sh ] && rm -f $(dirname $0)/aldm-${f}.sh
            done
        fi
        chmod 1777 /dce/tmp; chmod 777 /dce/target/data/reports

 	return
 elif  [ "$ACTION" == "pause" ] ;then
   ACTION="stop"
   CLIST=$WHAT
 fi

 echo "${ACTION}ing containers: "
  
 for c in $CLIST;do
	if [ -n "$($DOCKER ps -f name=$c -a -q)" ]; then  
       		[ "$ACTION" == "rm" ] && [ -n "$($DOCKER ps -f name=$c -q)" ] &&  $DOCKER container stop $c 
     		$DOCKER container $ACTION $c
       	fi
 done
}

what_iguana() {
	if [ -n "$ARG3" ] && ( test $ARG3 -eq $ARG3 2>/dev/null ) ;then
    IGUANA=$ARG3
 else
   echo -n "Are you processing Iguana files? [y|N]:" ; read ans
   if [ "$ans" = "n" ] || [ "$ans" = "N" ] || [ -z "$ans" ]; then
           IGUANA=0
   else
           IGUANA=1
   fi
 fi
}

what_version() {
 if [ -n "$ARG2" ] && [ $ARG2 -eq $ARG2 ] && [ $ARG2 -le 2 ] && [ $ARG2 -gt 0 ];then
   ALDM_VER=$ARG2
 else
   echo -n "What version [1|2] default=1:"
   read ans
   [ -z "$ans" ] && ans=1
   ALDM_VER=$ans
 fi
}

start_what(){
 while [ -z $ans ];do
	echo -n "Start what?  ALDM|DCE|all  [${ans:-"ALDM"}]:"
	read ans
       [ -z $ans ] && ans='aldm'
        case $ans in
          DCE|dce) start_DCE 88 488 ;;
	  ALDM|aldm) what_version; what_iguana	   
  		     exec $0 ALDM ${ALDM_VER} ${IGUANA}
	      ;;

          ALL|all) start_all  ;;
          *) ans=""  ;;
        esac 
       #[ -z $ans ] || $DOCKER ps  
 done
}

start_all(){
  start_DCE 88 488 
  what_version; what_iguana	   
  start_ALDM ${ALDM_VER} 443 ${IGUANA}
}



load_mariadb() {
#https://docs.podman.io/en/latest/markdown/podman-pull.1.html
[ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/mariadb-image.xz
        echo "Attempting to load $DOCKERDIR/aldm/mariadb-image${XZ}"
	if [ -f $DOCKERDIR/aldm/mariadb-image${XZ} ]; then
	    $DOCKER load -i $DOCKERDIR/aldm/mariadb-image${XZ}
	elif [ -f $DOCKERDIR/dce/mariadb-image${XZ} ]; then
	    $DOCKER load -i $DOCKERDIR/dce/mariadb-image${XZ}
	elif ( $DOCKER pull "${DOCKERREPO}mariadb/server:${MARIADBVER}" ) ; then
            echo "loaded mariadb server version $MARIADBVER from $DOCKERREPO hub"
	elif ( $DOCKER pull "${DOCKERREPO}mariadb:${MARIADBVER}" ) ; then
            echo "loaded mariadb version $MARIADBVER from $DOCKERREPO hub"
        else
          return 1
        fi
}

load_redis() {
[ $major -ge 8 ] && conv_xz_files $DOCKERDIR/dce/redis-image.xz
        echo "Attempting to load $DOCKERDIR/dce/redis-image${XZ}"
	if [ -f $DOCKERDIR/dce/redis-image${XZ} ]; then
	    $DOCKER load -i $DOCKERDIR/dce/redis-image${XZ}
	elif ( $DOCKER pull "${DOCKERREPO}library/redis:alpine" ) ; then
            echo "loaded redis from $DOCKERREPO hub"
	else
          return 1
        fi
}

start_DCE(){
myWebPort=$1
myWebPort2=$2
#10	 11     13      12      14
#mariadb,redis,pipeline,graphql,web app
    # Start MariaDB container
echo "starting DCE containers: "
    # Start MariaDB container
    echo "========>>> Working on MARIADB <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep mariadb)" ]; then
        if ( ! load_mariadb ); then
            printf "ERROR: Could not find Docker image for MariaDB\n"
       	    exit 10
        fi
    fi
    echo "stand by: starting mariadb"; sleep 3
    start_container mariadb dcedb

    # Start redis container
    echo "========>>> Working on REDIS  <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep redis)" ]; then
        if ( ! load_redis ); then
            printf "ERROR: Could not find Docker image for redis\n"
            exit 11
        fi
    fi
    echo "stand by: starting redis"; sleep 3
    start_container redis

    # Start DCE Pipeline
    echo "========>>> Working on DCE-PIPELINE <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep dce-pipeline-image)" ]; then
        [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/dce/dce-pipeline-image.xz
	if [ -f $DOCKERDIR/dce/dce-pipeline-image${XZ} ]; then
    	    $DOCKER load -i $DOCKERDIR/dce/dce-pipeline-image${XZ}
            sleep 2 ; start_container dce_pipeline
        else
            echo "ERROR: Could not find Docker image for DCE Pipeline"
            exit 13
	fi
    else
        echo "stand by: starting dce pipeline"; sleep 3
        start_container dce_pipeline
        
    fi

    # Start GraphQL Server
    echo "========>>> Working on GRAPHQL  <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep dce-graphql-image)" ]; then
        [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/dce/dce-graphql-image.xz
	if [ -f $DOCKERDIR/dce/dce-graphql-image${XZ} ]; then
    	    $DOCKER load -i $DOCKERDIR/dce/dce-graphql-image${XZ}
            sleep 2 ; start_container dce_graphql_server
        else
            echo "ERROR: Could not find Docker image for DCE GraphQL Server"
            exit 12
	fi
    else
        echo "stand by: starting graphql server "; sleep 3
        start_container dce_graphql_server
    fi

    # Start Web APP 
    echo "========>>> Working on DCE-WEBAPP <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep dce-webapp-image)" ]; then
        [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/dce/dce-webapp-image.xz
	if [ -f $DOCKERDIR/dce/dce-webapp-image${XZ} ]; then
    	    $DOCKER load -i $DOCKERDIR/dce/dce-webapp-image${XZ}
            sleep 2 ; start_container dce_web_app ${myWebPort} ${myWebPort2}
        else
            echo "ERROR: Could not find Docker image for DCE WebApp Server"
            exit 14
	fi
    else
        echo "stand by: starting dce webapp server "; sleep 3
        start_container dce_web_app ${myWebPort} ${myWebPort2}
    fi
    echo "Getting container status" && sleep 30 && $DOCKER ps
}

start_ALDM() {
myALDM=$1
myWebPort=$2
IGUANA=$3

echo "starting ALDM v${myALDM}.0 containers: "
    # Start MariaDB container
    echo "========>>> Working on MARIADB <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep mariadb)" ]; then
        if ( ! load_mariadb ); then
            printf "ERROR: Could not find Docker image for MariaDB\n"
       	    exit 10
        fi
    fi
    echo "stand by: starting mariadb"; sleep 3
    start_container mariadb aldm

    # Start ALDM Pipeline
    echo "========>>> Working on ALDM-PIPELINE <<<=========="; sleep 1
    if [ ! "$($DOCKER image ls | grep aldm-pipeline-image)" ]; then
        [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/aldm-pipeline-image.xz
	if [ -f $DOCKERDIR/aldm/aldm-pipeline-image${XZ} ]; then
	    $DOCKER load -i $DOCKERDIR/aldm/aldm-pipeline-image${XZ}
            sleep 2 && start_container aldm_pipeline
  	else 
            echo "ERROR: Could not find Docker image for ALDM Pipeline"
            exit 9
	fi
    else
        echo "stand by: starting aldm pipeline"; sleep 3
        start_container aldm_pipeline
    fi
 
    if [ $myALDM -le 2 ] ; then
    	# Start derbydb container
    echo "========>>> Working on DERBY <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep derby-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/derby-image.xz
	    if [ -f $DOCKERDIR/aldm/derby-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/derby-image${XZ}
                sleep 2 && start_container derbydb
  	    else 
       	        printf "ERROR: Could not find Docker image for Derby \n"
       	        exit 7
            fi
    	else
       	 echo "stand by: starting derby"; sleep 3
       	 start_container derbydb
    	fi
    fi

    if [ $myALDM -le 2 ] && [ $IGUANA -gt 0 ]; then
    	# Start db2 container
    echo "========>>> Working on DB2 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep db2server-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/db2server-image.xz
	    if [ -f $DOCKERDIR/aldm/db2server-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/db2server-image${XZ}
                sleep 2 && start_container db2server
  	    else 
       	        printf "ERROR: Could not find Docker image for DB2 \n"
       	        exit 7
            fi
    	else
       	 echo "stand by: starting db2server"; sleep 3
       	 start_container db2server
    	fi
    fi

    if [ $myALDM -eq 1 ] ; then
    	# Start ALDM Portal container  
    echo "========>>> Working on ALDM-WEBPORTAL 1.0 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep aldm-portal-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/aldm-portal-image.xz
	    if [ -f $DOCKERDIR/aldm/aldm-portal-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/aldm-portal-image${XZ}
                sleep 2 && start_container aldm_portal $myWebPort
  	    else 
       	        printf "ERROR: Could not find Docker image for the ALDM portal\n"
       	 	exit 8
	    fi
    	else
       	 echo "stand by: starting aldm portal"; sleep 3
       	 start_container aldm_portal $myWebPort
    	fi
    elif [ $myALDM -eq 2 ] ; then
    echo "========>>> Working on ALDM-POSTGRES 2.0 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep postgres-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/postgres-image.xz
	    if [ -f $DOCKERDIR/aldm/postgres-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/postgres-image${XZ}
                sleep 2 && start_container postgresdb
  	    else 
       	        printf "ERROR: Could not find Docker image for the ALDM postgres \n"
       	 	exit 8
	    fi
    	else
       	 echo "stand by: starting postgres db"; sleep 3
       	 start_container postgresdb 
    	fi
    	# Start ALDM Webui container 
        myWebport=80 #https suppot not available for applcation yet force the port
    echo "========>>> Working on ALDM-WEBUI 2.0 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep aldm-webui-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/aldm-webui-image.xz
	    if [ -f $DOCKERDIR/aldm/aldm-webui-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/aldm-webui-image${XZ}
                sleep 2 && start_container aldm_webui 80 #$myWebPort
  	    else 
       	        printf "ERROR: Could not find Docker image for the ALDM portal\n"
       	 	exit 8
	    fi
    	else
       	 echo "stand by: starting aldm webui"; sleep 3
       	 start_container aldm_webui 80 #$myWebPort
    	fi
    elif [ $myALDM -eq 3 ] ; then
    	# Start couchdb container
    echo "========>>> Working on COUCHDB <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep couchdb-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/couchdb-image.xz
	    if [ -f $DOCKERDIR/aldm/couchdb-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/couchdb-image${XZ}
                sleep 2 && start_container couchdb
  	    else 
       	        printf "ERROR: Could not find Docker image for Couchdb \n"
       	        exit 7
            fi
    	else
       	 echo "stand by: starting couchdb"; sleep 3
       	 start_container couchdb
    	fi

    	# Start ALDM UI container 
    echo "========>>> Working on ALDM-UI 2.0 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep aldm-ui-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/aldm-ui-image.xz
	    if [ -f $DOCKERDIR/aldm/aldm-ui-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/aldm-ui-image${XZ}
                sleep 2 && start_container aldm_ui
  	    else 
       	 	printf "ERROR: Could not find Docker image for the ALDM UI\n"
       	 	exit 8
	    fi
    	else
       	 echo "stand by: starting aldm ui"; sleep 3
       	 start_container aldm_ui
    	fi

    	# Start ALDM API container 
    echo "========>>> Working on ALDM-API 2.0 <<<=========="; sleep 1
    	if [ ! "$($DOCKER image ls | grep aldm-api-image)" ]; then
            [ $major -ge 8 ] && conv_xz_files $DOCKERDIR/aldm/aldm-api-image.xz
	    if [ -f $DOCKERDIR/aldm/aldm-api-image${XZ} ]; then
	        $DOCKER load -i $DOCKERDIR/aldm/aldm-api-image${XZ}
                sleep 2 && start_container aldm_api
  	    else 
       	 	printf "ERROR: Could not find Docker image for the ALDM API\n"
       	 	exit 6
	    fi
    	else
       	 echo "stand by: starting aldm api"; sleep 3
       	 start_container aldm_api
    	fi
    fi #myALDM
    echo "Getting container status" && sleep 15 && $DOCKER ps
}

conv_xz_files() {
XZLIST=$1
[ -z "$XZLIST" ] &&  XZLIST="$(find $DOCKERDIR/aldm -type f -name "*.xz" -print) $(find $DOCKERDIR/dce -type f -name "*.xz" -print)"
        for n in $XZLIST; do
	   if [ ! -f $(echo $n|cut -d. -f1) ]; then
		printf "\rUnpacking %s                        " ${n##*/}
                xz -d $n
	   else
		echo "Warn: $(echo $n|cut -d. -f1) unpacked file exits .. nothing unpacked"
	   fi
        done
	printf "\r                                                        \n"
}

######################## MAIN #######################
# Check if Docker is installed, exit if it is not available
while getopts "hv" OPT; do
    case $OPT in
     h) usage ; exit ;;
     v) echo v$REVISION ; exit ;;
    esac
done

[ "$(uname -s)" == "Linux" ] || major=0 #MINGW64

#docker switch
 if [ $major -le 7 ] ;then  
	major=7
        DOCKERSRV=$(docker info 2>/dev/null |awk -F: '$1 ~ /Operating System/ {split($2,a," ");print a[2] }')
        DOCKER=docker
        DOCKERDIR=/var/lib/docker
	DOCKERSOCKET=$(get_docker_socket docker.socket)
	DOCKERPING="http://ping"
	XZ=".xz"
 elif [ $major -ge 8 ];then
        DOCKER=podman
        DOCKERDIR=/var/lib/containers/storage
	DOCKERSOCKET=$(get_docker_socket podman.socket)
	DOCKERPING="http://d/_ping"
	DOCKERREPO="docker.io/"
 elif [ $major -eq 22 ] && [ "$ID" = "ubuntu" ];then  #22.04 unbuntu
        DOCKER=podman
        #DOCKERDIR=/home/mtacci/.local/share/containers/storage
        DOCKERDIR=/var/lib/containers/storage
	DOCKERSOCKET=/mnt/wslg/runtime-dir/podman/podman.sock
	DOCKERSOCKET=$(get_docker_socket podman.socket)
	DOCKERPING="http://d/_ping"
	DOCKERREPO="docker.io/"
 fi

if hash $DOCKER 2>/dev/null; then
    # Check if the Docker daemon is running, exit if it is not
    is_docker_daemon_running || init_docker_daemon  
    is_docker_daemon_running || exit 1


      # Exit immediately if any command below fails
      set -e

      	if [ -n "$ARG1" ];then
        	case $ARG1 in 
		   aldm-webportal) ALIAS="aldm-portal" ;;
                   aldm-derby|derby*) ALIAS="derby" ;;
                   aldm-postgres|postgres*) ALIAS="postgres" ;;
		esac
      	fi

	if [ "$(basename $0)" == "aldm-start.sh" ]|| [ "$2" == "start" ]; then
            for f in $FRIENDS;do
                  [ -h $(dirname $0)/aldm-${f}.sh ] || ln -s $(dirname $0)/aldm-start.sh $(dirname $0)/aldm-${f}.sh
            done

            # Check if the 'dce' Docker network exists
            if [ ! "$($DOCKER network ls | grep dce)" ]; then
                printf "Creating network 'dce'…\n"
                $DOCKER network create --subnet=$DCE_NETWORK dce
                printf "\n"
            fi

	    [ "$DOCKERSRV" == "Desktop" ] && echo "WARNING: Docker Desktop not fully supported " && exit 2

            [ "$ARG2" = "nowait" ] && ARG3=$ARG2 && ARG2=""

            if [ -z "$ARG1" ];then
                start_what
            elif [ "$ARG1" == "ALDM" ];then
  		what_version; what_iguana	   
  		start_ALDM ${ALDM_VER} 443 ${IGUANA}
            elif [ "$ARG1" == "DCE" ];then
                start_DCE 88 488
            elif [ "$ARG1" == "ALL" ];then
                start_all 
            else
                    case $ARG1 in 
                     mariadb) start_container mariadb ${ARG2:-"aldm"} ;;
                     aldm-pipeline) start_container aldm_pipeline ;;
                     aldm-portal|aldm-webportal) start_container aldm_portal $ARG2 ;;
                     aldm-webui) start_container aldm_webui $ARG2 ;;
                     aldm-derby|derby*) start_container derbydb ;;
                     aldm-postgres|postgres*) start_container postgresdb ;;

                     aldm-ui) start_container aldm_ui ;;
                     aldm-api) start_container aldm_api ;;
                     couchdb) start_container couchdb ;;
                     aldm-db2|db2server) start_container db2server ;;

                     aldm-browser|browser*) start_container browser ;;

                     redis) start_container redis ;;
                     dce-pipeline) start_container dce_pipeline ;;
                     dce-graphql|graphql*) start_container dce_graphql_server ;;
                     dce-webapp) start_container dce_web_app $ARG2;;
                     *) usage ; exit 1;

                    esac
            fi
	elif [ "$(basename $0)" == "aldm-stop.sh" ] && [ -z "$ARG1" ]; then
		stop_all stop
	elif [ "$(basename $0)" == "aldm-remove.sh" ] && [ -z "$ARG1" ]; then
		stop_all rm
	elif [ "$(basename $0)" == "aldm-restart.sh" ] && [ -z "$ARG1" ]; then
		restart_all 
	elif [ "$(basename $0)" == "aldm-status.sh" ]; then
		status_all $ARG1 
	elif [ "$(basename $0)" == "aldm-version.sh" ] ; then 
		version_all $ARG1 $ARG2
	elif [ "$(basename $0)" == "aldm-reset.sh" ] ; then 
		reset_all $ARG1
	elif [ "$(basename $0)" == "aldm-nuke.sh" ] ; then 
		stop_all nuke $ARG1 
    	elif [ -n "$ARG1" ];then
            if ([ "$(basename $0)" == "aldm-restart.sh" ] || [ "$ARG2" == "restart" ]) && ($DOCKER container ls -a|grep "$ARG1-container" >/dev/null 2>&1) ; then
                $DOCKER container start "$ARG1-container"
		if [ "$ARG1" = "mariadb" ];then 
                   $DOCKER inspect --format '{{.State.Status}}' "$ARG1-container" 
 	        else
                   $DOCKER inspect --format '{{.State.Status}}+{{.State.Health.Status}}' "$ARG1-container"
                fi
            else 
                case $ARG1 in
                     start) start_what;;
                     stop) stop_all stop ;;
                     remove) stop_all rm $ARG2 $ARG3  ;;
                     nuke) stop_all nuke $ARG2 ;;
                     reset) reset_all $ARG2 ;;
                     restart) restart_all $ARG2;;
                     status) status_all $ARG2 ;;
                     version) version_all $ARG2;;
                     upgradedb) upgrade_mariadb ;;
                     createdb) update_database ${ALDM_PIPELINE_CONTAINER_NAME} create  ;; #aldm
                     purgedb) update_database ${ALDM_PIPELINE_CONTAINER_NAME} purge $ARG2 ;; #history
                     dropdb) update_database ${MARIADB_CONTAINER_NAME} drop $ARG2 ;; #aldm|dce
                     backupdb) update_database ${MARIADB_CONTAINER_NAME} backup $ARG2 ;; #aldm|dce
                     *_mariadb) $ARG1 ;;
                     *help) usage ;;
                esac

                if [ "$(basename $0)" == "aldm-stop.sh" ] || [ "$(basename $0)" == "aldm-remove.sh" ] ;then 
                   if [ "$ARG1" = "ALL" ] || [ "$ARG1" = "ALDM" ] || [ "$ARG1" = "DCE" ]  ;then
                     [ "$(basename $0)" == "aldm-remove.sh" ] && stop_all rm $ARG1 ||  stop_all stop $ARG1
                   else   
                     $DOCKER container stop "${ALIAS:=$ARG1}-container"
                     [ "$(basename $0)" == "aldm-remove.sh" ] &&  $DOCKER container rm "${ALIAS:=$ARG1}-container"
                   fi
                fi
                
            fi 
     fi

else
    printf "'$DOCKER' command not found, exiting\n"
    exit 1
fi

### -mt
