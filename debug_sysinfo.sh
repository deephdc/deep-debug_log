#!/usr/bin/env bash
#
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# INFO:
# Script to read host information
#
# VKozlov @18-May-2018
#

echo "[INFO]##### Hostname: $HOSTNAME #####"
echo "* Internal IP: $(hostname -I)"
# external IP via checkip.amazonaws.com
EXT_IP=$(curl -s http://checkip.amazonaws.com)
echo "* External IP (check 1): ${EXT_IP}"
# external IP via ipecho.net/plain
EXT_IP=$(curl -s ipecho.net/plain)
echo "* External IP (check 2): ${EXT_IP}"
echo ""

echo "[INFO]##### Linux release: #####"
cat /etc/os-release
echo ""
echo "[INFO]##### top output: #####"
top -bn3 | head -n 5
echo ""

### info about network interfaces ###
echo "[INFO]##### Network Interfaces via ifconfig #####"
ifconfig
echo ""

### Python version ###
echo "[INFO]##### Python version #####"
echo "* Response for the default 'python':"
python --version
echo "* Check if 'python2' is present:"
python2 --version
echo ""

### info on nvidia cards ###
echo "[INFO]##### NVIDIA card (if installed) #####"
#if [ -f $(command -v nvidia-smi) ]; then
#    nvidia-smi
#else

if command nvidia-smi 2>/dev/null; then
    echo "NVIDIA is present"
else
    echo "!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!"
    echo "no nvidia-smi found on this machine"
    echo "Are you sure that it has GPU(s) and CUDA?"
    echo "!!!!!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!"
fi

echo ""
### print all environment settings: ###
echo "[INFO]##### Environment settings: #####"
echo "###### Skip variable names with 'pAsS':"
ENV_U_LIST=""
ENV_PASS=($(env | grep -i pass.*= | cut -d '=' -f1))
for pass in ${ENV_PASS[*]}
do
   ENV_U_LIST="${ENV_U_LIST} -u ${pass}"
   echo $pass
done
echo "#######################################"
# Show envrionment settings without those containing PASSWORD
env $ENV_U_LIST

