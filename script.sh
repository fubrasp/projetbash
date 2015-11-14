#!/bin/bash

#nom du fichier de configuration passe en parametre de, apres --backupdir
fichier_conf_nom=$3

#usage, explications 
function usage(){
    printf "Utilisation du script :\n"
    printf "\t--conf                   : lance le backup  \n"
    printf "\t--backupdir               :indique l'endroit a mettre le backup"
    printf "\t-h                       : affiche ce message.\n"
}
 
#abscence d'arguments -> affichage de l'usage
if [ $# -eq 0 ]
then
    usage
fi

#fonction de backup
#creer un dossier pour les backup
#copier les dossiers mentionnes dans le fichier de configuration (prealablement edites)
function backup(){
backup="backup_"
	current_hour=$(date +%Y%H%M%S)
	separateur="/"

    if [ -d "$1" ]
    then
	echo -e "\nDossier deja existant\n"
    else
	mkdir "$1"
    fi
	#chemin 
	#echo -e "full_path=$PWD$separateur$1$separateur$backup$current_hour \n" 
	#redirection ambigu si pas de param
	full_path=$PWD$separateur$1$separateur$backup$current_hour
	echo -e "Recuperation des dossiers de: $fichier_conf_nom \n"

while read line 
    do
	echo -e "copie de $line"
	#find /home -type d -name $line -print
	result=$(sudo find /home -type d -name $line)
	if [ -z $result ]
		then
			echo "$fichier n'existe pas"
		else
			echo "$fichier trouve:"
			echo $result
			#$full_path reste le meme dans la boucle!
			cp -avr "$line" "$full_path"
			
			echo -e "\nORIGINE: $line"
			echo -e "DESTINATION: $full_path"
		fi
    done < $fichier_conf_nom

    echo "le backup est dans :" $1
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
