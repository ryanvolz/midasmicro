#!/bin/sh

## install gnuradio
sudo apt-get install -y gnuradio-dev

## install patched uhd
sudo dpkg -i uhd-patched/*`lsb_release -cs`*.deb
sudo apt-get install -fy
sudo usermod -G usrp -a midasop
# replace rmem_max in sysctl config
cat >>uhd-usrp2.conf <<'EOL'
# USRP2 gigabit ethernet transport tuning
net.core.rmem_max=100000000
net.core.wmem_max=1048576
EOL
sudo mv uhd-usrp2.conf /etc/sysctl.d/uhd-usrp2.conf

## make sure submodules are up to date
git submodule init
git submodule update

## install digital_rf
# install prerequisites
sudo apt-get install -y automake libtool python-pkgconfig libhdf5-dev python-numpy
# build
cd digital_rf
sh autogen.sh
mkdir build
cd build
../configure
make
# install
sudo make install
cd ..
python setup.py build
sudo python setup.py install
cd ..

## install gr-drf
# install prerequisites
sudo apt-get install -y cmake swig doxygen
# build
cd gr-drf
mkdir build
cd build
cmake ../
make
# install
sudo make install
cd ../..

## install juha's python libs
cd python_libs
cd coord
python setup.py build
sudo python setup.py install
cd ../sampler_util
python setup.py build
sudo python setup.py install
cd ../stuffr
python setup.py build
sudo python setup.py install
cd ../..

## install tosr0x
# prerequisites
sudo apt-get install -y python-serial
# install
cd tosr0x
python setup.py build
sudo python setup.py install
sudo usermod -G dialout -a midasop
echo 'SUBSYSTEM=="usb", MODE="0666", GROUP="dialout"' | sudo tee /etc/udev/rules.d/50-usb.rules
cd ..

## add NetworkManager connections
sudo apt-get install -y network-manager network-manager-openvpn network-manager-ssh
sudo nmcli con add type wifi ifname "*" con-name midasmicro_wireless autoconnect yes \
                   ssid `hostname` mode ap -- \
                   +con.autoconnect-priority 1 +wifi-sec.key-mgmt wpa-psk +wifi-sec.psk mithaystack \
                   +ipv4.method shared

export MIDASMICRO_ETHDEV=`ls /sys/class/net | grep -m 1 ^enp`
sudo nmcli con add type ethernet ifname $MIDASMICRO_ETHDEV con-name midasmicro_ethernet autoconnect yes -- \
                   +con.autoconnect-priority 1 +ipv4.method manual \
                   +ipv4.addresses 192.168.10.1/16 +ipv4.never-default true

# install udhcpd for dhcp server when midasmicro_ethernet connection is active
sudo apt-get install -y udhcpd
# disable from starting at boot
sudo systemctl disable udhcpd
# enable running using init script
sudo patch /etc/default/udhcpd udhcpd/udhcpd_default_enable.patch
# replace config
sed -e "s/MIDASMICRO_ETHDEV/$MIDASMICRO_ETHDEV/g" udhcpd/udhcpd.conf | sudo tee /etc/udhcpd.conf
# set to use udhcpd when midasmicro_ethernet is active
sudo cp udhcpd/10midasmicro_dhcp_server /etc/NetworkManager/dispatcher.d/

# start new connections
sudo nmcli con up id midasmicro_wireless
sudo nmcli con up id midasmicro_ethernet

## set up mount directories for data disks and ringbuffer
sudo mkdir -p /data0
sudo mkdir -p /data1
sudo mkdir -p /ram
