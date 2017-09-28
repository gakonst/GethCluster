#!/bin/bash
# Usage:
# bash /path/to/eth-utils/gethup.sh <datadir> <instance_name>

root=$1  # base directory to use for datadir and logs
echo "Root is" $root
shift
dd=$1  # double digit instance id like 00 01 02
echo "dd is" $dd
shift
genesis=$1  # double digit instance id like 00 01 02
echo "genesis is" $genesis
shift
password=$1  # double digit instance id like 00 01 02
shift
echo "password file  is" $password
echo "password:" $(cat $password)


# logs are output to a date-tagged file for each run , while a link is
# created to the latest, so that monitoring be easier with the same filename
# TODO: use this if GETH not set
GETH=`which geth`
echo "geth at" $GETH

# geth CLI params       e.g., (dd=04, run=09)
datetag=`date "+%c%y%m%d-%H%M%S"|cut -d ' ' -f 5`
datadir=$root/data/$dd        # /tmp/eth/04
log=$root/log/$dd.$datetag.log     # /tmp/eth/04.09.log
linklog=$root/log/$dd.current.log     # /tmp/eth/04.09.log
stablelog=$root/log/$dd.log     # /tmp/eth/04.09.log
port=303$dd              # 30304
rpcport=85$dd            # 8104

echo "Launching node: " $port $rpcport

# Check if geth folder exists, otherwise initialize genesis block
if [ ! -d "$datadir/geth" ]; then
	echo "Initializing genesis block"
	geth --datadir $datadir init $genesis
fi

mkdir -p $root/data
mkdir -p $root/log
ln -sf "$log" "$linklog"
# if we do not have an account, create one
# will not prompt for password, we use the double digit instance id as passwd
# NEVER EVER USE THESE ACCOUNTS FOR INTERACTING WITH A LIVE CHAIN
if [ ! -d "$root/keystore/$dd" ]; then
  echo create an account with password $dd [DO NOT EVER USE THIS ON LIVE]
  mkdir -p $root/keystore/$dd
  echo -n $dd > $root/password.sec
  $GETH --datadir $datadir --password $root/password.sec  account new
  echo "Account created" 
# create account with password 00, 01, ...
  # note that the account key will be stored also separately outside
  # datadir
  # this way you can safely clear the data directory and still keep your key
  # under `<rootdir>/keystore/dd

  cp -R "$datadir/keystore" $root/keystore/$dd
fi

# bring up node `dd` (double digit)
# - using <rootdir>/<dd>
# - listening on port 303dd, (like 30300, 30301, ...)
# - with the account unlocked
# - launching json-rpc server on port 81dd (like 8100, 8101, 8102, ...)


echo "Extra Arguments" $*
 $GETH \
   --fast \
   --identity "$dd" \
 	--networkid 42 \
   --datadir $datadir \
   --nodiscover \
   --rpcapi net,eth,web3,miner,personal \
   --rpc \
   --rpccorsdomain='*' \
   --rpcport $rpcport \
   --port $port \
   --unlock 0 \
   --password $root/password.sec $* \
 	#2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.
# 
# to bring up logs, uncomment
# tail -f $log
