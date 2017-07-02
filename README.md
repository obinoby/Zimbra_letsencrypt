# AutoRenew letsencrypt
## Zimbra
## Apache
Après avoir installer letsencrypt via git dans le dossier de votre choix.
Télécharger ce script et éditer la variable LETSDIR pour y faire correspondre le chemin vers le dossier letsencrypt.

Lancer la la commande comme dans cet exemple :
./ApacheRenewSSL.sh /var/www/nextcloud cloud.mydomain.com nextcloud.mydomain.com|nc.mydomain.com|cloud.whatever.net

Ca va :
1- créer le certificat s'il n'existe pas déjà
   le mettre à jour dans le cas contraire
2- mettre en place le CRON pour lancer cette commande tous les 2 mois
