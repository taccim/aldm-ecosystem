#!/bin/bash

KEY=$1

if  [ $# -ge 1 ] ; then
 if [ "$KEY" = "kill" ]; then
 pkill ssh-agent && echo "agent killed";
 exit
 fi

 ssh-add -l
 if [ $? -eq 2 ] || [ "$KEY" = "force" ]  ; then
    echo "No agent running, starting one"
    eval "$(ssh-agent -s)" ## no agent running in shell , better start one
   [ "$KEY" = "force" ] &&  shift &&  KEY=$1
 fi

 if  [ $? -eq 1 ] || ( env|grep SSH_AGENT_PID >/dev/null 2>&1 ) ; then
        [ "$KEY" = "delete" ] && ssh-add -D && echo "removing all keys" && exit
        echo "KEY=$KEY"
	if (echo $KEY|grep "id_rsa"  >/dev/null 2>&1) ; then
            echo "adding identity associated with $KEY"
            ssh-add $KEY
            shift
        fi

	ssh-add -l 
        if  [ $? -eq 1 ] ; then
            echo "No identities in agent, adding one"
	    ssh-add  #has no identity so add the default key ~/.ssh/id_rsa #
        fi
 fi

else 
 echo "Nothing to do"
 echo "Usage: $(basename $0) [force] key_file "
 echo "                      [kill|delete] "
fi

