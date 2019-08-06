Debugging scripts
=================

debug_sysinfo.sh
-----------------
Script to collect information about the running system: 
   * Hostname
   * Linux release
   * Current memory load
   * Network interfaces
   * Python version
   * Nvidia card info (if present)
   * Environment settings (skipping those with 'pAssWoRd')

debug_log.sh 
------------
Calls debug_sysinfo.sh + starts deepaas-run and uploads its logfile to the remote storage. It has two parameters:
   * --deepaas_port - port used by DEEPaaS API (default is 5000)
   * --remote_dir - remote directory to be used by rclone (rclone.org) to upload log files.
       Must be given as e.g. "rshare:/Logs/", i.e. name of the remote share ("rshare"), and the remote directory ("/Logs/") with the slash "/" at the end.


