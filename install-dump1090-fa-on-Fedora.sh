#!/bin/bash

INSTALL_FOLDER=/usr/share/dump1090-assets
sudo mkdir -p ${INSTALL_FOLDER}
echo " Installing Tools & Dependencies...."
sudo dnf install -y git
sudo dnf install -y wget
sudo dnf install -y make
sudo dnf install -y cmake
sudo dnf install -y libusbx-devel
sudo dnf install -y ncurses-devel
sudo dnf install -y lighttpd

echo "Build & Install librtlsdr from source code."
cd ${INSTALL_FOLDER}
git clone https://github.com/steve-m/librtlsdr.git
cd ${INSTALL_FOLDER}/librtlsdr
sudo mkdir build && cd build
sudo cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON -DLIB_INSTALL_DIR=/usr/lib64 -DCMAKE_INSTALL_PREFIX=/usr
sudo make
sudo make install
sudo ldconfig

echo "Building dump1090-fa linux binary from source code"
cd ${INSTALL_FOLDER}
sudo git clone https://github.com/flightaware/dump1090.git dump1090-fa
cd ${INSTALL_FOLDER}/dump1090-fa
sudo make BLADERF=no DUMP1090_VERSION=$(git describe --tags | sed 's/-.*//')

echo "Copying necessary files from cloned source code to the computer  "
sudo cp ${INSTALL_FOLDER}/dump1090-fa/dump1090 /usr/bin/dump1090-fa
sudo cp ${INSTALL_FOLDER}/dump1090-fa/debian/dump1090-fa.default /etc/default/dump1090-fa
sudo cp ${INSTALL_FOLDER}/dump1090-fa/debian/dump1090-fa.service /usr/lib/systemd/system/dump1090-fa.service
sudo mkdir -p /usr/share/dump1090-fa/
sudo cp ${INSTALL_FOLDER}/dump1090-fa/debian/start-dump1090-fa /usr/share/dump1090-fa/start-dump1090-fa
sudo mkdir -p /usr/share/skyaware/
sudo cp -r ${INSTALL_FOLDER}/dump1090-fa/public_html /usr/share/skyaware/html

echo "Adding system user dump1090 and adding it to group rtlsdr"
echo "The user dump1090 will run the service"
sudo useradd --system dump1090
sudo usermod -a -G rtlsdr dump1090
sudo systemctl enable dump1090-fa

echo "Performing Lighttpd integration to display Skyaware Map"
sudo cp ${INSTALL_FOLDER}/dump1090-fa/debian/lighttpd/89-skyaware.conf /etc/lighttpd/conf.d/89-skyaware.conf
sudo cp ${INSTALL_FOLDER}/dump1090-fa/debian/lighttpd/88-dump1090-fa-statcache.conf /etc/lighttpd/conf.d/88-dump1090-fa-statcache.conf
sudo chmod 666 /etc/lighttpd/lighttpd.conf
echo "server.modules += ( \"mod_alias\" )" >> /etc/lighttpd/lighttpd.conf
echo "include \"/etc/lighttpd/conf.d/89-skyaware.conf\"" >> /etc/lighttpd/lighttpd.conf
sudo sed -i 's/server.use-ipv6 = "enable"/server.use-ipv6 = "disable"/' /etc/lighttpd/lighttpd.conf
sudo chmod 644 /etc/lighttpd/lighttpd.conf
sudo systemctl enable lighttpd
sudo systemctl start lighttpd

echo "Configure SELinux to run permissive for httpd"
echo "This will enable lighttpd to pull aircraft data from folder /var/run/dump1090-fa/ :"
sudo semanage permissive -a httpd_t

echo "Configure Firewall to permit display of SkyView from LAN/internet"
sudo firewall-cmd --add-service=http
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --reload


