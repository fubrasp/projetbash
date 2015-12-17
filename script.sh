#!/bin/bash

########VARIABLES DU SCRIPT########

#Repertoire de stockage des fichiers pour le fonctionnement de script en cas de changement de machine ne pas copier

#Configuration de la limite pour la supression automatique de backups
#Nom generique pour le fichier listant les backup qui est de la forme DOSSIER_DE_SAUVEGARDEnomgenerique.txt

#Nom du fichier de configuration
#Fichier de configuration par defaut le cas echeant
#Fichier sauvegardant le choix de configuration effectues posterieurement
#Fichier permettant de savoir si l'installation a deja ete realisee
#Repertoire ou sont stockes les fichiers telecharges la fonction downfile

#url d'upload de backups 
#url de download de backups
#url de la page recapitulative des synopsys
#url de base du site

#Extension .txt
#Extension .php
#Extension .tar.gz

#Signe / et dollar
#Signe / et d
#Separateur /

UTILISATEUR=$(whoami)
#*********************CONFIG script***************************  
CONF_SCRIPT="CONF_SCRIPT"
#*********************CONFIG supression automatique***************************  
#mis a 5 pour les tests la valeur normale est de 100
LIMITE_NB_FICHIERS_AUTO_SUPPRESSION=3
NOM_FICHIER_LISTANT_LESBACKUPS="listedesbackup"
#****************************CONFIG backup************************************
#LOCAL
fichier_conf_nom=""
FICHIER_CONF_DEFAUT="test2.txt"
FICHIER_SAUVEGARDE_CONFIG="save_CONF.txt"
FICHIER_TEST_INSTALLATION="confBASHBACKUP.txt"
#DISTANT
REPERTOIRE_FICHIERS_TELECHARGES="saved_files_directory"
NOM_FICHIER_LISTE_BACKUPS_UPLOADES="liste_backups_uploades.txt"
#*****************************CONFIG synopsys*********************************
SYNOPS_DOSS="/home/$UTILISATEUR/GoT"
NOM_SAISON="Saison"
NOM_EPISODE="Episode"
SUPERSYNOPS_DOSS="SUPSYNOPS"
#********************************URLs*****************************************
ADRESSE_BACKUP_SITE="https://daenerys.xplod.fr/backup/upload.php?login=bertrandcerfruez"
ADRESSE_DW_BACKUP_SITE="https://daenerys.xplod.fr/backup/download.php?login=bertrandcerfruez&hash="
ADRESSE_LIST_BACKUPS_UPLOADEES_JSON="https://daenerys.xplod.fr/backup/list.php?login=bertrandcerfruez"
PAGE_SYNOPS_SITE="https://daenerys.xplod.fr/synopsis.php"
ADRESSE_RELATIVE_SITE="https://daenerys.xplod.fr/"
#****************************extensions***************************************
TXT=".txt"
PHP=".php"
TARGZ=".tar.gz"
GPG=".gpg"
EXTSUPSYN=".syn.gpg"
#outils
DOL="/$"
D="/d"
SEPARATEUR="/"
UNDERSCORE="_"
########VARIABLES DU SCRIPT########

#usage: explications 
function usage(){
    printf "Utilisation du script :\n"
    printf "\t--installer              : installe les depandes suivant votre systeme type unix\n"
    printf "\t--conf                   : choisit le fichier de configuration  \n"
    printf "\t--backupdir              : indique l'endroit a mettre le backup \n"
    printf "\t--lire                   : lire un dossier de backup revient a faire un ls après avoir decrypte et desarchive  \n"
    printf "\t--uploadbck              : uploader un dossier de backup \n"
    printf "\t--dwbackup               : download d'une backup a partir de son hash\n"
    printf "\t--recupallsynops         : recupere les synopsys\n"     
    printf "\t--supp                   : supprime proprement un dossier de backup \n"
    printf "\t--differ                 : fait la difference entre deux backups" 
    printf "\t--conf fichierConf.txt --backupdir dossierDeStockageBackups\n"
    printf "\t-h                       : affiche ce message.\n"
}

#Installations et initialisations des divers packages necessaires au script
function installpackages(){
echo "***INSTALLATION AUTOMATIQUE***"
#Levinux
osdef=$(uname -a)
if [[ $osdef == *"tiny"* ]]; then
tce-load dialog gnupg curl
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
        sudo dnf install dialog gnupg curl
    #Linux avec packages DEB
    else
        if [[ $osdef == *"Debian"* ]]
        then
        printf "le script doit etre exclusivement lance par root la remiere fois"
        apt-get install sudo
        sudo apt-get install dialog gnupg curl
        else
	#Le dialog est deja sur une ubuntu de base en desktop
	sudo apt-get install dialog gnupg curl
        fi
    fi
    #FAIRE l'init de GPG
    ;;
   #On peut etendre a d'autre BSD..
  'FreeBSD')
    pkg install dialog gnupg curl
    #FAIRE l'init de GPG 
    ;;
   #On peut etendre a d'autre versions de Macintosh
   #Cas non verifie
   #Mac utilisation de la commande brew..
  'Darwin') 
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
    brew install dialog gnupg curl
    ;;
  #Joker
  *)
  echo "ARCHITECTURE NON PRIS EN CHARGE-Installez les packets ou compilez manuellement"
  ;;
esac 
keys_exist=$(gpg --list-keys)
if [ "$keys_exist" == "" ]
then
echo "Vous n'avez pas de clef gpg!!"
gpg --gen-key
else
echo "Une ou des clef(s) sont existente(s) vous pouvez l(es) utiliser pour proceder aux sauvegarde(s)"
fi
exit 0
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
    echo "L'INSTALLATION DES DEPENDANCES EST TERMINEE, Relancer la commande précédante"
    exit 0
fi

if [ ! -d $CONF_SCRIPT ]; then
mkdir $CONF_SCRIPT
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

#Lance la verification de la configuration concernant la liste des dossiers a backuper!
function verifconf(){
    #Nom du fichier de configuration passe en parametre de, apres --backupdir
    #Si l'argument n'est pas passe, cela veut dire qu'on peut faire la commande en 2 fois, passage par defaut
    if [ "$fichier_conf_nom" == "" ]
    then
    	fichier_conf_nom=$FICHIER_CONF_DEFAUT
    fi

    #Test de l'existance du fichier de configuratio passe en parametre
    if [ ! -e $(cat $FICHIER_SAUVEGARDE_CONFIG) ]; then
      echo "Fichier de conf n'existe pas!!"
      confexample
      exit 1
    fi
 
    #Test si le fichier de configuration est vide
    if [ ! -s $(cat $FICHIER_SAUVEGARDE_CONFIG) ]
        then
            echo "Fichier de conf $(cat $FICHIER_SAUVEGARDE_CONFIG) existant mais vide!!"
            confexample
	    exit 1
        else
            #On utilise le fichier de configuration indique s'il correspond a ce que l'on veut
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

    #On decrypte l'archive a lire
    gpg $dossier_voulu
    #On fait un "basename" (on enleve les extension .tar.gz.gpg), un substring aurait ete plus propre..		
    a=$(echo "${dossier_voulu%%.*}")
    echo "ARG LIRE BASENAME $a"
    #On concatene l'extension tar gz		
    c=$a$TARGZ
    #on decompresse
    tar zxfv $c
    cd $a
    echo "l'archive voulue contient"
    ls
    cd .. 
    #avec des dialog on peut faire naviguer le cas echeant
    exit 0 
}

#Fonction permettant la suppression automatique des backup au bout d'un d'un nombre defini de backup 
function autosupressbackup(){
    #Pour chaque dossier de backup on a un fichier les listant
    filename=$2$NOM_FICHIER_LISTANT_LESBACKUPS$TXT
    echo "$1" >> $filename
    #On compte le nombre de backups dans le bon dossier -> le but est de stocke l'information su nombre de backup et de l'ordre des backups 
    nb_fichiers=$(wc --words $filename  | cut -d ' ' -f1)
    echo "NOMBRE DE FICHIERS $nb_fichiers dans $2"
    if [ $nb_fichiers -eq $LIMITE_NB_FICHIERS_AUTO_SUPPRESSION ]; then
    #On prend la premiere ligne qui correspond au fichier le plus ancien 
    backup_la_plus_ancienne=$(head -n 1 $filename)
    #Suppression de la backup la plus ancienne
    sudo rm -Rf $2$SEPARATEUR$backup_la_plus_ancienne
    #On doit supprimer l'entree sur le fichier correspondant au fichier c'est a dire la premiere ligne du fichier
    sed -i '1d' $filename
    echo "****FICHIER $backup_la_plus_ancienne SUPPRIME AUTOMATIQUEMENT*****"
    fi
}

#Fonction qui supprime proprement une backup -> sans creer des cas d'erreurs
function supressbackup(){
    #On supprime la backup
    sudo rm -f $1
    #On obtient le dossier ou se situe la bakup
    sup=$(dirname $1)
    #On obtient le nom de la backup    
    file=$(basename $1)
    #On veut intervenir dans le fichier de la forme DOSSIERlistedebackups.txt
    filename=$sup$NOM_FICHIER_LISTANT_LESBACKUPS$TXT
    #regex pour la supression quelque soit l'emplacement dans le fichier
    a_sup=$DOL$file$D
    #Suppression de la ligne coresspondante
    sed $a_sup $filename
    #A detailler???
    grep -v $file $filename > /tmp/BASHscript.txt
    cat /tmp/BASHscript.txt > $filename
    exit 0
}

#Fonction de backup
#Creer un dossier pour les backup s'il n'a pas ete cree avant
function backup(){
verifconf $1 
backup="backup_"
current_hour=$(date +%Y%H%M%S)

    if [ -d "$1" ]
    then
	echo -e "\nDossier deja existant\n"
    else
	mkdir "$1"
    fi
	#chemin
	#echo -e "full_path=$PWD$SEPARATEUR$1$SEPARATEUR$backup$current_hour \n" 
	#redirection ambigu si pas de param
	full_path=$PWD$SEPARATEUR$1$SEPARATEUR$backup$current_hour
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
    #demande dans l'enonce juste la personne qui a cree peut lire la backup
    sudo chmod 400 $backup_name.tar.gz.gpg
    rm -R -f $backup_name
    rm -f $backup_name.tar.gz
    cd ..
    autosupressbackup $backup_name.tar.gz.gpg $1
 }


#Fonction qui recupere le fichier de configuration
function recup(){
   fichier_conf_nom=$1
   echo "$fichier_conf_nom" > $FICHIER_SAUVEGARDE_CONFIG
}

#Fonction qui crypte le backup
function crypte(){
    echo "Archive $1 cryptee"
    gpg --encrypt $1
}

#Cette fonction permet le diff entre 2 backups
function differ(){
#                if [ -f $1 ] || [ -f $2 ]
#                then  
		a=$1
                b=$2
                directory_a=$(dirname $a)
                directory_b=$(dirname $b)
                echo "DOSSIER A $directory_a"
		#On decrypte les deux archives a comparer (diff)
		gpg $a
		gpg $b
		#On fait un "basename" (on enleve les extension .tar.gz.gpg), un substring aurait ete plus propre..		
		a=$(echo "${a%%.*}")
		b=$(echo "${b%%.*}")
		#On concatene l'extension tar gz, on recherche seulement a savoir si c'est different en terme de contenu		
		c=$a$TARGZ
		d=$b$TARGZ
                #On detare et decompresse
                echo "A $c B $d"
                tar zxfv $c -C $directory_a
                tar zxfv $d -C $directory_b
		#On fait le diff
                printf "\n"
		diff $a $b
                printf "\n"
                if [ "$c" -ot "$d" ]
                   then
                       echo "$c est plus ancien que $d"
                   else
                       echo "$c est plus recent que $d"
                fi
		#On supprime les archives
		rm -Rf $c
		rm -Rf $d
                #On supprime les dossiers decompresses
                rm -Rf $a
                rm -Rf $b		
		exit 0
#                else
#                echo "UN des deux dossiers, ou les deux n'existent pas!!!"     
#                exit 1
#                fi
}


#Fonction generique, pour telecharger a partie d'une url
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

#Fonction recuperant les synopsys et episode dynamiquement ainsi que les signatures
function recupsynops(){
#Recuperation de la page principale
curl -O $PAGE_SYNOPS_SITE

#Test de l'existence du dossier des synopsys
if [ ! -d $SYNOPS_DOSS ];then
mkdir $SYNOPS_DOSS
fi

#Test de l'existence du dossier des superynopsys
if [ ! -d $SYNOPS_DOSS$SEPARATEUR$SUPERSYNOPS_DOSS ];then
mkdir $SYNOPS_DOSS$SEPARATEUR$SUPERSYNOPS_DOSS
fi

#Sequences utilises
supsyn="supsyn.php"
pre="?s="
post="&e="
supsynstock="synopsys"


IFS=$'\n'
#On affiche la page principale
var5=$(cat synopsis.php)

#la regex permettant de recuperer le nombre d'episodes et de saisons
regex="Season\ ([0-9]+)|Episode\ ([0-9]+)"
s=""
e=""
#parcours du fichier recapitulant les saisons et les episodes
for f in $var5
do
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
curl $PAGE_SYNOPS_SITE$pre$s$post$e > $SYNOPS_DOSS$SEPARATEUR$NOM_SAISON$s$NOM_EPISODE$e$PHP
curl $ADRESSE_RELATIVE_SITE$supsyn$pre$s$post$e > $SYNOPS_DOSS$SEPARATEUR$SUPERSYNOPS_DOSS$SEPARATEUR$supsynstock$UNDERSCORE$s$UNDERSCORE$e$EXTSUPSYN 
fname=$(echo "$SYNOPS_DOSS$SEPARATEUR$NOM_SAISON$s$NOM_EPISODE$e$PHP" | cut -d'.' -f1)
awk '{ if (match($0,/<p[[:space:]]class=\"left-align[[:space:]]light\"([^;])*<\/p>/,m)) print m[0] }' $SYNOPS_DOSS$SEPARATEUR$NOM_SAISON$s$NOM_EPISODE$e$PHP > $fname$TXT 
sed -i 's/<[^>]*>//g' $fname$TXT
fi
fi
done
rm $SYNOPS_DOSS$SEPARATEUR*.php
exit 0

}

function downbackup(){
#Dans un premier temps on va afficher les hash et les noms pour permettre un choix plus claire
curl $ADRESSE_LIST_BACKUPS_UPLOADEES_JSON > $NOM_FICHIER_LISTE_BACKUPS_UPLOADES
cat $NOM_FICHIER_LISTE_BACKUPS_UPLOADES
printf "\n"
#On concatene le hash à l'url
echo "rentrez le hash pour telecharger"
read res
#On concatene le hash à l'url
url=$ADRESSE_DW_BACKUP_SITE$res
#On voulait enlever le caractere bizarre, ne pose pas probleme ceci dit
# | sed -i -e 's/^M//g'
filename=$(curl -sI  $url | grep -o -E 'filename=.*$' | sed -e 's/filename=//' | sed -e 's/"//' | sed -e 's/"//')
echo "FICHIER $filename"
curl -o $filename -L $url
exit 0
}

#Methode pour l'upload et la mise a jour de fichier, on fait pas un upload naif..
function upbackup(){
   #Genere le hash du fichier passe en parametre
   md5_fichier_pour_upload=$(md5sum $1)
   #On telecharge la derniere version de la liste, on prevoit qu'a l'avenir on pourrait supprimer en ligne
   curl $ADRESSE_LIST_BACKUPS_UPLOADEES_JSON > $NOM_FICHIER_LISTE_BACKUPS_UPLOADES
   #On prend seulement le md5 pour la comparaison, on exclut volontairement le cas du meme fichier avec deux noms differents (la personne en est consciente si elle upload)
   var=$(echo $md5_fichier_pour_upload | cut -f 1 -d " ")
   #On test si ce fichier est deja en ligne a partir de la liste de backups telechargee
   if [[ $(cat $NOM_FICHIER_LISTE_BACKUPS_UPLOADES) == *"$var"* ]]
   then
       echo "Le fichier est DEJA uploade, uploader une copie? (y/n)"
       response="init"
       #On boucle jusqu'a avoir une reponse valable
       while [ "$response" != "y" ] || [ "$response" != "Y" ] || [ "$response" != "n" ] || [ "$response" != "N" ]
       do
       read response
       #La personne veut quand meme reuploader le meme fichier
       if [ $response == "y" ] || [ $response == "y" ]
       then
          curl -i -F "file=@$1;filename=$1" $ADRESSE_BACKUP_SITE
          exit 0
       else
         #Elle choisit d'arreter le processus ici
         if [ $response == "n" ] || [ $response == "N" ]; then
            exit 0
         fi
         #cas d'erreur
         echo "Recommencez!! erreur vous avez mis $response !!"
       fi
       done
   else
       #Le fichier n'est pas present en ligne
       curl -i -F "file=@$1;filename=$1" $ADRESSE_BACKUP_SITE
       exit 0
   fi
   exit 0
}


#Cette partie gere les arguments et lance la bonne methode
OPTS=$( getopt -o h -l conf:,backupdir:,lire,supp,installer,uploadbck,dwnfile,recupallsynops,dwbackup,differ -- "$@" )
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
        --differ) differ $3 $4; shift 2;;
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
