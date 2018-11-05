#!/bin/bash
#Program:
#version:v2
# This program is to delete the files older than 183 days in inspectors' share folders
#10 Nov 2017 created by Jimmy Chu
# edited in 20Jul2018 by Jimmy chu
# Shell script to monitor or watch the disk space
# -------------------------------------------------------------------------
# set alert level
safelevel=86
dangerouslevel=99

# Exclude list of unwanted monitoring, if several partions then use "|" to separate the partitions.
# An example: EXCLUDE_LIST="/dev/hdd1|/dev/hdc5"
EXCLUDE_LIST="/dev/sda1"
#
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#

cutoffday=183
gday=183
total=0


NOW=$(date +%Y-%m-%d_%H:%M:%S)

echo "program start @ $(date +%Y-%m-%d_%H:%M:%S)" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log

main_prog()
{
  while read output;  ##reading the df command result into each line
   do
    #echo $output
    usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
    partition=$(echo $output | awk '{print $2}')

    ## check if it is reached to line - mnt/ftpspace
    if [ $partition = "/mnt/ftpspace" ] ; then

      ## run a loop to check the percentage level of storage size
      ## lower than 86 percent will search files older than 183
      ## equal or more than 86 will search files by growth rate formula
      for (( alert=safelevel; alert<=dangerouslevel; alert++ ))
        do
          ## a formula to get the growth rate day
          gday=`echo "$gday - ($gday * 0.16)" | bc`
          counter=0

          echo "Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log

          if [ $usep -ge $alert ] ; then
            counter=$gday
          elif [ $usep -lt $safelevel ] ; then
            counter=$cutoffday
            alert=$dangerouslevel
          fi

          if [ $counter -gt 0 ] ; then
            total="$(find /mnt/ftpspace/inspector/savehere/ -type f -ctime +$counter | grep -c / )"
            echo "${total} files are older than $counter days!" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log
          fi

          if [ $total -gt 0 ] ; then
            echo "${total} files are removed!" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log
            find /mnt/ftpspace/inspector/savehere/ -type f -ctime +$counter -print >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log -exec chattr -i {} \; -exec rm -f {} \;
            ##find /mnt/ftpspace/inspector/savehere/jimmy.test -type f -ctime +$counter -print >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log -exec chattr -i {} \;
            exit 0
          fi
      done

      exit 0

    fi

  done
}

## a command to get the storage size on each device
if [ "$EXCLUDE_LIST" != "" ] ; then
   df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
   df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi


echo "program end @ $(date +%Y-%m-%d_%H:%M:%S)" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log

echo "===========================" >> /var/log/cron-result/$(date +%Y-%m-%d_RemovedFiles).log
