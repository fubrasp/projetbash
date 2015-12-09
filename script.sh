#!/bin/bash

########VARIABLES DU SCRIPT########
fichier_conf_nom=""
FICHIER_CONF_DEFAUT="test2.txt"
FICHIER_SAUVEGARDE_CONFIG="save_CONF.txt"
########VARIABLES DU SCRIPT########

########################USAGE########################
#abscence d'arguments -> affichage de l'usage
if [ $# -eq 0 ]
then
    usage
fi
########################USAGE########################


#les fonctions doivent etre avant leurs appels
function installpackages(){
    #sudo apt-get install dialog
    #dnf install dialog
    #or yum install dialog
    echo "http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script" 
}

function confexample(){
    echo ""
    fichier_conf_example="conf_exemple.txt"
    echo "###un fichier type###"
    echo "#juste de dossier listes"
    echo "#debut du fichier de conf"
    echo "dossier1"
    echo "dossier2"
    echo "dossier3"
    echo "#fin du fichier de conf"
    printf "dossier1\ndossier2\ndossier3" > $fichier_conf_example
    echo "un exemple a ete cree dans $fichier_conf_example"
    echo ""
}

#lance que pour le backupdir ou le conf!!
function verifconf(){
    #nom du fichier de configuration passe en parametre de, apres --backupdir
    #argument qui n'est pas passe, cela veut dire qu'on peut faire la commande en 2 fois, passage par defaut
    if [ "$fichier_conf_nom" == "" ]
    then
    	fichier_conf_nom=$FICHIER_CONF_DEFAUT
    fi

    #test de l'existance du parametre passe
    if [ ! -e $(cat $FICHIER_SAUVEGARDE_CONFIG) ]; then
      echo "Fichier de conf n'existe pas!!"
      confexample
      exit 1
    fi
 
    #fichier vide
    if [ ! -s $(cat $FICHIER_SAUVEGARDE_CONFIG) ]
        then
            echo "Fichier de conf $FICHIER_SAUVEGARDE_CONFIG existant mais vide!!"
            confexample
	    exit 1
        else
            fichier_conf_nom=$(head -n 1 $FICHIER_SAUVEGARDE_CONFIG)        
    fi
}

function lire(){
    #on va dans le dossier de backup
    cd $2
    ls
    echo "regarder le dossier(gpg) que vous voulez lire, rentrez le"
    read dossier_voulu
    extension=".tar.gz"
    separateur="/"		
    #On decrypte l'archive a lire
    gpg $dossier_voulu
    #On fait un "basename" (on enleve les extension .tar.gz.gpg), un substring aurait ete plus propre..		
    a=$(echo "${dossier_voulu%%.*}")
    echo "ARG LIRE BASENAME $a"
    #On concatene l'extension tar gz		
    c=$a$extension
    #on decompresse
    tar zxfv $c
    cd $a
    echo "l'archive voulue contient"
    ls
    cd .. 
    #avec des dialog on peut faire naviguer le cas echeant
    exit 0 
}

function autosupressbackup(){
    #pour chaque dossier de backup on a un fichier les listant
    limite_nb_fichiers=5
    #limite_nb_fichiers=100
    nom=listedesbackup
    txt=".txt"
    filename=$2$nom$txt
    echo "$1" >> $filename
    #on compte le nombre de backups dans le bon dossier
    nb_fichiers=$(wc --words $filename  | cut -d ' ' -f1)
    echo "NOMBRE DE FICHIERS $nb_fichiers dans $2"
    if [ $nb_fichiers -eq $limite_nb_fichiers ]
    then
    backup_la_plus_ancienne=$(head -n 1 $filename)
    cd $2
    sudo rm -Rf $backup_la_plus_ancienne
    #doit supprime l'entree sur le fichier c'est a dire la premiere ligne du fichier
    sed -i '1d' $filename
    cd ..
    fi
}

#usage, explications 
function usage(){
    printf "Utilisation du script :\n"
    printf "\t--conf                   : lance le backup  \n"
    printf "\t--backupdir               :indique l'endroit a mettre le backup \n"
    printf "\t-h                       : affiche ce message.\n"
}

#fonction de backup
#creer un dossier pour les backup
#copier les dossiers mentionnes dans le fichier de configuration (prealablement edites)
function backup(){
#echo "BACKUP PASSAGE VERICONF $1 $3" 

verifconf $1 
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
	backup_name=$backup$current_hour
	#full_path=$backup$current_hour
	echo -e "Recuperation des dossiers de: $fichier_conf_nom \n"

files=$(cat  $fichier_conf_nom)
for line in $files
    do
	echo -e "copie de $line"
	#find /home -type d -name $line -print
	result=$(sudo find  -type d -name $line)
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
    done

    echo "le backup est dans :" $1 "est il est crypté"
    #Tar l'interieur du $1
    cd $1 
    tar cvzf $backup_name.tar.gz $backup_name
    crypte $backup_name.tar.gz
    rm -R -f $backup_name
    rm -f $backup_name.tar.gz
    cd ..
    autosupressbackup $backup_name.tar.gz.gpg $1
 }


#Recupere le parametre du dossier principale
function recup(){
   fichier_conf_nom=$1
   echo "$fichier_conf_nom" > save_CONF.txt
}

#On veut un seul tar.gz contenant toutes les backups
#Apres relecture de l'enonce
function tarTout(){
   #on va a l'endroit indique
   cd $1
   #nous avons seulement des dossiers de la forme backup_..
   #on tar et compresse d'un coup toutes les backup
   #Il va de soit que l'on a un seul mdp pour toutes les backups..
   #existense du fichier tar avant
   if [ ! -z "all_backups.tar" ]
   then
   tar -cvf all_backups.tar backup_*
   #on supprime les dossiers du d'origine
   rm -Rf backup_*
   else
   #on ajoute les dossiers au tar existant
   tar -rvf all_backups.tar backup_*
   rm -Rf backup_*
   fi
}

function compressGZ(){
#on va dans le dossier de backup
cd $1
#TO DO
}

#Fonction qui crypte le backup
function crypte(){
    #gpg-zip -c -o $1.gpg $1
    #il nous faut notre propre cle a la base
    #TO DO
    #on suit les etapes que gpg indique
    #on s'indique soi meme comme destinataire
    #le but est de voir si key contient rien il n'y a pas de cle
    key=$(gpg --list-keys)
    #if [ ! $key="" ]
    #then
    #fi
    #si on a pas de clef, sinon on fait rien
#NE FONCTIONNE PAS
    #test restrictif!!   
#    if [ ! -z ../.gnupg/pubring.gpg ]
#    then    
#	gpg --gen-key
    #fi
    echo $1
    gpg --encrypt $1
}

#ces 2 fonctions sont pour le diff entre 2 backups
function compareA(){
		a=$1
}

function compareB(){
		extension=".tar.gz"
		separateur="/"		
		echo $a
		b=$1
		echo $b
		#On decrypte les deux archives a comparer (diff)
		gpg $a
		gpg $b
		#On fait un "basename" (on enleve les extension .tar.gz.gpg), un substring aurait ete plus propre..		
		a=$(echo "${a%%.*}")
		b=$(echo "${b%%.*}")
		#On concatene l'extension tar gz, on recherche seulement a savoir si c'est different en terme de contenu		
		c=$a$extension
		d=$b$extension
		#on fait le diff
		diff $c $d
		#On supprime nos archives, a discuter
		rm -Rf $c
		rm -Rf $d		
		exit 0
}
#Cette partie gere les arguments et lance la bonne méthode
OPTS=$( getopt -o h -l conf:,backupdir:,compA:,compB,lire -- "$@" )
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
	--compA) compareA $2; shift 2;;
	--compB) compareB $3; shift 2;;
        --lire) lire $2 $3; shift 2;;
        --) shift; break;;
    esac
done

exit 0
