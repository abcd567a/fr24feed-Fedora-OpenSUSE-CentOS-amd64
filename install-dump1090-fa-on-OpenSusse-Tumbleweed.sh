#!/bin/bash

ASSETS_FOLDER=/usr/share/dump1090-assets
sudo mkdir -p ${ASSETS_FOLDER}

echo -e "\e[01;32mUpdating repositories.... \e[0;39m"
zypper refresh

echo -e "\e[01;32mInstalling Tools & Dependencies.... \e[0;39m"
zypper install -y git
zypper install -y make
zypper install -y gcc
zypper install -y ncurses-devel
zypper install -y rtl-sdr
zypper install -y rtl-sdr-devel
zypper install -y lighttpd

cd ${ASSETS_FOLDER}

echo -e "\e[01;32mBuilding dump1090-fa linux binary from source code \e[0;39m"
cd ${ASSETS_FOLDER}
## git clone https://github.com/flightaware/dump1090.git dump1090-fa
sudo git clone -b dev --depth 1 https://github.com/flightaware/dump1090.git dump1090-fa
cd ${ASSETS_FOLDER}/dump1090-fa
## make RTLSDR=yes DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')
make RTLSDR=yes DUMP1090_VERSION=$(head -1 debian/changelog | sed 's/.*(\([^)]*\).*/\1/')

echo -e "\e[01;32mCopying necessary files from cloned source code to the computer...\e[0;39m"
cp ${ASSETS_FOLDER}/dump1090-fa/dump1090 /usr/bin/dump1090-fa
mkdir -p /etc/default
cp ${ASSETS_FOLDER}/dump1090-fa/debian/dump1090-fa.default /etc/default/dump1090-fa
mkdir -p /usr/share/dump1090-fa/
cp ${ASSETS_FOLDER}/dump1090-fa/debian/start-dump1090-fa /usr/share/dump1090-fa/start-dump1090-fa
cp ${ASSETS_FOLDER}/dump1090-fa/debian/generate-wisdom /usr/share/dump1090-fa/
cp ${ASSETS_FOLDER}/dump1090-fa/debian/upgrade-config /usr/share/dump1090-fa/
mkdir -p /usr/lib/dump1090-fa
cp ${ASSETS_FOLDER}/dump1090-fa/starch-benchmark  /usr/lib/dump1090-fa/
mkdir -p /usr/share/skyaware/
cp -r ${ASSETS_FOLDER}/dump1090-fa/public_html /usr/share/skyaware/html
mkdir -p /usr/lib/systemd/system
cp ${ASSETS_FOLDER}/dump1090-fa/debian/dump1090-fa.service /usr/lib/systemd/system/dump1090-fa.service

echo -e "\e[01;32mAdding system user dump1090 and adding it to group rtlsdr... \e[0;39m"
echo -e "\e[01;32mThe user dump1090 will run the dump1090-fa service \e[0;39m"
useradd --system dump1090 
echo -e "\e[01;32mInstalling rtl-sdr to create group rtlsdr and adding the\e[0;39m"
echo -e "\e[01;32muser dump1090 to group rtlsdr to enable it to use rtlsdr Dongle ... \e[0;39m"
usermod -a -G rtlsdr dump1090
systemctl enable dump1090-fa

echo -e "\e[01;32mPerforming Lighttpd integration to display Skyaware Map ... \e[0;39m"
cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/89-skyaware.conf /etc/lighttpd/conf.d/89-skyaware.conf
cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/88-dump1090-fa-statcache.conf /etc/lighttpd/conf.d/88-dump1090-fa-statcache.conf
chmod 666 /etc/lighttpd/lighttpd.conf
echo "server.modules += ( \"mod_alias\" )" >> /etc/lighttpd/lighttpd.conf
echo "include \"/etc/lighttpd/conf.d/89-skyaware.conf\"" >> /etc/lighttpd/lighttpd.conf
sed -i 's/server.use-ipv6 = "enable"/server.use-ipv6 = "disable"/' /etc/lighttpd/lighttpd.conf
chmod 644 /etc/lighttpd/lighttpd.conf
systemctl enable lighttpd
systemctl start lighttpd

echo " "
echo -e "\e[01;32mConfiguring Firewall to permit display of SkyView from LAN/internet \e[0;39m"
echo -e "\e[39m   sudo firewall-cmd --zone=public --add-service=http --permanent \e[39m"
echo -e "\e[39m   sudo firewall-cmd --zone=public --add-service=https --permanent \e[39m"
echo -e "\e[39m   sudo firewall-cmd --reload \e[39m"

firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-service=https --permanent
firewall-cmd --reload

echo " "
echo -e "\e[01;32mInstallation of dump1090-fa completed....\e[0;39m"
echo -e "\e[01;32mSee the Web Interface (Map etc) at\e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware/ \e[39m" "\e[35m(IP-of-Computer/skyaware/) \e[39m"
echo -e "\e[01;32m   OR \e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8080 \e[39m" "\e[35m(IP-of-Computer:8080) \e[39m"
echo " "
echo -e "\e[01;32mControl dump1090-fa by following commands \e[0;39m"
echo -e "\e[01;39m   sudo systemctl status dump1090-fa\e[0;39m"
echo -e "\e[01;39m   sudo systemctl restart dump1090-fa\e[0;39m"
echo " "
echo -e "\e[01;31mREBOOT Computer ... REBOOT Computer ... REBOOT Computer \e[0;39m"
echo " "

