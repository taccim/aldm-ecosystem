#!/bin/bash
# $Id: deploy-config.sh,v 0.9 2020/12/12 20:13:35 mtacci Exp $ 
#Purpose: Used to creat a config.sh script required by MySQL 10.1 to set some config parmaters
#         it is called during the startup of the MariaDB


#volume /docker-entrypoint-initdb.d/ #problems using this mount in 10.1 TODO: revisit with 10.4
# URL: https://mariadb.com/resources/blog/10-database-tuning-tips-for-peak-workloads/

[ -d /dce/initdb.d ] || mkdir -p /dce/initdb.d 
ilfig=2
ibps=$(awk '/MemTotal/ {print $2 * 716}' /proc/meminfo) #Bytes  70% of Mem_kB
ilfs=$(awk '/MemTotal/ {i=$2 * 716 * .25 ;i=int(i/n);if(i*n>536870912000)i=536870912000/n;printf("%d",i)}' n=$ilfig  /proc/meminfo) #25% ibps <= 512G (500)
ilbs=$(awk '/MemTotal/ {print $2 * 72}' /proc/meminfo) #Bytes  10% ibps
tts=$(awk '/MemTotal/ {n=$2 * 716;i=3221225472;if(n<i) i=n*3/5;printf("%d",i)}' /proc/meminfo) #<=3G
mhts=$tts

cat - << ESQL > /dce/initdb.d/config.sh
#!/bin/sh
if [ ! -f /etc/mysql/conf.d/mariadb4aldm.cnf  ];then
    cat - << ESQLC > /etc/mysql/conf.d/mariadb4aldm.cnf
$(awk '/MemTotal/ {printf("#%s %.1fG", $1,$2*1024/1000^3)}' /proc/meminfo)
[mysqld]
max_connections = 1001
innodb_buffer_pool_size = $ibps
innodb_log_file_size = $ilfs
innodb_log_files_in_group = $ilfig
innodb_file_per_table	= 1
innodb_open_files	= 400
innodb_io_capacity	= 400
log_error = mariadb.err
ESQLC
    cat - << ESQLP >> /etc/mysql/conf.d/mariadb4aldm.cnf
innodb_log_buffer_size = $ilbs
max_allowed_packet = 500M
sort_buffer_size = 50M
bulk_insert_buffer_size = 1G
tmp_table_size = $tts
max_heap_table_size = $mhts
skip-name-resolve
query_cache_limit = 1M
query_cache_size = 0 
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/mariadb-slow.log
ESQLP
fi
ESQL
chmod 755  /dce/initdb.d/config.sh
cp /dce/initdb.d/config.sh /dce/tmp  #XXX work around for 10.1 issue

#config.sh is run at startup by aldm-start.sh script
#mt ibm-2020
