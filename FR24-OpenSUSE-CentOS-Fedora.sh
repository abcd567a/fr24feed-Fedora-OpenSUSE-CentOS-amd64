#!/bin/bash

ASSETS_FOLDER=/usr/share/fr24-assets
FR24_LINUX_ARCHIVE=fr24feed_1.0.34-0_amd64.tgz
echo "Creating folder fr24-assets"
sudo mkdir ${ASSETS_FOLDER}
echo "Downloading fr24feed amd64 binary file from Flightradar24"
sudo wget -O ${ASSETS_FOLDER}/${FR24_LINUX_ARCHIVE} "https://repo-feed.flightradar24.com/linux_x86_64_binaries/${FR24_LINUX_ARCHIVE}"

echo "Unzipping downloaded file"
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
logmode="1"
logpath="/var/log/fr24feed"
mlat="yes"
mlat-without-gps="yes"
EOM
sudo chmod 644 ${CONFIG_FILE}

SERVICE_FILE=/etc/systemd/system/fr24feed.service
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
ExecStartPre=-/bin/mkdir -p /var/log/fr24feed
ExecStartPre=-/bin/mkdir -p /run/fr24feed
ExecStartPre=-/bin/touch /dev/shm/decoder.txt
ExecStartPre=-/bin/chown fr24 /dev/shm/decoder.txt /run/fr24feed /var/log/fr24feed
ExecStart=/usr/bin/fr24feed
User=fr24
PermissionsStartOnly=true
StandardOutput=null

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

echo -e "\e[32mCreation of necessary files of \"fr24feed\" completed...\e[39m"

echo -e "\e[32mSignup for \"fr24feed\" ...\e[39m"
## Read current timezone and store in a variable "TZ_ORIGINAL"
TZ_ORIGINAL=`timedatectl show | grep Timezone= | cut -d= -f2-`
echo ${TZ_ORIGINAL}

##Change timezone temporarily to GMT+0
export TZ=GMT+0

##Signup
sudo fr24feed --signup

##Revert to original timezone
export TZ=${TZ_ORIGINAL}

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
echo -e "\e[01;32m    Your fr24keys are in following config file\e[39m"
echo -e "\e[01;33m    sudo nano /etc/fr24feed.ini  \e[39m"
echo " "
echo -e "\e[01;33m    To restart fr24feed:  sudo systemctl restart fr24feed  \e[39m"
echo " "
echo -e "\e[01;33m    To check log of fr24feed:  cat /var/log/fr24feed/fr24feed.log  \e[39m"
echo " "
echo -e "\e[01;33m    To check status of fr24feed:  sudo fr24feed-status  \e[39m"
echo " "
echo -e "\e[01;31mRESTART fr24feed ... RESTART fr24feed ... RESTART fr24feed ... \e[39m"
echo -e "\e[01;31mRESTART fr24feed ... RESTART fr24feed ... RESTART fr24feed ... \e[39m"
echo " "
echo -e "\e[01;33m    sudo systemctl restart fr24feed \e[39m"
echo " "
echo -e "\e[01;33mAfter restarting fr24feed, check status of fr24feed:\e[0;39m"
echo -e "\e[39m     sudo fr24feed-status  \e[39m"
echo -e "\e[01;32mSee the Web Interface (Status & Settings) at\e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8754 \e[39m" "\e[35m(IP-of-Computer:8754) \e[39m"


