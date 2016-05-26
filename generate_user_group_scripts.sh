#!/bin/bash

### Execution: ./generate_user_group_scripts.sh

### This scripts creates user and group creation commands for a ### new IOP 4.1 and EMC Isilon OneFS 8.0 installation.


#   Change the four variables below to fit your environment:

### Starting GID for group creation
GidBase=1000
### Starting UDI for user creation
UidBase=1000
### Name of Access Zone used by EMC Isilon
Zone=ibm41
### Root dir of EMC Isilon
HDFSRoot=/ifs/ibm41/hadoop

### END of variables to be changed


## Users as described in IBM Knowledge Center as required for IOP 4.1 installation:
#
#  http://www.ibm.com/support/knowledgecenter/SSPT3X_4.1.0/com.ibm.swg.im.infosphere.biginsights.install.doc/doc/inst_iop_users.html
#  value add:  http://www.ibm.com/support/knowledgecenter/SSPT3X_4.1.0/com.ibm.swg.im.infosphere.biginsights.install.doc/doc/val-add_ports.html?lang=en 


cat << EOF > user_group_table.txt
# User;Group;Service
apache;apache;
ams;hadoop;Ambari metric service
#postgres;postgres;
hive;hadoop;Hive
oozie;hadoop;Oozie
ambari-qa;hadoop;
flume;hadoop;
hdfs;hadoop;HDFS
solr;hadoop;
knox;hadoop;Knox
spark;hadoop;Spark
mapred;hadoop;MapReduce
hbase;hadoop;HBase
zookeeper;hadoop;ZooKeeper
sqoop;hadoop;Sqoop
yarn;hadoop;YARN
hcat;hadoop;HCat,WebHCat
rrdcached;rrdcached;
#mysql;mysql;
hadoop;hadoop;Hadoop
kafka;hadoop;Kafka
# value-add users, manually added
bigsheets;hadoop;Bigsheets
tauser;hadoop;Text Analytics
bigsql;hadoop;Big SQL
uiuser;hadoop;BigInsights Home
bigr;hadoop;Big R
dsmadmin;dsmadmin;Data Server Manager
EOF


## create groups
#
egrep -v "^#" user_group_table.txt | awk -F ";" '{print $2}' | sort | uniq > groups.txt

i=$GidBase
echo "#!/bin/bash" > groupadd.sh 
echo "#!/usr/local/bin/zsh" > isi_auth_groups.sh

for Group in `cat groups.txt`
do
  ### create group
  #  for IOP
  echo "groupadd -g $i $Group" >> groupadd.sh
  #  for Isilon
  echo "isi auth groups create $Group --gid $i --zone $Zone" >> isi_auth_groups.sh
  i=$(($i+1)) 
done

### special case: hdfs group
echo "groupadd -g $i hdfs" >> groupadd.sh
echo "isi auth groups create hdfs --gid $i --zone $Zone" >> isi_auth_groups.sh

chmod 750 groupadd.sh isi_auth_groups.sh
#echo "Create groups .."
#./groupadd.sh > groupadd.log 2>&1

echo -e "\n### File groupadd.sh has to be executed for each IOP cluster node"
cat groupadd.sh
echo -e "\n### File isi_auth_groups.sh has to be executed in a shell at any EMC Isilon node"
cat isi_auth_groups.sh


### create userids
# 
echo "#!/bin/bash" > useradd.sh 
echo "#!/usr/local/bin/zsh" > isi_auth_users.sh

## for IOP
egrep -v "^#" user_group_table.txt | awk -F ";" -v Uid=$UidBase '{printf("useradd -g %s -u %s %s -c \"%s\"\n", $2, Uid, $1, $3);Uid++}'  > useradd.sh
## for Isilon
egrep -v "^#" user_group_table.txt | awk -F ";" -v HDFSRoot=$HDFSRoot -v Zone=$Zone -v Uid=$UidBase '{printf("isi auth users create %s --uid %s --primary-group %s --zone %s --provider local --home-directory %s/%s \n", $1, Uid, $2, Zone,HDFSRoot,$1);Uid++}'  > isi_auth_users.sh

###special case: user hdfs needs to be member in hdfs group
echo "groupmems -a hdfs -g hdfs" >> useradd.sh
echo "isi auth groups modify hdfs --zone=$Zone --add-user=hdfs" >> isi_auth_users.sh

chmod 750 useradd.sh isi_auth_users.sh
#echo "Create users ..."
#./useradd.sh > useradd.log 2>&1

echo -e "\n### File useradd.sh has to be executed for each IOP cluster node"
cat useradd.sh
echo -e "\n### File isi_auth_users.sh has to be executed in a shell at any EMC Isilon node"
cat isi_auth_users.sh

echo -e "\n### Execute group scripts before users scripts."
echo "Done."
