#!/bin/bash

# Variabelen uit parameters
ADMIN_USER=$1
FTPUSER1_PASSWORD=$2
FTPUSER2_PASSWORD=$3
FTP_DATA_DIR=$4
FTP_GROUP="ftpusers"

# Updates uitvoeren en vsftpd installeren
apt-get update -y
apt-get install -y vsftpd
apt-get install -y ufw

# Gedeelde directory aanmaken
mkdir -p $FTP_DATA_DIR
chmod 770 $FTP_DATA_DIR

# Groep aanmaken en directory aan groep koppelen
groupadd $FTP_GROUP
chown :$FTP_GROUP $FTP_DATA_DIR

# FTP-gebruikers aanmaken en aan de groep toevoegen
useradd -m -d $FTP_DATA_DIR -s /sbin/nologin -G $FTP_GROUP ftpuser1
echo "ftpuser1:$FTPUSER1_PASSWORD" | chpasswd
useradd -m -d $FTP_DATA_DIR -s /sbin/nologin -G $FTP_GROUP ftpuser2
echo "ftpuser2:$FTPUSER2_PASSWORD" | chpasswd

# Admin-gebruiker toevoegen aan de FTP-groep
usermod -a -G $FTP_GROUP $ADMIN_USER

# Configuratie van vsftpd aanpassen
cat <<EOL > /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=\$USER
local_root=$FTP_DATA_DIR
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=1048
EOL

# Beveiligingsmaatregelen
echo "ftpuser1" | tee -a /etc/vsftpd.userlist
echo "ftpuser2" | tee -a /etc/vsftpd.userlist
echo $ADMIN_USER | tee -a /etc/vsftpd.userlist
echo "userlist_enable=YES" | tee -a /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" | tee -a /etc/vsftpd.conf
echo "userlist_deny=NO" | tee -a /etc/vsftpd.conf

# Service herstarten
systemctl restart vsftpd
systemctl enable vsftpd

# firewall allow ssh and ftp
ufw allow ssh
ufw allow ftp
ufw enable

echo "FTP-server configuratie voltooid. Alleen toegang tot $FTP_DATA_DIR toegestaan."
