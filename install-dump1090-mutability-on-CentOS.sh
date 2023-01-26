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
sudo git clone https://github.com/mutability/dump1090.git
cd ${ASSETS_FOLDER}/dump1090
git fetch --all
git reset --hard origin/master
sudo make DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')
echo -e "\e[01;32mCopying Executeable Binary to folder `/usr/bin/` \e[0;39m"
sudo cp ${ASSETS_FOLDER}/dump1090/dump1090 /usr/bin/dump1090-mutability

sudo wget -O ${ASSETS_FOLDER}/dump1090-mutability.init "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/raw/main/dump1090-mutability.init"
sudo wget -O ${ASSETS_FOLDER}/dump1090-mutability.default "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/blob/main/dump1090-mutability.default"
sudo wget -O ${ASSETS_FOLDER}/89-dump1090.conf "https://github.com/abcd567a/fr24feed-Fedora-OpenSUSE-CentOS-amd64/blob/main/89-dump1090.conf"

echo -e "\e[01;32mCopying necessary files from cloned source code to the computer...\e[0;39m"
sudo mkdir -p /etc/init.d
sudo cp ${ASSETS_FOLDER}/dump1090-mutability.init /etc/init.d/dump1090-mutability
sudo mkdir -p /etc/default
sudo cp ${ASSETS_FOLDER}/dump1090-mutability.default /etc/default/dump1090-mutability
sudo mkdir -p /etc/lighttpd/conf.d
sudo cp ${ASSETS_FOLDER}/89-dump1090.conf  /etc/lighttpd/conf.d/

chkconfig --add dump1090-mutability 
chkconfig --level 2345 dump1090-mutability on

echo -e "\e[01;32mAdding system user dump1090 and adding it to group rtlsdr... \e[0;39m"
echo -e "\e[01;32mThe user dump1090 will run the dump1090-fa service \e[0;39m"
sudo useradd --system dump1090 
echo -e "\e[01;32mInstalling rtl-sdr to create group rtlsdr and adding the\e[0;39m"
echo -e "\e[01;32muser dump1090 to group rtlsdr to enable it to use rtlsdr Dongle ... \e[0;39m"
sudo usermod -a -G rtlsdr dump1090

echo -e "\e[01;32mPerforming Lighttpd integration to display Map ... \e[0;39m"
sudo lighty-enable-mod dump1090
sudo service lighttpd force-reload

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
