
1er SENSE RUNTLS


**Actuem com a CA...**

* **Generem clau privada simple i fabriquem certificat autosignat de veritat absoluta:**
```
openssl genrsa -out cakey.pem
openssl req -new -x509 -days 365 -key cakey.pem -out cacert.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:CA
State or Province Name (full name) [Some-State]:Barcelona
Locality Name (eg, city) []:bcn
Organization Name (eg, company) [Internet Widgits Pty Ltd]:VeritatAbsoluta
Organizational Unit Name (eg, section) []:Certificats
Common Name (e.g. server FQDN or YOUR name) []:veritat
Email Address []:veritat@edt.org
```

* **Generem clau privada del servidor:**
```
openssl genrsa -out serverkey.ldap.pem 4096
```


```
PER GENERAR LA CLAU PUBLICA (NO ENS CAL)
openssl rsa -in cakey.pem -pubout -out cakeypub.pem

```

* **Generem 'request' per el servidor LDAP:**

```
openssl req -new -x509 -days 365 -nodes -out servercert.ldap.pem -keyout serverkey.ldap.pem
Generating a RSA private key
..........+++++
.........+++++
writing new private key to 'serverkey.ldap.pem'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:CA
State or Province Name (full name) [Some-State]:Catalunya
Locality Name (eg, city) []:Barcelona
Organization Name (eg, company) [Internet Widgits Pty Ltd]:edt
Organizational Unit Name (eg, section) []:ldap
Common Name (e.g. server FQDN or YOUR name) []:ldap.edt.org
Email Address []:ldap@edt.org
```

**Som el servidor LDAP...**

* **Fem la petició (de firma) al servidor (VeritatAbsoluta), ens demanarà 'qui som':**

**Obtenim la petició del 'request' al servidor VeritatAbsolut (CA):**

```
openssl req -new -key serverkey.ldap.pem -out serverrequest.ldap.pem

You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:CA
State or Province Name (full name) [Some-State]:Catalunya
Locality Name (eg, city) []:Barcelona
Organization Name (eg, company) [Internet Widgits Pty Ltd]:edt
Organizational Unit Name (eg, section) []:ldap
Common Name (e.g. server FQDN or YOUR name) []:ldap.edt.org
Email Address []:ldap@edt.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:jupiter
An optional company name []:edt
```

**Tornem a ser CA...**

* **FIRMEM la 'request' enviada per LDAP, és genera 'cacert.srl':**
```
openssl x509 -CA cacert.pem -CAkey cakey.pem -req -in serverrequest.ldap.pem -CAcreateserial -days 365 -out servercert.ldap.pem
Signature ok
subject=C = CA, ST = Catalunya, L = Barcelona, O = edt, OU = ldap, CN = ldap.edt.org, emailAddress = ldap@edt.org
Getting CA Private Key
```

* ** ALTERNETIVA FIRMAR LA REQUEST ACEPTANT ALTRES DOMINIS COM A SINONIMS  ADJUNTATN UN FITXER DE CONFG ** *

openssl x509 -CA cacert.pem -CAkey cakey.pem -req -in serverrequest.ldap.pem -out servercertPLUS.pem -CAcreateserial -extfile ext.alternate.conf -days 365

L'IMPORTANT DEL FITXER AGFEGIT (-extfile), SON LES LINEAS:

[ v3_req ]

# Extensions to add to a certificate request

basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]

DNS.0 = ldap.edt.org
DNS.1 = mysecureldapserver.org
DNS.2 = ldap
IP.1 = 172.19.0.2
IP.2 = 127.0.0.1

-----------------------------------------------------------------------------------------------------  
**DINS DEL DOCKER/SERVIDOR:**

sudo docker build -t balenabalena/ldaps21:latest .

docker run --rm -h ldap.edt.org --name ldap.edt.org --network 2hisix -d balenabalena/ldaps21:latest
(els ports -p 389:389 -p 636:6363 no cal exposar-los cap a fora ja que ho farem local)

* **Mirem si en el propi Docker funciona:**
```
AFEGIR -d1 i -v per mirar errors (Debug i verbose)

ldapsearch -x -ZZ -LLL -H ldap://ldap.edt.org -b 'dc=edt,dc=org'
ldapsearch -x -LLL -H ldaps://ldap.edt.org -b 'dc=edt,dc=org'

AMB EL PLUS (dominis alternatius)

ldapsearch -x -LLL -H ldaps://mysecureldapserver.org -b 'dc=edt,dc=org'

**COM A CLIENT:**

* **1er hem de modificar '/etc/hosts' i posar la IP del Docker:**
```
172.x.0.x	ldap.edt.org mysercureldapserver.org 
127.0.0.1 localhost
```

* **Al client, FUNCIONA ? Encara no.. falta pas de sota:**
```
ldapsearch -x -LLL -H ldaps://ldap.edt.org -b 'dc=edt,dc=org'
ldapsearch -x -ZZ -LLL -H ldap://ldap.edt.org -b 'dc=edt,dc=org'
ldapsearch -x -LLL -H ldaps://mysecureldapserver.org -b 'dc=edt,dc=org'
```

* **Hem de modificar al client l'arxiu '/etc/ldap/ldap.conf' i ficar-li la ruta del certifcat, per tant, hem de pasar-li el certificat de la CA creat anteriorment per extreure la clau publica i chequejar el ServidorLDAPs:**
```
cp /var/tmp/m11/ssl21/tls:ldaps/cacert.pem

ARXIU CONF CLIENT: '/etc/ldap/ldap.conf':
TLS_CACERT	/etc/ssl/certs/cacert.pem
```


