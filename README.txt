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

PROBLEME TRAITE (a bien verifier):
-~~si on fait un --conf seul visiblement rien ne se passe, on ne peux pas imbriquer si je ne me trompe pas:
./script --conf test2.txt
./script --backupdir DOSSIER_BACKUP
A Discuter: que faut-il afficher simplement l'usage?

A VOIR:
Visiblement la phrase secrete n'est plus demande, au cryptage.

PB de la boucle meme pb avec un for
http://unix.stackexchange.com/questions/29214/copy-first-n-files-in-a-different-directory/29221

On remarquera un comportement très étrange si on laisse pas un deuxième argument dans la recuperation des opts avec lire

le but est de rendre plus propre le tout notamment les tests pour les fichiers de conf..
tester tous les cas d'erreurs..
