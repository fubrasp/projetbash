#!/bin/bash

function usage(){
    printf "Utilisation du script :\n"
    printf "\t--conf                   : lance le backup  \n"
    printf "\t-h                       : affiche ce message.\n"
}
 
if [ $# -eq 0 ]
then
    usage
fi
 
function showHome(){
   echo "vous avez ecrit" $1
}
 
OPTS=$( getopt -o h -l conf: -- "$@" )
if [ $? != 0 ]
then
    exit 1
fi
eval set -- "$OPTS"
 
while true ; do
    case "$1" in
        -h) usage;
            exit 0;;
        --conf) showHome $2;
                shift 2;;
        --) shift; break;;
	
    esac
done
 
exit 0
