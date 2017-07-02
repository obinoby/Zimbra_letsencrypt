# AutoRenew letsencrypt
Après avoir installé letsencrypt via git dans le dossier de votre choix.
## Zimbra
Télécharger ce script et éditer les variables :<br>
LETSDIR is the dir where letsencrypt scripts are located<br>
ZIMDIR is the dir where zimbra is located<br>
FIRSTDOMAIN is the FQDN of the primary domain of this Zimbra server<br>
OTHERDOMAINS space separated FQDN domains list<br>

Lancer la la commande comme dans cet exemple :<br>
./ZimbraRenewSSL.sh

Ca va :<br>
1- créer le certificat s'il n'existe pas déjà<br>
   le mettre à jour dans le cas contraire<br>
2- mettre en place le CRON pour lancer cette commande tous les 2 mois<br>
3- déployer le certificat dans Zimbra
## Apache
Télécharger ce script et éditer la variable LETSDIR pour y faire correspondre le chemin vers le dossier letsencrypt.

Lancer la la commande comme dans cet exemple :<br>
./ApacheRenewSSL.sh /var/www/nextcloud cloud.mydomain.com nextcloud.mydomain.com|nc.mydomain.com|cloud.whatever.net

Ca va :<br>
1- créer le certificat s'il n'existe pas déjà<br>
   le mettre à jour dans le cas contraire<br>
2- mettre en place le CRON pour lancer cette commande tous les 2 mois<br>
