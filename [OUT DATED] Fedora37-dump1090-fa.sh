#!/bin/bash

ASSETS_FOLDER=/usr/share/dump1090-assets
sudo mkdir -p ${ASSETS_FOLDER}

echo -e "\e[01;32mInstalling Tools & Dependencies.... \e[0;39m"
dnf makecache
dnf install -y git
dnf install -y wget
dnf install -y gcc
dnf install -y make
dnf install -y cmake
dnf install -y libusb-devel
dnf install -y libusbx-devel
dnf install -y ncurses-devel
dnf install -y lighttpd
dnf install -y rtl-sdr
dnf install -y rtl-sdr-devel

##echo -e "\e[01;32mBuild & Install librtlsdr from source code. \e[0;39m"
cd ${ASSETS_FOLDER}
git clone --depth 1 https://github.com/steve-m/librtlsdr.git
cd ${ASSETS_FOLDER}/librtlsdr
mkdir build && cd build
cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON -DLIB_INSTALL_DIR=/usr/lib64 -DCMAKE_INSTALL_PREFIX=/usr
make
make install
ldconfig

echo -e "\e[01;32mBuilding dump1090-fa linux binary from source code \e[0;39m"
cd ${ASSETS_FOLDER}
git clone -b dev --depth 1 https://github.com/flightaware/dump1090.git dump1090-fa
cd ${ASSETS_FOLDER}/dump1090-fa
make RTLSDR=yes DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')

echo -e "\e[01;32mCopying necessary files from cloned source code to the computer...\e[0;39m"

cp ${ASSETS_FOLDER}/dump1090-fa/dump1090 /usr/bin/dump1090-fa
cp ${ASSETS_FOLDER}/dump1090-fa/view1090 /usr/bin/view1090

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
echo -e "\e[01;32mHave installed rtl-sdr to create group rtlsdr, now adding the\e[0;39m"
echo -e "\e[01;32muser dump1090 to group rtlsdr to enable it to use rtlsdr Dongle ... \e[0;39m"

usermod -a -G rtlsdr dump1090
systemctl enable dump1090-fa

echo -e "\e[01;32mPerforming Lighttpd integration to display Skyaware Map ... \e[0;39m"
cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/89-skyaware.conf /etc/lighttpd/conf.d/89-skyaware.conf
cp ${ASSETS_FOLDER}/dump1090-fa/debian/lighttpd/88-dump1090-fa-statcache.conf /etc/lighttpd/conf.d/88-dump1090-fa-statcache.conf

chmod 666 /etc/lighttpd/lighttpd.conf
if [[ ! `grep "^server.modules += ( \"mod_alias\" )" /etc/lighttpd/lighttpd.conf` ]]; then
  echo "server.modules += ( \"mod_alias\" )" >> /etc/lighttpd/lighttpd.conf
fi
if [[ ! `grep "89-skyaware.conf" /etc/lighttpd/lighttpd.conf` ]]; then
  echo "include conf_dir + \"/conf.d/89-skyaware.conf\"" >> /etc/lighttpd/lighttpd.conf
fi
sed -i 's/server.use-ipv6 = "enable"/server.use-ipv6 = "disable"/' /etc/lighttpd/lighttpd.conf
chmod 644 /etc/lighttpd/lighttpd.conf

systemctl enable lighttpd
systemctl start lighttpd

echo -e "\e[01;32mConfiguring SELinux to run permissive for httpd \e[0;39m"
echo -e "\e[01;32mThis will enable lighttpd to pull aircraft data \e[0;39m"
echo -e "\e[01;32mfrom folder /var/run/dump1090-fa/ \e[0;39m"
echo -e "\e[39m   sudo semanage permissive -a httpd_t \e[39m"

semanage permissive -a httpd_t

echo " "
echo -e "\e[01;32mConfiguring Firewall to permit display of SkyView from LAN/internet \e[0;39m"
echo -e "\e[39m   sudo firewall-cmd --add-service=http \e[39m"
echo -e "\e[39m   sudo firewall-cmd --add-port=8080/tcp \e[39m"
echo -e "\e[39m   sudo firewall-cmd --runtime-to-permanent \e[39m"
echo -e "\e[39m   sudo firewall-cmd --reload \e[39m"

firewall-cmd --add-service=http
firewall-cmd --add-port=8080/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
echo " "
echo -e "\e[01;32mSee the Web Interface (Map etc) at\e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*')/skyaware/ \e[39m" "\e[35m(IP-of-Computer/skyaware/) \e[39m"
echo -e "\e[01;32m   OR \e[0;39m"
echo -e "\e[39m     $(ip route | grep -m1 -o -P 'src \K[0-9,.]*'):8080 \e[39m" "\e[35m(IP-of-Computer:8080) \e[39m"
echo " "
echo -e "\e[01;31mREBOOT Computer ... REBOOT Computer ... REBOOT Computer \e[0;39m"
echo " "

