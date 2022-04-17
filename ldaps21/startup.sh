#! /bin/bash

mkdir /etc/ldap/certs
cp /opt/docker/cacert.pem /etc/ldap/certs/. # PER PROVAR-SE A SI MATEIX COM A CLIENT
cp /opt/docker/cacert.pem /etc/ssl/certs/.
cp /opt/docker/servercert.ldap.pem /etc/ldap/certs/.
cp /opt/docker/servercertPLUS.pem /etc/ldap/certs/.
cp /opt/docker/serverkey.ldap.pem  /etc/ldap/certs/.

rm -rf /etc/ldap/slapd.d/*
rm -rf /var/lib/ldap/*

cp /opt/docker/slapd.conf /etc/ldap/slapd.conf # NO SE SI CAL

slaptest -f /opt/docker/slapd.conf -F /etc/ldap/slapd.d
slaptest -u -f /opt/docker/slapd.conf -F /etc/ldap/slapd.d

slapadd -F /etc/ldap/slapd.d -l /opt/docker/edt.org.ldif
chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap

cp /opt/docker/ldap.conf /etc/ldap/ldap.conf # PER PROBAR-SE A SI MATEIX
#cp /opt/docker/slapd /etc/default/slapd # NO CAL PQ JA FUNCIONA EL SBIN DE ABAIX

########EXTRA ALTERNATE############

#A /etc/ssl/openssl.cnf li hem d'indicar ext.alternate.conf
#Si volguesim tenir sinonims del host (amb CA valid)  hauriem d'haver creat el certificat del ServerLdap incoporant ext.alternate.conf

#openssl x509 -CA cacert.pem -CAkey cakey.pem -req -in reqServer1.pem -out servercert.pem -CAcreateserial -extfile comtuvulguis.conf -extensions my_client -days 360

##############

#/usr/sbin/slapd -d0
/usr/sbin/slapd -d0 -u openldap -h "ldap:/// ldaps:/// ldapi:///"
