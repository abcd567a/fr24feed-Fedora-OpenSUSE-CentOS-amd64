#!/bin/bash
set -e

BUILD_FOLDER=/usr/share/piaware-builder
sudo mkdir -p ${BUILD_FOLDER}

dnf install lsb_release
OS_ID=`lsb-release -si`
echo -e "\e[01;32mUpdating repository... \e[0;39m"
if [[ ! ${OS_ID} == "Fedora" ]]; then dnf install epel-release; fi
dnf update
dnf makecache

echo -e "\e[01;32mInstalling Tools & Dependencies.... \e[0;39m"
dnf install autoconf -y
dnf install ncurses-devel -y
dnf install net-tools -y
dnf install openssl-devel -y
dnf install openssl-perl -y
dnf install python3-devel -y
dnf install tcl-devel -y
dnf install tcllib -y
dnf install tcltls -y
dnf install tk -y
dnf install tcl -y
if [[ ${OS_ID} == "Fedora" ]]; then dnf install tclx; fi

echo -e "\e[01;32mBuilding & Installing tcllauncher using Source Code from Github \e[0;39m"
cd ${BUILD_FOLDER}
git clone https://github.com/flightaware/tcllauncher.git
cd tcllauncher
autoconf
./configure --prefix=/usr/share/piaware-builder --with-tcl=/usr/lib64/tclConfig.sh
make
make install

echo -e "\e[01;95mBuilding & Installing itcl using Source Code from Github \e[0;39m"
cd ${BUILD_FOLDER}
git clone https://github.com/tcltk/itcl.git
cd itcl
./configure
make all
make test
ln -sf itclWidget/tclconfig tclconfig
make install
ln -sf /usr/lib/itcl4.3.2 /usr/share/tcl8.6

echo -e "\e[01;95mBuilding & Installing mlat-client & fa-mlat-client using Source Code from Github \e[0;39m"
cd ${BUILD_FOLDER}
git clone https://github.com/mutability/mlat-client.git
cd mlat-client
./setup.py build
./setup.py install

echo -e "\e[01;95mBuilding & Installing faup1090 using Source Code from Github \e[0;39m"
cd ${BUILD_FOLDER}
git clone https://github.com/flightaware/dump1090 faup1090
cd faup1090
make faup1090

echo -e "\e[01;95mBuilding & Installing PIAWARE using Source Code from Github \e[0;39m"
cd ${BUILD_FOLDER}
git clone https://github.com/flightaware/piaware.git
cd piaware
make install
ln -sf /usr/lib/piaware_packages /usr/share/tcl8.6
ln -sf /usr/lib/fa_adept_codec /usr/share/tcl8.6
cp ${BUILD_FOLDER}/faup1090/faup1090 /usr/lib/piaware/helpers/
cp /usr/local/bin/fa-mlat-client /usr/lib/piaware/helpers/
install -Dm440 ${BUILD_FOLDER}/piaware/etc/piaware.sudoers /etc/sudoers.d/piaware
systemctl enable generate-pirehose-cert.service

adduser --system piaware
sudo install -d -o piaware -g piaware /var/cache/piaware

systemctl enable piaware.service
systemctl start piaware.service

