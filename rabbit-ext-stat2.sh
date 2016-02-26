#!/bin/bash

# RabbitMQ External Stats
timestamp=`cat /tmp/rabbit-ext-stat-timestamp`
if [ -z $timestamp ]; then 
  timestamp=`date +%s`
  date +%s > /tmp/rabbit-ext-stat-timestamp
fi
let dif=`date +%s`-$timestamp
if [ "$dif" -gt "55" ]; then
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .name' | cat -n | awk '{ print $1 }' > /tmp/rabbit-ext-stat-ids
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .name' | sed -e 's/\"//g' > /tmp/rabbit-ext-stat-names
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .messages' > /tmp/rabbit-ext-stat-messages
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .memory' > /tmp/rabbit-ext-stat-memory
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .message_stats.deliver' > /tmp/rabbit-ext-stat-deliver
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .slave_nodes | length' > /tmp/rabbit-ext-stat-slave-nodes
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .synchronised_slave_nodes | length' > /tmp/rabbit-ext-stat-sync-slave-nodes
  curl -i -u zabbix:zabbix http://localhost:15672/api/queues | sed -n '7,${p;}' | jq '.[] | .recoverable_slaves | length' > /tmp/rabbit-ext-stat-rec-slave-nodes
  date +%s > /tmp/rabbit-ext-stat-timestamp
fi

if [ -z $1 ]; then
  echo "Usage: rabbit-ext-stat.sh id metric. Id missing."
  exit 1
fi

if [ "$1" -eq "0" ]; then
  # Generate JSON
  printf "{\n"
  printf "\t\"data\":[\n\n"
  lines=`cat /tmp/rabbit-ext-stat-names | wc -l`
  for i in `seq 1 $lines`; do
    line=`sed -n -e "$i"p /tmp/rabbit-ext-stat-names`
    printf "\t{\n"
    printf "\t\t\"{#QUEUEID}\":\"$i\",\n"
    printf "\t\t\"{#QUEUENAME}\":\"$line\"\n"
    if [ "$i" -ne "$lines" ]; then
      printf "\t},\n"
    else
      printf "\t}\n"
    fi
  done


  printf "\n\t]\n"
  printf "}\n"
  exit 0
fi

case "$2" in
  test)
    echo "Test passed. Id is $1, metric is $2"
    ;;
  name)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-names
    ;;
  messages)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-messages
    ;;
  memory)
    mem=0
    for line in `cat /tmp/rabbit-ext-stat-memory`; do
      let mem=$mem+$line
    done
    echo $mem
    ;;
  proc_memory)
    ps -aux | grep rabbitmq_server | grep -v grep | awk '{ print $6 }'
    ;;
  deliver)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-deliver
    ;;
  id)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-ids
    ;;
  alive_telnet)
    if echo q | telnet -e q localhost 15672| grep -oq Connected &> /dev/null
      then echo 1
      else echo 0
    fi;
    ;;
  slave)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-slave-nodes
    ;;
  sync-slave)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-sync-slave-nodes
    ;;
  rec-slave)
    sed -n -e "$1p" /tmp/rabbit-ext-stat-rec-slave-nodes
    ;;
  *)
    echo "Usage: rabbit-ext-stat.sh id metric. Metric missing or not valid."
    exit 2
    ;;
esac

