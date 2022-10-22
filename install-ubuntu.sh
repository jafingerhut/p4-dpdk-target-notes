#! /bin/bash

# Set up some environment variables that we need them later
# Assume you want to install everything under your home directory
export SDE=$HOME/sde
export SDE_INSTALL=$SDE/install
export LD_LIBRARY_PATH=$SDE_INSTALL/lib:$SDE_INSTALL/lib64:$SDE_INSTALL/lib/x86_64-linux-gnu/:/usr/local/lib64:/usr/local/lib

# Some dependencies to build the SDE/p4-dpdk-target
sudo apt update && \
sudo apt install -y git automake cmake python3 python3-pip
pip3 install distro # Required by `p4-dpdk-target/tools/setup/sysutils.py` to detect the OS

# Download everything we need
mkdir -p $SDE_INSTALL
cd $SDE
git clone --depth=1 https://github.com/p4lang/target-utils --recursive utils
git clone --depth=1 https://github.com/p4lang/target-syslibs --recursive syslibs
git clone --depth=1 https://github.com/p4lang/p4-dpdk-target --recursive p4-dpdk-target

# NOTE: The version of meson installed with this script on Ubuntu
# 20.04 is 0.53.2, and that version does not implement the 'compile'
# subcommand, according to the output of 'meson --help'.

# The version of meson installed with a similar script on Fedora 34 is
# 0.62.1, and that version _does_ implement the 'compile' subcommand.
# Parts of the build commands below rely upon commands like 'meson
# compile -j4' working.  They fail on Ubuntu 20.04 with meson 0.53.2.

# Ubuntu 20.04 'sudo apt-get install meson' -> meson 0.53.2 ninja 1.10.0 'meson compile'? no
# Ubuntu 22.04 'sudo apt-get install meson' -> meson 0.61.2 ninja 1.10.1 'meson compile'? yes
# Fedora 34 'yum install meson' -> meson 0.62.1 ninja 1.10.2 'meson compile'? yes

# Some other dependencies, here are packages installed (with apt-get command):
# git unifdef curl python3-setuptools python3-pip python3-wheel python3-cffi
# libconfig-dev libunwind-dev libffi-dev zlib1g-dev libedit-dev libexpat1-dev clang
# ninja-build gcc libstdc++6 autotools-dev autoconf autoconf-archive libtool meson
# google-perftools connect-proxy tshark
# ... and installed with pip3:
# thrift protobuf pyelftools scapy six

sudo -E python3 p4-dpdk-target/tools/setup/install_dep.py
# jafingerhut: Got up to here in my VM "Ubuntu 20.04 try p4-dpdk-target-notes"
cd $SDE/utils && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL -DCPYTHON=1 -DSTANDALONE=ON .. && \
    make -j && \
    make install
cd $SDE/syslibs && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL .. && \
    make -j && \
    make install
cd $SDE/p4-dpdk-target && \
    git submodule update --init --recursive --force && \
    ./autogen.sh && \
    ./configure --prefix=$SDE_INSTALL && \
# jafingerhut: Got up to here in my VM "Ubuntu 20.04 try2 p4-dpdk-target-notes"
    make -j && \
    make install

# refresh path so we will use python3 from SDE instead the default one
ln -s $SDE_INSTALL/bin/python3.8 $SDE_INSTALL/bin/python3
