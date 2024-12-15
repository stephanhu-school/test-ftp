#!/bin/bash

# Definieer variabelen voor gebruikersnamen en wachtwoorden
ADMIN_USER=$1
FTPUSER1_PASSWORD=$2
FTPUSER2_PASSWORD=$3
FTP_DATA_DIR=$4
FTP_GROUP="ftpusers"

# Installeer benodigde pakketten vsftpd, ufw en whois
apt-get update -y
apt-get install -y vsftpd ufw whois

# Maak de FTP data directory aan en stel permissies in
mkdir -p $FTP_DATA_DIR
chmod 770 $FTP_DATA_DIR

# Maak een FTP gebruikersgroep aan en stel groepsrechten in op de data directory
groupadd $FTP_GROUP
chown :$FTP_GROUP $FTP_DATA_DIR

# Voeg ftpuser1 en ftpuser2 toe aan de FTP groep en stel hun wachtwoorden in
useradd -m -d $FTP_DATA_DIR -G $FTP_GROUP ftpuser1
echo "ftpuser1:$FTPUSER1_PASSWORD" | chpasswd
useradd -m -d $FTP_DATA_DIR -G $FTP_GROUP ftpuser2
echo "ftpuser2:$FTPUSER2_PASSWORD" | chpasswd

# Voeg de beheerdersgebruiker toe aan de FTP groep
usermod -a -G $FTP_GROUP $ADMIN_USER

# Maak het vsftpd configuratiebestand aan met de benodigde instellingen
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

# Voeg gebruikers toe aan de vsftpd gebruikerslijst en pas de configuratie aan
echo "ftpuser1" | tee -a /etc/vsftpd.userlist
echo "ftpuser2" | tee -a /etc/vsftpd.userlist
echo $ADMIN_USER | tee -a /etc/vsftpd.userlist
echo "userlist_enable=YES" | tee -a /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" | tee -a /etc/vsftpd.conf
echo "userlist_deny=NO" | tee -a /etc/vsftpd.conf

# Herstart de vsftpd service en schakel deze in bij opstarten
systemctl restart vsftpd
systemctl enable vsftpd

# Configureer de firewall om SSH en FTP verkeer toe te staan
ufw allow ssh
ufw allow ftp
ufw enable

echo "FTP-server configuratie voltooid. Alleen toegang tot $FTP_DATA_DIR toegestaan."
