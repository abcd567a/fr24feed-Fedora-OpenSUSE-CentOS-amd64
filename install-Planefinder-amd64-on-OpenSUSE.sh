#!/bin/bash

BINARY_VERSION=pfclient_5.0.162_amd64
DOWNLOAD_LINK=http://client.planefinder.net
ASSETS_FOLDER=/usr/share/pfclient-assets
sudo mkdir ${ASSETS_FOLDER}

echo "Installing wget and tarr packages if not already installed"
zypper install -y wget
dnf install -y wget
zypper install -y tar
dnf install -y tar

echo "Downloading amd64 binary tarball " ${BINARY_VERSION}.tar.gz "from Planefinder.net"
wget -O ${ASSETS_FOLDER}/${BINARY_VERSION}.tar.gz "${DOWNLOAD_LINK}/${BINARY_VERSION}.tar.gz"

echo "extracting amd64 binary from tarball & copying to folder /usr/bin/"
tar zxvf  ${ASSETS_FOLDER}/${BINARY_VERSION}.tar.gz -C ${ASSETS_FOLDER}
cp ${ASSETS_FOLDER}/pfclient /usr/bin/pfclient

echo "Creating user pfc to run service"
useradd --system pfc

echo "Creating start file start-pfclient"
START_FILE=${ASSETS_FOLDER}/start-pfclient
touch ${START_FILE}
chmod 777 ${START_FILE}
echo "Writing code to config file start-pfclient"
/bin/cat <<EOM >${START_FILE}
#!/bin/sh

# Start script which  either starts pfclient with the configured
# arguments, or exits with status 64 to tell systemd
# not to auto-restart the service.

DAEMON=/usr/bin/pfclient

PIDFILE=/var/run/pfclient.pid
LOGFILE=/var/log/pfclient
CONFIGFILE=/etc/pfclient-config.json


if [ -f /etc/pfclient-config.json ]
then
    . /etc/pfclient-config.json
fi

exec /usr/bin/pfclient $DAEMON -- -d -i $PIDFILE -z $CONFIGFILE -y $LOGFILE $ 2>/var/log/pfclient/eror.log
# exec failed, do not restart
exit 64

EOM

chmod +x ${START_FILE}
chown pfc:pfc -R ${ASSETS_FOLDER}


echo "Creating Service file pfclient.service"
SERVICE_FILE=/lib/systemd/system/pfclient.service
touch ${SERVICE_FILE}
chmod 777 ${SERVICE_FILE}
/bin/cat <<EOM >${SERVICE_FILE}
# planefinder uploader service for systemd
# install in /lib/systemd/system/

[Unit]
Description=Planefinder Feeder
After=network-online.target

[Service]
Type=simple
SyslogIdentifier=pfclient
RuntimeDirectory=pfclient
RuntimeDirectoryMode=0755
User=pfc
PermissionsStartOnly=true
ExecStartPre=-/bin/mkdir -p /var/log/pfclient
ExecStartPre=-/bin/chown pfc /var/log/pfclient
ExecStart=${START_FILE}
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target

EOM

chmod 644 ${SERVICE_FILE}
systemctl enable pfclient
systemctl restart pfclient


echo -e "\e[01;32mConfiguring Firewall to permit display of  \e[0;39m"
echo -e "\e[01;32mPlanefinder Map & Settings web page at port 30053 from LAN/internet \e[0;39m"
echo -e "\e[39m   sudo firewall-cmd --add-port=30053/tcp \e[39m"
echo -e "\e[39m   sudo firewall-cmd --runtime-to-permanent \e[39m"

sudo firewall-cmd --add-port=30053/tcp
sudo firewall-cmd --runtime-to-permanent

echo " "
echo " "
echo -e "\e[32m INSTALLATION COMPLETED \e[39m"
echo -e "\e[32m=======================\e[39m"
echo -e "\e[32m PLEASE DO FOLLOWING:\e[39m"
echo -e "\e[32m=======================\e[39m"
echo -e "\e[32m SIGNUP:\e[39m"
echo -e "\e[32m In your browser, go to web interface at\e[39m"
echo -e "\e[39m     http://$(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):30053 \e[39m"
echo -e "\e[32m Fill necessary details to sign up / sign in\e[39m"
echo -e "\e[32m Use IP Address 127.0.0.1 and Port number 30005 when asked for these\e[39m"
echo -e "\e[31m If it fails to save settings when you hit button [Complete Configuration],\e[39m"
echo -e "\e[31m then restart pfclient by following command, and again hit [Complete Configuration] utton\e[39m"
echo "     sudo systemctl restart pfclient "
echo " "
echo " "
echo -e "\e[32mTo see status\e[39m sudo systemctl status pfclient"
echo -e "\e[32mTo restart\e[39m    sudo systemctl restart pfclient"
echo -e "\e[32mTo stop\e[39m       sudo systemctl stop pfclient"


