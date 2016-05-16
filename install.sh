#!/bin/sh

# install gnuradio
sudo apt-get install -y gnuradio-dev

# install patched uhd
sudo dpkg -i uhd-patched/*`lsb_release -cs`*.deb
sudo apt-get install -fy

# make sure submodules are up to date
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
sudo python setup.py install
cd ../sampler_util
sudo python setup.py install
cd ../stuffr
sudo python setup.py install
cd ../..
