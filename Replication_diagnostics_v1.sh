#!/bin/bash

################################################################################################
# Author: Upinder Sujlana
# Version: v1.0.1
# Date: April, 29, 2021
# Description: Do a arping, fping & netcat for multiple ports for HX replication troubleshooting.
#              The script shall ask for local & remote eth2 IP's from user.
# Usage: ./Replication_diagnostics.sh
###############################################################################################

pgname=`basename $0`
#-----------------------------------------------------------------------------
function debug_log() {
    msg=$*
    /usr/bin/logger -p "user.info" --id --tag $pgname $msg
}

function error_log() {
    msg=$*
    /usr/bin/logger -p "user.err" --id --tag $pgname $msg
}
#-----------------------------------------------------------------------------
LOCAL_ETH0=$(ifconfig eth0 | grep -i inet |  awk '{ print $2}' | sed 's/addr://')
LOCAL_ETH2=$(ifconfig eth2 | grep -i inet |  awk '{ print $2}' | sed 's/addr://')

echo "Running the script on SCVM with eth0 : $LOCAL_ETH0";echo
if [[ $LOCAL_ETH2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Local SCVM has a valid eth2 IP $LOCAL_ETH2 . Moving on.";echo
  echo "//----------------------------------------------------------------------"; echo
else
  echo "Local SCVM does not have a valid eth2 IP. Existing the script"
  error_log "Local SCVM does not have a valid eth2 IP. Existing the script"; exit 1
fi
#-----------------------------------------------------------------------------
read -p "Enter all LOCAL   cluster ETH2 IP whitespace seperated  : " local_eth2_ips
read -p "Enter all REMOTE  cluster ETH2 IP whitespace seperated :  " remote_eth2_ips

# Just in case user inputs the local eth2 IP let me remove it.
local_eth2_ips=( "${local_eth2_ips[@]/$LOCAL_ETH2}" )
remote_eth2_ips=( "${remote_eth2_ips[@]/$LOCAL_ETH2}" )

echo "//----------------------------------------------------------------------";echo
#-----------------------------------------------------------------------------
echo "Doing a arping across the eth2 local IP's";echo
for i in ${local_eth2_ips[@]}
do
   echo "$(arping -c 5 -D -I eth2 $i | grep reply)"
done
echo "//----------------------------------------------------------------------";echo
#-----------------------------------------------------------------------------
echo "Testing 1472 MTU ping to local cluster eth2 IP's"; echo
for i in ${local_eth2_ips[@]}
do
   echo "$(fping -I eth2 -M -c 1 -q -b 1472 $i)"
   echo
done
echo "//----------------------------------------------------------------------";echo
echo "Testing 1472 MTU ping to remote cluster eth2 IP's"; echo
for i in ${remote_eth2_ips[@]}
do
   echo "$(fping -I eth2 -M -c 1 -q -b 1472 $i)"
   echo
done
echo "//----------------------------------------------------------------------";echo
#-----------------------------------------------------------------------------
PORT_ARRAY=(9338 3049 4049 4059 9098 8889 9350)
echo "Doing a netcat (timeout 5 seconds) to remote cluster eth2 IP's on ports ${PORT_ARRAY[@]}";echo
echo -e "NOTE :- in below output if you see 'timed out: Operation now in progress' substring, it means \nremote node's firewall dropped the connection request"
echo
for ip in ${remote_eth2_ips[@]}
do
  for port in ${PORT_ARRAY[@]}
    do
      echo "$(nc -v -z -w 5 $ip $port )"
      echo
    done
done
echo "//----------------------------------------------------------------------";echo
#-----------------------------------------------------------------------------
