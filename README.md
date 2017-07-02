# AutoRenew letsencrypt
## Zimbra
## Apache
Après avoir installé letsencrypt via git dans le dossier de votre choix.
Télécharger ce script et éditer la variable LETSDIR pour y faire correspondre le chemin vers le dossier letsencrypt.

Lancer la la commande comme dans cet exemple :
./ApacheRenewSSL.sh /var/www/nextcloud cloud.mydomain.com nextcloud.mydomain.com|nc.mydomain.com|cloud.whatever.net

Ca va :<br>
1- créer le certificat s'il n'existe pas déjà<br>
   le mettre à jour dans le cas contraire<br>
2- mettre en place le CRON pour lancer cette commande tous les 2 mois<br>
