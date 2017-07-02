#!/bin/bash
# Joris Marie    - Nov 2016
# Ben Souverbie  - Jui 2017
# Script de renouvellement automatique du certificat ssl de zimbra !

## ==== Custom parameters ====

#LETSDIR is the dir where letsencrypt scripts are located
LETSDIR="/opt/scripts/letsencrypt"

#SITEDIR is the dir where the site is located like "/var/www/site"
SITEDIR=$1

#FIRSTDOMAIN is the FQDN of the primary domain of this Zimbra server like "www.mydomain.com"
FIRSTDOMAIN=$2

#OTHERDOMAINS pipe separated FQDN domains list like "site.mydomain.com|whatever.anydomain.net"
OTHERDOMAINS=$3


## ==== Do not modify anything bellow this line ====

# Gestion du cron
echo "Check if the CRON is set"
SCRIPT=$0
if [ `echo $SCRIPT |grep "^\." -c` -eq 1 ]
then
  SCRIPT_DIR="$( cd "$( dirname "$SCRIPT" )" && pwd )"
  SCRIPT=$(echo $0 | cut -d/ -f2)
  SCRIPT="$SCRIPT_DIR/$SCRIPT"
fi
if [ ! -f /etc/cron.d/apacherenewssl ]
then
  echo "> Well... It's not! Configuring CRON"

  echo "SHELL=/bin/sh" > /etc/cron.d/apacherenewssl
  echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/cron.d/apacherenewssl
  echo "" >> /etc/cron.d/apacherenewssl
  echo "# m h dom mon dow user	command" >> /etc/cron.d/apacherenewssl
  echo "52 22   1 */2 *   root  $SCRIPT $SITEDIR $FIRSTDOMAIN $OTHERDOMAINS >> /var/log/ApacheRenewSSL.log" >> /etc/cron.d/apacherenewssl
else
  echo "> CRON file exists but is it set for $FIRSTDOMAIN ?"
  if [ `cat /etc/cron.d/apacherenewssl |grep $SCRIPT |grep -c $FIRSTDOMAIN` -eq 0 ]
  then
    echo ">> Well... It's not! Configuring CRON"
    echo "52 22   1 */2 *   root  $SCRIPT $SITEDIR $FIRSTDOMAIN $OTHERDOMAINS >> /var/log/ApacheRenewSSL.log" >> /etc/cron.d/apacherenewssl
  fi
fi

DOMLIST=$(echo $OTHERDOMAINS | sed -- 's/|/ -d /g')
if [ "$DOMLIST" != "" ]
then
  DOMLIST=" -d $DOMLIST"
fi
if [ -d /etc/letsencrypt/live/$FIRSTDOMAIN ]
then
  #Renouvellement du certif
  echo "Renew existing certificate"
  RENEW="--renew-by-default"
else
  #Création du certificat
  echo "Create new certificate from scratch"
  RENEW=""
fi
$LETSDIR/letsencrypt-auto certonly -a webroot --webroot-path $SITEDIR $RENEW -d $FIRSTDOMAIN $DOMLIST
GETAT=$?

case $GETAT in
  0)
    echo "New certificate generated"
    ;;
  *)
    echo "Certificate generation failure - nothing changed"
    ;;
esac

echo "*** Restart Apache services ***"
service apache2 restart

exit 0
