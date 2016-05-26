#!/bin/bash

### Change history
#   BB 20160422:  - added DIST bi4.1 with adapted list items
#                 - migrated hdfsroot detection function for OneFS 8.0

###########################################################################
##  Script to create Hadoop directory structure on Isilon.
##  Must be run on Isilon system.
########################################################################### 

if [ -z "$BASH_VERSION" ] ; then
   # probably using zsh...
   echo "Script not run from bash -- reinvoking under bash"
   bash "$0"
   exit $?
fi

declare -a ERRORLIST=()

DIST=""
FIXPERM="n"
ZONE="System"

#set -x

function banner() {
   echo "##################################################################################"
   echo "## $*"
   echo "##################################################################################"
}

function usage() {
   echo "$0 --dist <bi4.0> [--zone <ZONE>] [--fixperm]"
   exit 1
}

function fatal() {
   echo "FATAL:  $*"
   exit 1
}

function warn() {
   echo "ERROR:  $*"
   ERRORLIST[${#ERRORLIST[@]}]="$*"
}

function yesno() {
   [ -n "$1" ] && myPrompt=">>> $1 (y/n)? "
   [ -n "$1" ] || myPrompt=">>> Please enter yes/no: "
   read -rp "$myPrompt" yn
   [ "z${yn:0:1}" = "zy" -o "z${yn:0:1}" = "zY" ] && return 0
#   exit "DEBUG:  returning false from function yesno"
   return 1
}

function makedir() {
   if [ "z$1" == "z" ] ; then
      echo "ERROR -- function makedir needs directory as an argument"
   else
      mkdir $1
   fi
}
   
function fixperm() {
   if [ "z$1" == "z" ] ; then
      echo "ERROR -- function fixperm needs directory owner group perm as an argument"
   else
      isi_run -z $ZONEID chown $2 $1
      isi_run -z $ZONEID chown :$3 $1
      isi_run -z $ZONEID chmod $4 $1
   fi
}

function getHdfsRoot() {
    local hdfsroot
    #hdfsroot=$(isi zone zones view $1 | grep "HDFS Root Directory:" | cut -f2 -d :)
    # Syntax Change needed for OneFS v 8
    hdfsroot=$(isi hdfs settings view --zone $1 | grep "Root Directory:" | cut -f2 -d :)

    echo $hdfsroot
}
 
function getAccessZoneId() {
    ## Get local access zone id
    zoneid=$(isi zone zones view $1 | grep "Zone ID:" | cut -f2 -d :)
    echo $zoneid
}
   
if [ "`uname`" != "Isilon OneFS" ]; then
   fatal "Script must be run on Isilon cluster as root."
fi

if [ "$USER" != "root" ] ; then
   fatal "Script must be run as root user."
fi

# Parse Command-Line Args       
# Allow user to specify what functions to check 
while [ "z$1" != "z" ] ; do
    # echo "DEBUG:  Arg loop processing arg $1"
    case "$1" in
      "--dist")
             shift
             DIST="$1"
             echo "Info: Hadoop distribution:  $DIST"
             ;;
      "--zone")
             shift
             ZONE="$1"
             echo "Info: will use users in zone:  $ZONE"
             ;;
      "--fixperm")
             echo "Info: will fix permissions and owners on existing directories"
             FIXPERM="y"
             ;;
      *)     echo "ERROR -- unknown arg $1"
             usage
             ;;
    esac
    shift;
done

declare -a dirList

case "$DIST" in
    "bi4.0")
        # Format is: dirname#perm#owner#group
        dirList=(\
            "/#755#hdfs#hadoop" \
            "/tmp#1777#hdfs#hadoop" \
            "/user#755#hdfs#hadoop" \
            "/iop#755#hdfs#hadoop" \
            "/apps#755#hdfs#hadoop" \
            "/app-logs#755#hdfs#hadoop" \
            "/mapred#755#hdfs#hadoop" \
            "/mr-history#755#hdfs#hadoop" \
            "/user/ambari-qa#770#ambari-qa#hadoop" \
            "/user/hcat#775#hcat#hadoop" \
            "/user/hive#775#hive#hadoop" \
            "/user/oozie#775#oozie#hadoop" \
            "/user/yarn#775#yarn#hadoop" \
            "/user/zookeeper#775#zookeeper#hadoop" \
            "/user/uiuser#775#uiuser#hadoop" \
            "/user/spark#775#spark#hadoop" \
            "/user/sqoop#775#sqoop#hadoop" \
            "/user/solr#775#solr#hadoop" \
            "/user/nagios#775#nagios#hadoop" \
            "/user/bigsheets#775#bigsheets#hadoop" \
            "/user/bigsql#775#bigsql#hadoop" \
            "/user/dsmadmin#775#dsmadmin#hadoop" \
            "/user/flume#775#flume#hadoop" \
            "/user/hbase#775#hbase#hadoop" \
            "/user/knox#775#knox#hadoop" \
            "/user/mapred#775#mapred#hadoop" \
            "/user/bigr#775#bigr#hadoop" \
            "/user/bighome#775#bighome#hadoop" \
            "/user/tauser#775#tauser#hadoop" \
        )
	;;
    "bi4.1")
        # Format is: dirname#perm#owner#group
        # Chnage compared to bi4.0:
        #  - removed: nagios, bighome
        #  - added: ams, kafka, rrdcached, hdfs
        dirList=(\
            "/#755#hdfs#hadoop" \
            "/tmp#1777#hdfs#hadoop" \
            "/user#755#hdfs#hadoop" \
            "/iop#755#hdfs#hadoop" \
            "/apps#755#hdfs#hadoop" \
            "/app-logs#755#hdfs#hadoop" \
            "/mapred#755#hdfs#hadoop" \
            "/mr-history#755#hdfs#hadoop" \
            "/user/ambari-qa#770#ambari-qa#hadoop" \
            "/user/hcat#775#hcat#hadoop" \
            "/user/hive#775#hive#hadoop" \
            "/user/oozie#775#oozie#hadoop" \
            "/user/yarn#775#yarn#hadoop" \
            "/user/zookeeper#775#zookeeper#hadoop" \
            "/user/uiuser#775#uiuser#hadoop" \
            "/user/spark#775#spark#hadoop" \
            "/user/sqoop#775#sqoop#hadoop" \
            "/user/solr#775#solr#hadoop" \
            "/user/bigsheets#775#bigsheets#hadoop" \
            "/user/bigsql#775#bigsql#hadoop" \
            "/user/dsmadmin#775#dsmadmin#hadoop" \
            "/user/flume#775#flume#hadoop" \
            "/user/hbase#775#hbase#hadoop" \
            "/user/knox#775#knox#hadoop" \
            "/user/mapred#775#mapred#hadoop" \
            "/user/bigr#775#bigr#hadoop" \
            "/user/tauser#775#tauser#hadoop" \
            "/user/kafka#775#kafka#hadoop" \
            "/user/ams#775#ams#hadoop" \
            "/user/hdfs#775#hdfs#hadoop" \
            "/user/rrdcached#775#rrdcached#rrdcached" \
        )
	;;
    *)
        echo "ERROR -- Invalid Hadoop distribution"
        usage
        ;;
esac

ZONEID=$(getAccessZoneId $ZONE)
echo "Info: Access Zone ID is $ZONEID"

HDFSROOT=$(getHdfsRoot $ZONE)
echo "Info: HDFS root dir is $HDFSROOT"

if [ ! -d $HDFSROOT ] ; then
   fatal "HDFS root $HDFSROOT does not exist!"
fi

# MAIN

banner "Creates Hadoop directory structure on Isilon system HDFS."

prefix=0
# Cycle through directory entries comparing owner, group, perm
# Sample output from "ls -dl"  command below
# drwxrwxrwx    8 hdfs  hadoop  1024 Aug 26 03:01 /tmp

for direntry in ${dirList[*]}; do
   read -a specs <<<"$(echo $direntry | sed 's/#/ /g')"
   echo "DEBUG: specs dirname ${specs[0]}; perm ${specs[1]}; owner ${specs[2]}; group ${specs[3]}"
   ifspath=$HDFSROOT${specs[0]}
   # echo "DEBUG:  ifspath = $ifspath"

   #  Get info about directory
   if [ ! -d $ifspath ] ; then
      # echo "DEBUG:  making directory $ifspath"
      makedir $ifspath
      fixperm $ifspath ${specs[2]} ${specs[3]} ${specs[1]}
   elif [ "$FIXPERM" == "y" ] ; then
      # echo "DEBUG:  fixing directory perm $ifspath"
      fixperm $ifspath ${specs[2]} ${specs[3]} ${specs[1]}
   else
      warn "Directory $ifspath exists but no --fixperm not specified"
   fi

done

if [ "${#ERRORLIST[@]}" != "0" ] ; then
   echo "NOTE:"
   i=0
   while [ $i -lt ${#ERRORLIST[@]} ]; do
      echo "INFO:  ${ERRORLIST[$i]}"
      i=$(($i + 1))
   done
   fatal "Issue found in Hadoop admin directory structure -- please review before continuing"
   exit 1
else 
   echo "SUCCESS -- Hadoop admin directory structure exists and has correct ownership and permissions"
fi

echo "Done!"
