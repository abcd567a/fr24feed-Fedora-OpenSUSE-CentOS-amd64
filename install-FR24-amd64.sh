#!/bin/bash

FR24_LINUX_ARCHIVE=fr24feed_1.0.48-0_amd64.tgz
ASSETS_FOLDER=/usr/share/fr24feed-assets
echo "Creating folder" ${ASSETS_FOLDER}
sudo mkdir ${ASSETS_FOLDER}
echo "Downloading fr24feed amd64 binary file from Flightradar24"
sudo wget -O ${ASSETS_FOLDER}/${FR24_LINUX_ARCHIVE} "https://repo-feed.flightradar24.com/linux_binaries/${FR24_LINUX_ARCHIVE}"

echo "Unzipping downloaded file"
sudo dnf install -y tar
sudo zypper install -y tar
sudo tar xvzf ${ASSETS_FOLDER}/${FR24_LINUX_ARCHIVE} -C ${ASSETS_FOLDER}
sudo cp ${ASSETS_FOLDER}/fr24feed_amd64/fr24feed /usr/bin/

echo -e "\e[32mCreating necessary files for fr24feed......\e[39m"

CONFIG_FILE=/etc/fr24feed.ini
sudo touch ${CONFIG_FILE}
sudo chmod 666 ${CONFIG_FILE}
echo "Writing code to config file fr24feed.ini"
/bin/cat << \EOM >${CONFIG_FILE}
receiver="avr-tcp"
host="127.0.0.1:30002"
fr24key="xxxxxxxxxxxxxxxx"
bs="no"
raw="no"
mlat="yes"
mlat-without-gps="yes"
EOM
sudo chmod 644 ${CONFIG_FILE}

SERVICE_FILE=/usr/lib/systemd/system/fr24feed.service
sudo touch ${SERVICE_FILE}
sudo chmod 666 ${SERVICE_FILE}
/bin/cat << \EOM >${SERVICE_FILE}
[Unit]
Description=Flightradar24 Feeder
After=network-online.target

[Service]
Type=simple
Restart=always
LimitCORE=infinity
RuntimeDirectory=fr24feed
RuntimeDirectoryMode=0755
ExecStartPre=-/bin/mkdir -p /run/fr24feed
ExecStartPre=-/bin/touch /dev/shm/decoder.txt
ExecStartPre=-/bin/chown fr24 /dev/shm/decoder.txt /run/fr24feed
ExecStart=/usr/bin/fr24feed
ExecStop=/bin/kill -TERM $MAINPID
User=fr24
PermissionsStartOnly=true
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOM
sudo chmod 644 ${SERVICE_FILE}

sudo useradd --system fr24

sudo systemctl enable fr24feed


wget -O ${ASSETS_FOLDER}/init-functions "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/fr24/init-functions"
wget -O ${ASSETS_FOLDER}/00-verbose "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/fr24/init-functions.d/00-verbose"
wget -O ${ASSETS_FOLDER}/40-systemd "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/fr24/init-functions.d/40-systemd"
wget -O ${ASSETS_FOLDER}/fr24feed-status "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/fr24/fr24feed-status"
sudo chmod +x ${ASSETS_FOLDER}/fr24feed-status

INIT_FUNCTIONS_FOLDER=/lib/lsb/
sudo mkdir -p ${INIT_FUNCTIONS_FOLDER}
sudo cp ${ASSETS_FOLDER}/init-functions ${INIT_FUNCTIONS_FOLDER}/init-functions

INIT_FUNCTIONS_D_FOLDER=${INIT_FUNCTIONS_FOLDER}/init-functions.d
sudo mkdir -p ${INIT_FUNCTIONS_D_FOLDER}
sudo cp ${ASSETS_FOLDER}/00-verbose ${INIT_FUNCTIONS_D_FOLDER}/00-verbose
sudo cp ${ASSETS_FOLDER}/40-systemd ${INIT_FUNCTIONS_D_FOLDER}/40-systemd

STATUS_FILE_FOLDER=/usr/bin
sudo cp ${ASSETS_FOLDER}/fr24feed-status ${STATUS_FILE_FOLDER}/fr24feed-status

echo -e "\e[01;32mConfiguring Firewall to permit display of  \e[0;39m"
echo -e "\e[01;32mFR24 Status & Settings web page at port 8754 from LAN/internet \e[0;39m"
echo -e "\e[39m   sudo firewall-cmd --add-port=8754/tcp \e[39m"
echo -e "\e[39m   sudo firewall-cmd --runtime-to-permanent \e[39m"

sudo firewall-cmd --add-port=8754/tcp
sudo firewall-cmd --runtime-to-permanent

##Signup
echo -e "\e[32mSignup for \"fr24feed\" ...\e[39m"
sudo fr24feed --signup
echo " "
read -p "Press ENTER KEY to continue: "

## Setting fr24feed.ini to receiver="avr-tcp"
sed -i '/receiver/c\receiver=\"avr-tcp\"' /etc/fr24feed.ini
sed -i '/host/c\host=\"127.0.0.1:30002\"' /etc/fr24feed.ini
if [[ ! `grep 'host' /etc/fr24feed.ini` ]]; then echo 'host="127.0.0.1:30002"' >>  /etc/fr24feed.ini; fi
sed -i '/logpath/c\logpath=\"/var/log/fr24feed\"' /etc/fr24feed.ini
sed -i '/raw/c\raw=\"no\"' /etc/fr24feed.ini
sed -i '/bs/c\bs=\"no\"' /etc/fr24feed.ini
sed -i '/mlat=/c\mlat=\"yes\"' /etc/fr24feed.ini
sed -i '/mlat-without-gps=/c\mlat-without-gps=\"yes\"' /etc/fr24feed.ini
echo " "
echo " "
echo -e "\e[01;32mInstallation of fr24feed completed...\e[39m"
echo " "
echo -e "\e[01;33m Your fr24key is in following config file\e[39m"
echo -e "\e[01;39m      sudo nano /etc/fr24feed.ini  \e[39m"
echo " "
echo -e "\e[01;31mRESTART fr24feed ... RESTART fr24feed ... RESTART fr24feed ... \e[39m"
echo -e "\e[01;31mRESTART fr24feed ... RESTART fr24feed ... RESTART fr24feed ... \e[39m"
echo " "
echo -e "\e[01;39m       sudo systemctl restart fr24feed \e[39m"
echo " "
echo -e "\e[01;39m       sudo systemctl status fr24feed \e[39m"
echo " "
echo -e "\e[01;33m Few minutes after restarting fr24feed, check status:\e[0;39m"
echo -e "\e[01;39m       sudo fr24feed-status  \e[39m"
echo " "
echo -e "\e[01;33m To check log of fr24feed: \e[39m"
echo -e "\e[01;39m      sudo journalctl -u fr24feed -e  \e[39m"
echo " "
echo -e "\e[01;32m See the Web Interface (Status & Settings) at\e[39m"
echo -e "\e[01;39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8754 \e[39m" "\e[01;35m(IP-of-Computer:8754) \e[0;39m"


