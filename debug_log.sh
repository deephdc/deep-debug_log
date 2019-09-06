#!/usr/bin/env bash
#
# This code is distributed under the MIT License
# Please, see the LICENSE file
#
# INFO:
# Script to run debug_sysinfo.sh and 
# upload results on the remote share
#
# VKozlov @5-Aug-2019
#
DATENOW=$(date +%y%m%d_%H%M%S)
# Script full path. The following is taken from
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself/4774063
SCRIPT_PATH="$( cd $(dirname $0) ; pwd -P )"

### user defined default params
REMOTE_DIR="rshare:/Logs/"
# Service to run
DEEPAAS_PORT=5000
DEEPAAS_LOG="${SCRIPT_PATH}/logs/${DATENOW}_${HOSTNAME}-deepaas_log.txt"
SERVICE_CMD="deepaas-run"

### settings for debug_sysinfo.sh
SYSINFO_CMD="${SCRIPT_PATH}/debug_sysinfo.sh"
SYSINFO_LOG="${SCRIPT_PATH}/logs/${DATENOW}_${HOSTNAME}-sysinfo_log.txt"

### Usage message (params can be re-defined) ###
USAGEMESSAGE="Usage: sh $0 <options> ; where <options> are: \n
	--remote_dir \t\t Remote directory to store logs, e.g. rshare:/Logs/ \n
	--deepaas_port \t DEEPaaS port (default 5000) \n"

### Parse script flags ###
arr=("$@")
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    # print usagemessage
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 1
elif [ $# -ge 1  ] && [ $# -le 2 ]; then
    for i in "${arr[@]}"; do
        [[ $i = *"--remote_dir"* ]]  && REMOTE_DIR=${i#*=}
        [[ $i = *"--deepaas_port"* ]]  && DEEPAAS_PORT=${i#*=}
    done
elif [ $# -ge 3 ]; then
    echo "[ERROR!] Too many arguments provided!"
    shopt -s xpg_echo
    echo $USAGEMESSAGE
    exit 2
fi

### Since PORT can be re-defined, set SERVICE_FLAGS here: ###
SERVICE_FLAGS="--log-file=${DEEPAAS_LOG} --openwhisk-detect --listen-ip=0.0.0.0 --listen-port=${DEEPAAS_PORT}"

##### RUN THE SCRIPT #####
### collect sysinfo
if [ -x $SYSINFO_CMD ]; then
    echo "[INFO] Collecting system information..."
    $SYSINFO_CMD > $SYSINFO_LOG
else
   echo "[INFO] $SYSINFO_CMD not found!"
   echo "[INFO] $SYSINFO_CMD not found!" >>$SYSINFO_LOG
fi

### copy sysinfo to the remote dir
RCLONE_PATH=$(which rclone)
if [ -x $RCLONE_PATH ] && [ "$RCLONE_PATH"!="" ]; then
    echo "[INFO] Now upload sysinfo log file to remote ${REMOTE_DIR}..."
    rclone copy $SYSINFO_LOG $REMOTE_DIR
else
    echo "[INFO] rclone not found!"
fi

echo "====== Starting DEEPaaS API =====" >>$SYSINFO_LOG
# After collecting sysinfo, start the service
SERVICE_CMD_PATH=$(which $SERVICE_CMD)
if [ -x $SERVICE_CMD_PATH ] && [ "$SERVICE_CMD_PATH" != "" ]; then
    SERVICE_CMD="${SERVICE_CMD} ${SERVICE_FLAGS}"
    echo "[INFO] Starting the service as:" >>$SYSINFO_LOG
    echo "${SERVICE_CMD}" >>$SYSINFO_LOG
    $SERVICE_CMD >>$SYSINFO_LOG &
    echo "[INFO] Now wait for 60s..." >>$SYSINFO_LOG
    # sleep for 60s that deepaas starts
    sleep 60s
else
   echo "[INFO] $SERVICE_CMD not found!" >>$SYSINFO_LOG
fi

echo "[INFO] Upload sysinfo log file again to remote ${REMOTE_DIR}..."
rclone copy $SYSINFO_LOG $REMOTE_DIR

# Attempt to 'continuously' upload deepaas log file
if [ -x $RCLONE_PATH ] && [ "$RCLONE_PATH" != "" ]; then
    if [ -f $DEEPAAS_LOG ]; then
        echo "[INFO] Now upload deepaas log file to remote share..."
        rclone copy $DEEPAAS_LOG $REMOTE_DIR
        # check modification time of deepaas log file
        mlast=$(stat -c %Y $DEEPAAS_LOG)
        # infinite loop
        while :
        do
            mnow=$(stat -c %Y $DEEPAAS_LOG)
            # if modification time of deepaas log file changed -> upload
            if [ "$mlast" != "$mnow" ]; then
                rclone copy $DEEPAAS_LOG $REMOTE_DIR
                mlast=$mnow
            fi
            # check the modification time every 30s
            sleep 30s
        done
    else
        echo "[INFO] $DEEPAAS_LOG not found!"
    fi
else
    echo "[INFO] rclone not found!"
fi
