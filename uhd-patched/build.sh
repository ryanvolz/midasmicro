#!/bin/sh

# install development tools
sudo apt-get install -y packaging-dev devscripts equivs

# fetch the source package
apt-get source uhd

# install build dependencies by creating and installing a package named
# 'uhd-build-deps' that depends on the build dependencies
cd uhd-*
sudo mk-build-deps --install --remove

# add the patch to the package
cp ../usrp2-include-DSP-bit-gain debian/patches
echo usrp2-include-DSP-bit-gain >> debian/patches/series

# update the changelog
dch -n "Include patch for variable DSP bit gain."
dch --local ~`lsb_release -cs` "Local build."

# build the package
dpkg-buildpackage -us -uc
