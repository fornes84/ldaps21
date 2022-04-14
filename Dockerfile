# ldaps_server
FROM debian:latest
LABEL version="1.0"
LABEL author="@rubeeenrg ASIX-M11"
LABEL subject="ldaps_server (TLS)"
RUN apt-get update
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install procps iproute2 tree nmap vim ldap-utils systemd slapd less openssl 
RUN mkdir /opt/docker
COPY * /opt/docker/
RUN chmod +x /opt/docker/startup.sh
WORKDIR /opt/docker
CMD /opt/docker/startup.sh
EXPOSE 389 636

