#! /bin/bash

# TODO: Add checks for supported OS version(s), and sufficient free
# RAM and disk space.

# This script downloads about 1 GB of data from the Internet.
# It ran fine in a system with GB of RAM and 4 CPU cores, as long as
# 'make -j2' was used for the last make command instead of the
# original 'make -j', which caused too many jobs to be run in parallel
# and consumed too much RAM for a 4 GB RAM system.

# It increased disk space by about 4.5 GB during its execution.

set -x

# Set up some environment variables that we need them later
# Assume you want to install everything under your home directory
export SDE=$HOME/sde
export SDE_INSTALL=$SDE/install
export LD_LIBRARY_PATH=$SDE_INSTALL/lib:$SDE_INSTALL/lib64:$SDE_INSTALL/lib/x86_64-linux-gnu/:/usr/local/lib64:/usr/local/lib

# Some dependencies to build the SDE/p4-dpdk-target
sudo apt update
sudo apt install -y git automake cmake python3 python3-pip
# Required by `p4-dpdk-target/tools/setup/sysutils.py` to detect the OS
pip3 install distro

# Download everything we need
mkdir -p $SDE_INSTALL
cd $SDE
git clone --depth=1 https://github.com/p4lang/target-utils --recursive utils
git clone --depth=1 https://github.com/p4lang/target-syslibs --recursive syslibs
git clone --depth=1 https://github.com/p4lang/p4-dpdk-target --recursive p4-dpdk-target

# Some other dependencies, here are packages installed (with apt-get command):
# git unifdef curl python3-setuptools python3-pip python3-wheel python3-cffi
# libconfig-dev libunwind-dev libffi-dev zlib1g-dev libedit-dev libexpat1-dev clang
# ninja-build gcc libstdc++6 autotools-dev autoconf autoconf-archive libtool meson
# google-perftools connect-proxy tshark
# ... and installed with pip3:
# thrift protobuf pyelftools scapy six

sudo -E python3 p4-dpdk-target/tools/setup/install_dep.py

cd $SDE/utils
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL -DCPYTHON=1 -DSTANDALONE=ON ..
make -j
make install

cd $SDE/syslibs
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL ..
make -j
make install

cd $SDE/p4-dpdk-target
git submodule update --init --recursive --force
./autogen.sh
./configure --prefix=$SDE_INSTALL
make -j2
make install

# refresh path so we will use python3 from SDE instead the default one
ln -s $SDE_INSTALL/bin/python3.8 $SDE_INSTALL/bin/python3
