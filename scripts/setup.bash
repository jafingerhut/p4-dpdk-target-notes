# Basic environment variables we need
export SDE=$HOME/sde
export SDE_INSTALL=$SDE/install
export LD_LIBRARY_PATH=$SDE_INSTALL/lib:$SDE_INSTALL/lib64:$SDE_INSTALL/lib/x86_64-linux-gnu/:/usr/local/lib64:/usr/local/lib
# We need to put SDE executable path before the system one since the bfrt_python
# needs to use Python libraries from it and use the Python executable from SDE
export PATH=$SDE_INSTALL/bin:$PATH
