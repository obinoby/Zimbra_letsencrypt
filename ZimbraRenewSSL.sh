#!/bin/bash
# Joris Marie    - Nov 2016
# Ben Souverbie  - Jui 2017
# Script de renouvellement automatique du certificat ssl de zimbra !

## ==== Custom parameters ====

#LETSDIR is the dir where letsencrypt scripts are located
LETSDIR="/opt/scripts/letsencrypt"

#ZIMDIR is the dir where zimbra is located
ZIMDIR="/opt/zimbra"

#FIRSTDOMAIN is the FQDN of the primary domain of this Zimbra server
FIRSTDOMAIN="zimbra.mydomain.com"

#OTHERDOMAINS space separated FQDN domains list
OTHERDOMAINS="mail.mydomain.com mail.myotherdomain.com whatever.anydomain.net"


## ==== Do not modify anything bellow this line ====

# Gestion du cron
echo "Check if the CRON is set"
if [ ! -f /etc/cron.d/zimbrarenewssl ]
then
  echo "> Well... It's not ! Configuring CRON"
  SCRIPT=$0
  if [ `echo $SCRIPT |grep "^\." -c` -eq 1 ]
  then
    SCRIPT_DIR="$( cd "$( dirname "$SCRIPT" )" && pwd )"
    SCRIPT=$(echo $0 | cut -d/ -f2)
    SCRIPT="$SCRIPT_DIR/$SCRIPT"
  fi
  echo "SHELL=/bin/sh" > /etc/cron.d/zimbrarenewssl
  echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/cron.d/zimbrarenewssl
  echo "" >> /etc/cron.d/zimbrarenewssl
  echo "# m h dom mon dow user	command" >> /etc/cron.d/zimbrarenewssl
  echo "52 22   1 */2 *   root  $SCRIPT >> /var/log/ZimbraRenewSSL.log" >> /etc/cron.d/zimbrarenewssl
fi

#Arret des services Web Zimbra
echo "Webserver has to be not running when generating certificates, so :"
echo "> Stop Zimbra web services"
su - zimbra -c "zmproxyctl stop"
su - zimbra -c "zmmailboxdctl stop"

CERTDIR="$ZIMDIR/ssl/letsencrypt"
DOMLIST=$(echo $OTHERDOMAINS | sed -- 's/ / -d /g')
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
$LETSDIR/letsencrypt-auto certonly --standalone $RENEW -d $FIRSTDOMAIN $DOMLIST
GETAT=$?

case $GETAT in
  0)
    echo "Copy the certificate into Zimbra directory"
    mkdir -p $CERTDIR
    rm -f $CERTDIR/*
    if [ -d /etc/letsencrypt/live/$FIRSTDOMAIN-0001 ]; then
      cp /etc/letsencrypt/live/$FIRSTDOMAIN-0001/* $CERTDIR
    else
      cp /etc/letsencrypt/live/$FIRSTDOMAIN/* $CERTDIR
    fi

    echo "Add the root CA into the certification chain"
    echo "-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----" >> $CERTDIR/chain.pem

    echo "Change the rights on the certificates so that Zimbra own them"
    chown zimbra:zimbra $CERTDIR/*

    echo "Check if the new certificate is valid"
    VALID=$(su - zimbra -c "/opt/zimbra/bin/zmcertmgr verifycrt comm $CERTDIR/privkey.pem $CERTDIR/cert.pem $CERTDIR/chain.pem")
    ETAT=$?

    case $ETAT in
      0)
        echo "> New certificate is valid"
        #Backup des certif actuels
        TODAY=$(date +%Y%m%d)
        BCKDIR="/opt/zimbra/ssl/zimbra.$TODAY"
        echo "> Backup old Zimbra certificates into $BCKDIR"
        cp -a /opt/zimbra/ssl/zimbra $BCKDIR
        echo "> Put the private key in place"
        cp $CERTDIR/privkey.pem /opt/zimbra/ssl/zimbra/commercial/commercial.key
        echo "> Deploy the new certificate"
        su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm $CERTDIR/cert.pem $CERTDIR/chain.pem "
        ETAT=$?
        case $ETAT in
          0)
            echo ">> Certificate deploy succeeded"
            ;;
          *)
            echo ">> Certificate deploy failure"
            echo ">>> Restauring from backup"
            rm -rf /opt/zimbra/ssl/zimbra
            cp -a $BCKDIR /opt/zimbra/ssl/zimbra
            ;;
        esac
        ;;
      *)
        echo "> Invalid new Certificate - nothing changed"
        ;;
    esac
    ;;
  *)
    echo "Certificate generation failure - nothing changed"
    ;;
esac

echo "*** Restart Zimbra services ***"
su - zimbra -c "zmcontrol restart"

exit 0
