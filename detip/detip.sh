#!/bin/bash
########################################################################
# Functions
########################################################################
function check_ipv4 () {
    if [ `echo $1 | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'  | grep -o "\." | wc -l` -eq 3 ];
    then 
      ipv4=true;
    else 
      ipv4=false;
    fi
}


########################################################################
# Bash start here
########################################################################
  this_script=`echo $0 | sed "s/^.*\///"`
  script_path=`echo $0 | sed "s/\/${this_script}$//"`

case "$2" in
  daemon)
     out_fd=" >/dev/null"         # run as daemon mode, all message output to /dev/null
     ;;
  debug)                    
     out_fd=" >>/root/defender/dbg.log"  # run as debug mode, log all message in file "dbg.log"
     ;;
  *)
     out_fd=" >&1"                # run as normal mode, all message output to std-out
     ;;
esac

case "$1" in
  start)
   eval echo "------------------" ${out_fd}
   eval echo "\| Starting Detip \|" ${out_fd}
   eval echo "------------------" ${out_fd}
   ;;
  stop)
   eval echo "------------------" ${out_fd}
   eval echo "\| Stopping Detip \|" ${out_fd}
   eval echo "------------------" ${out_fd}
   ;;
  *)
   eval echo "Usage: $this_script {start\|stop} [daemon]" >&2
   exit 1
   ;;
esac

########################################################################
#  載入並且檢查設定檔 
########################################################################

  if [ -f $script_path/detip.conf ]; then
    . $script_path/detip.conf
  else
    eval echo "Can\'t find $script_path/detip.conf file!!" >&2
    exit 1
  fi

  check_ipv4 $PING_IP
  if [ "$ipv4" != "true" ]; then
    eval echo "The \"PING_IP\" settings is wrong in detip.conf" >&2
    exit 1
  fi

  if [ ! -f ${script_path}/$ACTION_SCRIPT_NAME ]; then
    eval echo "Can\'t find the action script file: ${ACTION_SCRIPT_NAME}" >&2
    exit 1
  fi

  if [ ! -x ${script_path}/$ACTION_SCRIPT_NAME ]; then
    eval echo "The action script is not execuable file" >&2
    exit 1
  fi

########################################################################
#  環境變數及目錄設定 
########################################################################
  PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin; 
  export PATH


########################################################################
# Main Loop
########################################################################
 err_cnt=0

 while true
 do
   sleep 60     # 每分鐘偵測一次IP
   ip_result=`ping -c 1 $PING_IP  > /dev/null 2>&1 && echo "ok" || echo "err"` 

   if [ "$ip_result" != "ok" ]; then
     err_cnt=`echo "$err_cnt+1" | bc`
   else
     err_cnt=0
   fi

   #---------------------------------------
   # 連續錯誤3次, 則執行$ACTION_SCRIPT_NAME
   #---------------------------------------
   if [ "$err_cnt" == "3" ]; then
     eval ${script_path}/${ACTION_SCRIPT_NAME} ${out_fd}
     err_cnt=0
   fi
 done 


########################################################################
# End
########################################################################
  eval echo "--------" ${out_fd}
  eval echo "\| Done \|" ${out_fd}
  eval echo "--------" ${out_fd}

