# LDAPS
## @edt ASIX M11-SAD Curs 2018-2019

Creació d'un container docker amb un servei ldap
i la base de dades *dc=edt,dc=org*. Aquest servei
permet l'accés segur via TLS/SSL amb *ldaps* i 
també *starttls*.

```
$ docker run --rm --name ldap.edt.org -h ldap.edt.org -d rubeeenrg/tls21:ldaps
```

#### Configuració:

Per tal de que escolti també al port ldaps (636) a 
més del port standard (389), *startup.sh*:
```
/usr/sbin/slapd -d0 -u ldap -h "ldap:/// ldaps:/// ldapi:///" 
```

Per configurar les claus de TLS/SSL, *slapd.conf*:
```
TLSCACertificateFile        /etc/ldap/certs/cacert.pem
TLSCertificateFile          /etc/ldap/certs/servercert.ldap.pem
TLSCertificateKeyFile       /etc/ldap/certs/serverkey.ldap.pem
TLSVerifyClient       never
TLSCipherSuite HIGH:MEDIUM:LOW:+SSLv2
```

En el client cal configurar el certificat de la CA que ha de validar el certificat
del servidor:
```
/etc/ldap/ldap.conf:
TLS_CACERT /etc/ldap/certs/cacert.pem
```

En la pròpia imatge ldap configurar el client ldap per usar el certificat de la CA:
```
/etc/ldap/ldap.conf:
TLS_CACERT /opt/docker/cacert.pem
```

#### Ordres client:

Exemples de connexió client  en text plà i en tls/ssl
```
ldapsearch -x  -H ldap://ldap.edt.org 
ldapsearch -x  -H ldaps://ldap.edt.org 
```

Exemples usant startls:
```
ldapsearch -x -Z -H ldap://ldap.edt.org 
ldapsearch -x -ZZ -H ldap://ldap.edt.org 
```

Exemple '*erroni*', usar starttls sobre una connexió que 
ja és tls/ssl:
```
ldapsearch -x -ZZ -H ldaps://ldap.edt.org 
```

Desar e un fitxer el debug:
```
ldapsearch -x -ZZ -H ldap://ldap.edt.org -d1   dn  2> log
```

## Subject Alternative Name

**Atenció** Si es genera un nou certificat cal generar de nou la imatge docker i fer el run,
no podem simplement copiar-la en calent al container per fer el test perquè el certificat es
carrega al slapd en temps de construccció (en fer *slaptest*) de la base de dades.

Fitexr de extensions amb noms alternatius de host del servidor:
```
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth
subjectAltName=IP:172.17.0.2,IP:127.0.0.1,email:copy,URI:ldaps://mysecureldapserver.org
```

Generar el certificat nou (utilitzem la CA de Veritat Absoluta perquè no sigui autosignat):
```
openssl x509 -CAkey cakey.pem -CA cacert.pem -req -in serverreq.ldap.pem -days 3650 -CAcreateserial -extfile ext.alternate.conf -out servercert.ldap.pem
Signature ok
subject=/C=ca/ST=barcelona/L=barcelona/O=edt/OU=informatica/CN=ldap.edt.org/emailAddress=ldap@edt.org
Getting CA Private Key
```

```
openssl x509 -CAkey cakey.pem -CA cacert.pem -req -in serverreq.ldap.pem -days 3650 -CAcreateserial -extfile ext.alternate.conf -out servercert.ldap.pem

RESUM DE TOT: Signar / crear un certificat per 'ldapserver'.
SIGNIFICAT INDIVIDUAL:
```

Verificar que hi ha les extensions:
```
openssl x509 -noout -text -in servercert.ldap.pem
        ...
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Subject Alternative Name: 
                IP Address:172.17.0.2, IP Address:127.0.0.1, email:ldap@edt.org, URI:ldaps://mysecureldapserver.org
```

Test ldap
```
# ldapsearch -x -LLL -h 172.17.0.2 -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org

# ldapsearch -x -LLL -Z -h 172.17.0.2 -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org

# ldapsearch -x -LLL -ZZ -h 172.17.0.2 -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org

# ldapsearch -x -LLL -H ldaps://172.17.0.2  -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org

# ldapsearch -x -LLL -H ldaps://172.17.0.2:636  -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org

# ldapsearch -x -LLL -ZZ -H ldaps://172.17.0.2 -s base -b 'dc=edt,dc=org' dn
ldap_start_tls: Operations error (1)
	additional info: TLS already started
```

```
# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
172.17.0.2 ldap.edt.org mysecureldapserver.org

# ldapsearch -x -LLL -H ldaps://ldap.edt.org -s base -b 'dc=edt,dc=org' dn
dn: dc=edt,dc=org
```

Test del certificat:
```
# openssl s_client -connect 172.17.0.2:636 < /dev/null 2> /dev/null | openssl x509 -noout -tex
```

Test des de l'interior del container:
```
# ldapsearch -x -LLL -ZZ -h 127.0.0.1 -s base
dn: dc=edt,dc=org
dc: edt
description: Escola del treball de Barcelona
objectClass: dcObject
objectClass: organization
o: edt.org

[root@ldap docker]# ldapsearch -x -LLL -H ldaps://127.0.0.1 -s base dn
dn: dc=edt,dc=org

[root@ldap docker]# ldapsearch -x -LLL -H ldaps://localhost -s base dn
dn: dc=edt,dc=org
```
