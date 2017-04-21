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
sudo apt-get install -y cmake libtool libhdf5-dev python-numpy python-dev swig doxygen python-watchdog python-tz python-dateutil
# build
cd digital_rf
mkdir build
cd build
cmake ..
make
make test
# install
sudo make install
sudo ldconfig
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

export INTERNAL_ETHDEV=`ls /sys/class/net | grep -m 1 ^enp`
sudo nmcli con add type ethernet ifname $INTERNAL_ETHDEV con-name internal_ethernet autoconnect yes -- \
                   +con.autoconnect-priority 1 +ipv4.method manual \
                   +ipv4.addresses 192.168.10.1/16 +ipv4.never-default true

export MIDASMICRO_ETHDEV=`ls /sys/class/net | grep -m 1 ^enx`
sudo nmcli con add type ethernet ifname $MIDASMICRO_ETHDEV con-name dhcp_ethernet autoconnect yes -- \
                   +con.autoconnect-priority 2 +ipv4.method auto \
                   +ipv4.dhcp-timeout 15 +ipv6.method ignore

sudo nmcli con add type ethernet ifname $MIDASMICRO_ETHDEV con-name midasmicro_ethernet autoconnect yes -- \
                   +con.autoconnect-priority 1 +ipv4.method manual \
                   +ipv4.addresses 10.0.0.1/24 +ipv4.never-default true

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

## gpsd and ntpd
sudo apt-get install -y ntp gpsd gpsd-clients
sudo dpkg-reconfigure -plow gpsd

# configure gpsd
cat >>gpsd <<'EOL'
# Default settings for the gpsd init script and the hotplug wrapper.

# Start the gpsd daemon automatically at boot time
START_DAEMON="true"

# Use USB hotplugging to add new USB devices automatically to the daemon
USBAUTO="true"

# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES=""

# Other options you want to pass to gpsd
GPSD_OPTIONS="-n -F /var/run/gpsd.sock /dev/ttyUSB1"
EOL
sudo mv gpsd /etc/default/gpsd

# configure ntpd
sudo tee --append /etc/ntp.conf <<'EOL'

server 127.127.28.0 minpoll 4 maxpoll 4
fudge 127.127.28.0 time1 0.0 refid GPS

server 127.127.28.1 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.1 refid PPS
EOL

## set up mount directories for data disks and ringbuffer
sudo mkdir -p /data
sudo mkdir -p /data/ssd0
sudo mkdir -p /data/ssd1
sudo mkdir -p /data/ram

## group setup
sudo addgroup daq
sudo adduser midasop daq
sudo chown -R root:daq /data
sudo chmod -R g+rw /data
