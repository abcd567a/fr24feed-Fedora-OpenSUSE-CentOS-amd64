ASSETS_FOLDER=/usr/share/dump1090-assets
sudo mkdir -p ${ASSETS_FOLDER}

echo -e "\e[01;32mAdding EPEL repository... \e[0;39m"
sudo yum install -y epel-release

echo -e "\e[01;32mInstalling Tools & Dependencies.... \e[0;39m"
sudo yum install -y git
sudo yum install -y wget
sudo yum install -y make
sudo yum install -y gcc
sudo yum install -y cmake
sudo yum install -y usbutils
sudo yum install -y libusbx
sudo yum install -y libusbx-devel
sudo yum install -y ncurses-devel
sudo yum install -y rtl-sdr
sudo yum install -y rtl-sdr-devel
sudo yum install -y lighttpd



echo -e "\e[01;32mDownloading dump1090-fa Source Code from Github \e[0;39m"
cd ${ASSETS_FOLDER}
sudo git clone https://github.com/flightaware/dump1090.git dump1090-fa
cd ${ASSETS_FOLDER}/dump1090-fa
git fetch --all
git reset --hard origin/master
sudo make BLADERF=no DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')

echo -e "\e[01;32mCopying Executeable Binary to folder `/usr/bin/` \e[0;39m"
sudo cp ${ASSETS_FOLDER}/dump1090-fa/dump1090 /usr/bin/dump1090-fa
sudo cp ${ASSETS_FOLDER}/dump1090-fa/view1090 /usr/bin/view1090

echo -e "\e[01;32mCopying necessary files from cloned source code to the computer...\e[0;39m"
sudo mkdir -p /etc/default
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/dump1090-fa.default /etc/default/dump1090-fa

sudo mkdir -p /usr/share/dump1090-fa/
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/start-dump1090-fa /usr/share/dump1090-fa/start-dump1090-fa
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/generate-wisdom /usr/share/dump1090-fa/
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/upgrade-config /usr/share/dump1090-fa/
sudo mkdir -p /usr/lib/dump1090-fa
sudo cp ${ASSETS_FOLDER}/dump1090-fa/starch-benchmark  /usr/lib/dump1090-fa/

sudo mkdir -p /usr/share/skyaware/
sudo cp -r ${ASSETS_FOLDER}/dump1090-fa/public_html /usr/share/skyaware/html

sudo mkdir -p /usr/lib/systemd/system
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/dump1090-fa.service /usr/lib/systemd/system/dump1090-fa.service

echo -e "\e[01;32mAdding system user dump1090 and adding it to group rtlsdr... \e[0;39m"
echo -e "\e[01;32mThe user dump1090 will run the dump1090-fa service \e[0;39m"
sudo useradd --system dump1090
echo -e "\e[01;32mGroup rtlsdr was created when installing rtl-sdr, now adding the\e[0;39m"
echo -e "\e[01;32muser dump1090 to group rtlsdr to enable it to use rtlsdr Dongle ... \e[0;39m"
sudo usermod -a -G rtlsdr dump1090
sudo systemctl enable dump1090-fa

echo -e "\e[01;32mPerforming Lighttpd integration to display Skyaware Map ... \e[0;39m"
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/89-skyaware.conf /etc/lighttpd/conf.d/89-skyaware.conf
sudo cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/88-dump1090-fa-statcache.conf /etc/lighttpd/conf.d/88-dump1090-fa-statcache.conf
sudo chmod 666 /etc/lighttpd/lighttpd.conf
if [[ ! `grep "^server.modules += ( \"mod_alias\" )" /etc/lighttpd/lighttpd.conf` ]]; then
  echo "server.modules += ( \"mod_alias\" )" >> /etc/lighttpd/lighttpd.conf
fi
if [[ ! `grep "89-skyaware.conf" /etc/lighttpd/lighttpd.conf` ]]; then
  echo "include conf_dir + \"/conf.d/89-skyaware.conf\"" >> /etc/lighttpd/lighttpd.conf
fi
sudo sed -i 's/server.use-ipv6 = "enable"/server.use-ipv6 = "disable"/' /etc/lighttpd/lighttpd.conf
sudo chmod 644 /etc/lighttpd/lighttpd.conf
sudo systemctl enable lighttpd
sudo systemctl start lighttpd

echo -e "\e[01;32mConfiguring SELinux to run permissive for httpd \e[0;39m"
echo -e "\e[01;32mThis will enable lighttpd to pull aircraft data \e[0;39m"
echo -e "\e[01;32mfrom folder /var/run/dump1090-fa/ \e[0;39m"
echo -e "\e[39m   sudo semanage permissive -a httpd_t \e[39m"

sudo semanage permissive -a httpd_t

echo " "
echo -e "\e[01;32mConfiguring Firewall to permit display of SkyView from LAN/internet \e[0;39m"
echo -e "\e[39m   sudo firewall-cmd --add-service=http \e[39m"
echo -e "\e[39m   sudo firewall-cmd --runtime-to-permanent \e[39m"
echo -e "\e[39m   sudo firewall-cmd --reload \e[39m"

sudo firewall-cmd --add-service=http
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --reload
echo " "
echo -e "\e[01;32mSee the Web Interface (Map etc) at\e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware/ \e[39m" "\e[35m(IP-of-Computer/skyaware/) \e[39m"
echo -e "\e[01;32m   OR \e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8080 \e[39m" "\e[35m(IP-of-Computer:8080) \e[39m"
echo " "
echo -e "\e[01;31mREBOOT Computer ... REBOOT Computer ... REBOOT Computer \e[0;39m"
echo " "
