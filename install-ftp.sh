#!/bin/bash

# Variabelen uit parameters
ADMIN_USER=$1
FTPUSER1_PASSWORD=$2
FTPUSER2_PASSWORD=$3
FTP_DATA_DIR=$4
FTP_GROUP="ftpusers"

# Updates uitvoeren en vsftpd installeren
apt-get update -y
apt-get upgrade -y
apt-get install -y vsftpd
apt-get install -y ufw

# firewall allow ssh and ftp
ufw allow ssh
ufw allow ftp
ufw enable

# Configuratie van vsftpd
cat <<EOL > /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=1048
EOL

# Gedeelde directory aanmaken
mkdir -p $FTP_DATA_DIR
chmod 755 $FTP_DATA_DIR

# FTP-groep aanmaken
groupadd $FTP_GROUP
chown :$FTP_GROUP $FTP_DATA_DIR
chmod 770 $FTP_DATA_DIR

# FTP-gebruikers aanmaken en toevoegen aan de groep
useradd -m -d $FTP_DATA_DIR -s /sbin/nologin -G $FTP_GROUP ftpuser1
echo "ftpuser1:$FTPUSER1_PASSWORD" | chpasswd
useradd -m -d $FTP_DATA_DIR -s /sbin/nologin -G $FTP_GROUP ftpuser2
echo "ftpuser2:$FTPUSER2_PASSWORD" | chpasswd

# FTP-server opnieuw starten
systemctl restart vsftpd
systemctl enable vsftpd

echo "FTP-server installatie voltooid. Gebruikers hebben toegang tot $FTP_DATA_DIR via groep $FTP_GROUP."
