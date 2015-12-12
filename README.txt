Je propose qu'on se tienne au courant dans ce fichier, de ce que chacun a fait et s'il y a des trucs de quelqu'un a terminer qu'un autre puisse reprendre !

Je pense que ça parle mieux que les messages imbitables des commits ...

du genre :

Anthony : 19/11 : Je n'ai rien fait à part créer cette merde
A faire : m'expliquer ce que je peux/dois faire.

Kiss aux rageux !

Guillaume : 23/11

BOGUES:
-Premier dossier copie present dans le fichier de configiuration (test2.txt) (premiere ligne du fichier):
s'il contient des fichiers, il n'est pas copie en entier: seul ses sous dossiers et fichiers son copies



A VOIR:

PB de la boucle meme pb avec un for
http://unix.stackexchange.com/questions/29214/copy-first-n-files-in-a-different-directory/29221

On remarquera un comportement très étrange si on laisse pas un deuxième argument dans la recuperation des opts avec lire

le test des arguments est fastidieux

le but est de rendre plus propre le tout notamment les tests pour les fichiers de conf..
tester tous les cas d'erreurs..
certains sont testes d'autres il est tres difficile
si dialog en faire un pour la lecture serait l'ideal

#####IMPORTANT#####
Kevin Araba a fait une tres bonne remarque il ne faut pas copier les dossiers mais faire une archive en utilisant leurs chemins, au niveau perf ca doit etre pourri
Droits sur les backup!!
#####IMPORTANT#####

PROBLEME TRAITES (a bien verifier):

-~~si on fait un --conf seul visiblement rien ne se passe, on ne peux pas imbriquer si je ne me trompe pas:
./script --conf test2.txt
./script --backupdir DOSSIER_BACKUP

Si on passe un fichier de conf inexistant genre text3.txt on a une erreur
Si on passe un fichier de conf mais avec rien dedans on a une erreur
Si on passe un fichier de conf dans un premier temps:
./script --conf text2.txt
puis on fait le backup après
./script --backupdir OK
cela fonctionne
si on passe
./script --conf test2.txt --backupdir OK
cela fonctionne aussi

Le cas du: on mets n'importe quoi dans le fichier de conf n'est pas traite

on un usage pour le fichier de conf en quelque sorte (si la personne se trompe ça s'affiche)

plus de pb de phrase secrete visiblement
