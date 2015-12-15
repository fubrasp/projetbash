#!/bin/bash

########VARIABLES DU SCRIPT########

#configuration de la limite pour la supression automatique de backups

#nom du fichier de configuration
#fichier de configuration par defaut le cas echeant
#fichier sauvegardant le choix de configuration effectues posterieurement
#fichier permettant de savoir si l'installation a deja ete realisee
#repertoire ou sont stockes les fichiers telecharges la fonction downfile

#url d'upload de backups 
#url de download de backups
#url de la page recapitulative des synopsys
#url de base du site

#extension .txt

#*********************CONFIG supression automatique***************************  
#mis a 5 pour les tests la valeur normale est de 100
LIMITE_NB_FICHIERS_AUTO_SUPPRESSION=5
#****************************CONFIG backup************************************
fichier_conf_nom=""
FICHIER_CONF_DEFAUT="test2.txt"
FICHIER_SAUVEGARDE_CONFIG="save_CONF.txt"
FICHIER_TEST_INSTALLATION="confBASHBACKUP.txt"
REPERTOIRE_FICHIERS_TELECHARGES="saved_files_directory"
#********************************URLs*****************************************
ADRESSE_BACKUP_SITE="https://daenerys.xplod.fr/backup/upload.php?login=bertrandcerfruez"
ADRESSE_DW_BACKUP_SITE="https://daenerys.xplod.fr/backup/download.php?login=bertrandcerfruez&hash="
PAGE_SYNOPS_SITE="https://daenerys.xplod.fr/synopsis.php"
ADRESSE_RELATIVE_SITE="https://daenerys.xplod.fr/"
#****************************extensions***************************************
TXT=".txt"
########VARIABLES DU SCRIPT########

#usage, explications 
function usage(){
    printf "Utilisation du script :\n"
    #printf "\t--conf                  : lance le backup  \n"
    printf "\t--installer                : installe les depandes suivant votre systeme type unix"
    printf "\t--conf                   : choisit le fichier de configuration  \n"
    printf "\t--backupdir              : indique l'endroit a mettre le backup \n"
    printf "\t--lire                   : lire un dossier de backup revient a faire un ls après avoir decrypte et desarchive  \n"
    printf "\t--uploadbck              : uploader un dossier de backup \n"
    printf "\t--dwbackup               : download d'une backup a partir de son hash"     
    printf "\t--supp                   : supprime proprement un dossier de backup \n" 
    printf "\t--conf fichierConf.txt --backupdir dossierDeStockageBackups "
    printf "\t-h                       : affiche ce message.\n"
}

#Installations et initialisations des divers packages necessaires au script
function installpackages(){
echo "***INSTALLATION AUTOMATIQUE***"
#Levinux
osdef=$(uname -a)
if [[ $osdef == *"tiny"* ]]; then
tce-load dialog gnupg
exit 0
fi
    
OS=$(uname)
echo "MON SYSTEME EST UN $OS"
case $OS in
  'Linux')
    #Test l'existence du chemin pour les rpm
    res=$(/usr/bin/rpm -q -f /usr/bin/rpm 2> /dev/null)
    if [[ $res == *"rpm"* ]]
    #Linux avec packages RPM
    then
        #Les distributions avec packages rpm peuvent gerer les deb aussi
        #Habituellement les distributions fedora sont changes souvent..
        #On peut utiliser le yum qui est deprecier a l'heure actuelle cela fonctionne encore avec la commande yum
        sudo dnf install dialog gnupg
    #Linux avec packages DEB
    else
	#Le dialog est deja sur une ubuntu de base en desktop
	sudo apt-get install dialog gnupg
    fi
    #FAIRE l'init de GPG
    ;;
   #On peut etendre a d'autre BSD..
  'FreeBSD')
    pkg install dialog gnupg
    #FAIRE l'init de GPG 
    ;;
   #On peut etendre a d'autre versions de Macintosh
   #Cas non verifie
   #Mac utilisation de la commande brew..
  'Darwin') 
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
    brew install dialog gpg
    ;;
  #Joker
  *)
  echo "ARCHITECTURE NON PRIS EN CHARGE-Installez les packets manuellement"
  ;;
esac 
}

########################TEST LANCEMENT########################
#Abscence d'arguments -> affichage de l'usage
#**************APPEL DE L USAGE**************
if [ $# -eq 0 ]; then
    usage
fi

#Lancement de l'installation au premier lancement du script (installation fraiche)
if [ ! -e $FICHIER_TEST_INSTALLATION ]; then
    echo "Installation des packets logiciels necessaires realisee" > $FICHIER_TEST_INSTALLATION
    installpackages
    echo "INSATALLATION DES DEPENDANCES EST TERMINEE, Relancer la commande précédante"
    exit 0
fi

#le test de l'ordre des arguments ne marche pas
########################TEST LANCEMENT########################

#Methode d'aide a la configuration 
function confexample(){
    echo ""
    fichier_conf_example="conf_exemple.txt"
    echo "###Un fichier de configuration typique###"
    echo "#Il s'agit de dossiers listes"
    echo "#Debut du fichier de configuration"
    echo "#pas de sensibilite a la case"
    echo "dossier1"
    echo "dossier2"
    echo "dossier3"
    echo "#fin du fichier de configuration"
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

    #regex=""
    #test de la forme du fichier avec une regex
    #if [ ! $FICHIER_SAUVEGARDE_CONFIG ~= $regex ];then
    #echo "le fichier de configuration n'est pas de la bonne forme!!"
    #confexample
    #fi

}

function veriflire(){
if [ -z $1 ]; then
   echo "vous devez passer un dossier à --lire:"
   usage
   exit 1	
fi

if [ ! -d "$1" ]; then
   echo "dossier renseigne inexistant!!"
   if [ -f "$1" ]; then
   echo "il s'agit d'un fichier!!"
   fi
   exit 1
fi
}

function lire(){
    #on va dans le dossier de backup
    veriflire $2
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
    nom=listedesbackup
    filename=$2$nom$TXT
    echo "$1" >> $filename
    #on compte le nombre de backups dans le bon dossier
    nb_fichiers=$(wc --words $filename  | cut -d ' ' -f1)
    echo "NOMBRE DE FICHIERS $nb_fichiers dans $2"
    if [ $nb_fichiers -eq $LIMITE_NB_FICHIERS_AUTO_SUPPRESSION ]
    then
    backup_la_plus_ancienne=$(head -n 1 $filename)
    cd $2
    sudo rm -Rf $backup_la_plus_ancienne
    #doit supprime l'entree sur le fichier c'est a dire la premiere ligne du fichier
    sed -i '1d' $filename
    cd ..
    fi
}

function supressbackup(){
    sudo rm -f $1
    nom=listedesbackup
    sup=$(dirname $1)    
    file=$(basename $1)
    filename=$sup$nom$TXT
    dol="/$"
    d="/d"
    a_sup=$dol$file$d
    sed $a_sup $filename
    grep -v $file $filename > /tmp/BASHscript.txt
    cat /tmp/BASHscript.txt > $filename
    exit 0
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
                if [ "$c" -ot "$d" ]
                   then
                       echo "$c est plus ancien que $d"
                   else
                       echo "$c est plus recent que $d"
                fi
		#On supprime nos archives, a discuter
		rm -Rf $c
		rm -Rf $d		
		exit 0
}


function downfile(){
   echo "ARG $1"
   if [ -d $REPERTOIRE_FICHIERS_TELECHARGES ]
   then
      mkdir $REPERTOIRE_FICHIERS_TELECHARGES
      cd $REPERTOIRE_FICHIERS_TELECHARGES
   else
      cd $REPERTOIRE_FICHIERS_TELECHARGES
   fi
   curl -O $1
   cd ..
   exit 0
}

function recupsynops(){
curl -O $PAGE_SYNOPS_SITE

synops_doss="SYNOPS"
supersynops="SUPSYNOPS"
sep="/"
if [ ! -d $synops_doss ];then
mkdir $synops_doss
fi

if [ ! -d $supersynops ];then
mkdir $supersynops
fi

supsyn="supsyn.php"
pre="?s="
post="&e="
page_stock="page"
supsynstock="synopsys"
underscore="_"
extsupsyn=".syn.gpg"
php=".php"
IFS=$'\n'
var5=$(cat synopsis.php)
regex="Season\ ([0-9]+)|Episode\ ([0-9]+)"
s=""
e=""
#echo "VAR 5 $var5"
for f in $var5
do
#echo "F $f"
 [[ $f =~ $regex ]]
 seasons="${BASH_REMATCH[1]}"
 episodes="${BASH_REMATCH[2]}"

if [ "$seasons" != "" ]; then
echo $seasons
s=$seasons
else
if [ "$episodes" != "" ]; then
echo $episodes
e=$episodes
curl $PAGE_SYNOPS_SITE$pre$s$post$e > $synops_doss$sep$page_stock$s$e$php
curl $ADRESSE_RELATIVE_SITE$supsyn$pre$s$post$e > $supersynops$sep$supsynstock$underscore$s$underscore$e$extsupsyn 
fi
fi
done

#files="*"
#point="."
#params=$point$sep$synops_doss$sep$files
#echo "FICHIERS $params"
#mettre en txt que le synopsys des pages.php



cd SYNOPS
IFS=$'\n'
for fich in *.php
do
echo "FICHIER TRAITE $fich"
fname=$(echo "$fich" | cut -d'.' -f1)
awk '{ if (match($0,/<p[[:space:]]class=\"left-align[[:space:]]light\"([^;])*<\/p>/,m)) print m[0] }' $fich > $fname$TXT
done
exit 0

}

function downbackup(){
#on concatene le hash
#result_request=$(curl -i $ADRESSE_DW_BACKUP_SITE$1)
#curl -i $ADRESSE_DW_BACKUP_SITE$1 > test.txt
#curl -O $name $ADRESSE_DW_BACKUP_SITE$1
url=$ADRESSE_DW_BACKUP_SITE$1
# | sed -i -e 's/^M//g'
filename=$(curl -sI  $url | grep -o -E 'filename=.*$' | sed -e 's/filename=//' | sed -e 's/"//' | sed -e 's/"//')
echo "FICHIER $filename"
curl -o $filename -L $url
exit 0
}

function upbackup(){
   curl -i -F "file=@$1;filename=$1" $ADRESSE_BACKUP_SITE 
   exit 0
}
#Cette partie gere les arguments et lance la bonne méthode
OPTS=$( getopt -o h -l conf:,backupdir:,compA:,compB,lire,supp,installer,uploadbck,dwnfile,recupallsynops,dwbackup, -- "$@" )
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
        --uploadbck) upbackup $3; shift 2;;
        --dwbackup) downbackup $3; shift 2;;
        --dwnfile) downfile $3; shift 2;;
        --recupallsynops) recupsynops; shift 2;;
        --supp) supressbackup $3; shift 2;;
	--installer) installpackages; shift 2;;
        --) shift; break;;
    esac
done

exit 0
