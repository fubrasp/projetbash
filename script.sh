#!/bin/bash

#CONSTANTES

#fichiers de confs
. ./test2.cfg
		
#a titre de test

#fichier_conf_nom=""

#IMPORTS
#on doit dabord utiliser la fonction aui partage ses variables avec le bash courant
importNoms
fich_conf_type2="${dossiers_de_sauvegarde[@]}"

function usage(){
    printf "Utilisation du script :\n"
    printf "\t--conf                   : lance le backup  \n"
    printf "\t--backupdir               :indique l'endroit a mettre le backup"
    printf "\t-h                       : affiche ce message.\n"
}
 

function recherche_copie(){
	backup="backup_"
	current_hour=$(date +%Y%H%M%S)
	separateur="/"
	full_path=$PWD$separateur$backup$current_hour

	for fichier in $@
	do
		result=$(find /home -name "$fichier")
		if [ -z $result ]
		then
			echo "$fichier n'existe pas"
		else
			echo "$fichier trouve:"
			echo $result
			#$full_path reste le meme dans la boucle!
			cp -R $fichier $full_path
		fi
	done
}




if [ $# -eq 0 ]
then
    usage
fi
 
function backup(){
    if [ -d "$1" ]
    then
	echo "dossier deja existant"
    else
	mkdir "$1"
    fi  
    echo "recupération des dossiers de $fichier_conf_nom"
#    while read line  
#    do   
#	echo -e " copie de $line"
	#find /home -type d -name $line -print
	#marche pas
#    done < $fichier_conf_nom
    
#    echo "le backup est dans :" $1
recherche_copie $fich_conf_type2 
}

function recup(){
   fichier_conf_nom=$1
}
OPTS=$( getopt -o h -l conf:,backupdir: -- "$@" )
if [ $? != 0 ]
then
    exit 1
fi
eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h) usage;
            exit 0;;
        --conf) recup $2; shift 2;;
	--backupdir) backup $2; shift 2;;
        --) shift; break;;
	
    esac
done
 
exit 0
