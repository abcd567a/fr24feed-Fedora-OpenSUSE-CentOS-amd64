ASSETS_FOLDER=/usr/share/dump1090-assets
sudo mkdir -p ${ASSETS_FOLDER}

echo -e "\e[01;32mAdding EPEL repository... \e[0;39m"
sudo yum install -y epel-release

echo -e "\e[01;32mInstalling Tools & Dependencies.... \e[0;39m"
sudo yum install -y git
sudo yum install -y wget
sudo yum install -y make
sudo yum install -y cmake
sudo yum install -y gcc
sudo yum install -y usbutils
sudo yum install -y libusbx
sudo yum install -y libusbx-devel
sudo yum install -y ncurses-devel
sudo yum install -y rtl-sdr 
sudo yum install -y rtl-sdr-devel
sudo yum install -y lighttpd



echo -e "\e[01;32mDownloading dump1090-mutability Source Code from Github \e[0;39m"
cd ${ASSETS_FOLDER}
sudo git clone -b unmaintained https://github.com/mutability/dump1090.git
cd ${ASSETS_FOLDER}/dump1090
sudo make 
## sudo make DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')
echo -e "\e[01;32mCopying Executeable Binary to folder `/usr/bin/` \e[0;39m"
sudo cp ${ASSETS_FOLDER}/dump1090/dump1090 /usr/bin/dump1090-mutability

sudo wget -O ${ASSETS_FOLDER}/dump1090-mutability.default  https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/mutab/dump1090-mutability.default
sudo wget -O ${ASSETS_FOLDER}/start-dump1090-mutability "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/mutab/start-dump1090-mutability"
sudo wget -O ${ASSETS_FOLDER}/89-dump1090-mutability.conf "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/mutab/89-dump1090-mutability.conf"
sudo wget -O ${ASSETS_FOLDER}/dump1090-mutability.service "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/mutab/dump1090-mutability.service"


echo -e "\e[01;32mCopying necessary downloaded files to the computer...\e[0;39m"
sudo mkdir -p /usr/share/dump1090-mutability
sudo cp -r ${ASSETS_FOLDER}/dump1090/public_html /usr/share/dump1090-mutability/html
sudo chmod +x ${ASSETS_FOLDER}/start-dump1090-mutability
sudo cp ${ASSETS_FOLDER}/start-dump1090-mutability /usr/share/dump1090-mutability/

sudo mkdir -p /etc/default
sudo cp ${ASSETS_FOLDER}/dump1090-mutability.default /etc/default/dump1090-mutability
sudo cp ${ASSETS_FOLDER}/dump1090-mutability.service  /lib/systemd/system/

sudo mkdir -p /etc/lighttpd/conf.d
sudo cp ${ASSETS_FOLDER}/89-dump1090-mutability.conf  /etc/lighttpd/conf.d/

echo -e "\e[01;32mAdding system user dump1090 and adding it to group rtlsdr... \e[0;39m"
echo -e "\e[01;32mThe user dump1090 will run the dump1090-fa service \e[0;39m"
sudo useradd --system dump1090 
echo -e "\e[01;32mInstalling rtl-sdr to create group rtlsdr and adding the\e[0;39m"
echo -e "\e[01;32muser dump1090 to group rtlsdr to enable it to use rtlsdr Dongle ... \e[0;39m"
sudo usermod -a -G rtlsdr dump1090

echo -e "\e[01;32mPerforming Lighttpd integration to display Map ... \e[0;39m"
sudo chmod 666 /etc/lighttpd/lighttpd.conf
if [[ ! `grep "^server.modules += ( \"mod_alias\" )" /etc/lighttpd/lighttpd.conf` ]]; then
  echo "server.modules += ( \"mod_alias\" )" >> /etc/lighttpd/lighttpd.conf;
fi
echo "include conf_dir + \"/conf.d/89-dump1090-mutability.conf\"" >> /etc/lighttpd/lighttpd.conf
sudo sed -i 's/server.use-ipv6 = "enable"/server.use-ipv6 = "disable"/' /etc/lighttpd/lighttpd.conf
sudo chmod 644 /etc/lighttpd/lighttpd.conf
sudo systemctl enable lighttpd
sudo systemctl start lighttpd

sudo lighty-enable-mod dump1090
sudo service lighttpd force-reload
sudo systemctl enable dump1090-mutability
sudo systemctl restart dump1090-mutability


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
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/dump1090-mutability/ \e[39m" "\e[35m(IP-of-Computer/dump1090-mutability/) \e[39m"
echo -e "\e[01;32m   OR \e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8080 \e[39m" "\e[35m(IP-of-Computer:8080) \e[39m"
echo " "
echo -e "\e[01;31mREBOOT Computer ... REBOOT Computer ... REBOOT Computer \e[0;39m"
echo " "
