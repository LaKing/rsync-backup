#!/bin/bash

## Generic backup script 1.0 - D250 Laboratories
## Written by István Király - LaKing@D250.hu
## https://github.com/LaKing/rsync-backup
## The questionmark argument will not do any syncing, only query disk usages.
## This file can be sourced, or edited and backup commands can be added at the bottom.
## ssh key-authentication, and fingerprint configuration required.



## check arguments
if [ "$1" == "-h" ] || [ "$1" == "--help" ] 
then
    head -n 9 $0 | grep "##" | tr "##" '   '
    echo ''
    exit
fi

## logs about the whole process
    LOG=$0.log

## do a test-only/measure disk usage - or - do a full backup?
    full_backup=true

if [ -z "$BACKUP_PATH" ]
then
    BACKUP_PATH="$1"
fi

## most important variable
if [ ! -d "$BACKUP_PATH" ]
then
    head -n 9 $0 | grep "##" | tr "##" '   '
    echo ''
    echo "Variable BACKUP_PATH not defined. Define either as argument or exported variable."
    echo ''
    exit
else

    echo $BACKUP_PATH
    df -h $BACKUP_PATH
    echo ''


    if [ "$1" == "query" ] || [ "$1" == "?" ] 
    then
        head -n 9 $0 | grep "##" | tr "##" '   '
        echo ''
        full_backup=false
    fi
fi

## function that will timestamp
function log {

    NOW=$(date +%Y-%m-%d-%H:%M:%S)
    echo "$NOW - $1" >> $LOG

}

    log "START full-backup: $full_backup"
    log "backup to: $BACKUP_PATH"

## local backup from a local folder
function local_backup {

    backup_dirs="${@:1}"
    backup_target=$BACKUP_PATH/$(hostname)

    for i in $backup_dirs
    do
        backup_log=$backup_target/$i.log
        echo $(hostname):$i
        mkdir -p $backup_target/$i

        du -hs $backup_target/$i
        du -hs $i

        log "@  $(hostname):$i"

        if $full_backup
        then
            if rsync --delete -av $i $backup_target >> $backup_log
            then
                log "done $(hostname) @ $i"
            else
                log "done $(hostname) @ $i"
                echo "done $(hostname) @ $i"
            fi
        fi
        echo ''
    done
    echo ''
}

## local backup from a server
function server_backup {

    backup_host="$1"
    backup_dirs="${@:2}"
    backup_target=$BACKUP_PATH/$backup_host

    for i in $backup_dirs
    do
        backup_log=$backup_target/$i.log
        echo $backup_host:$i
        mkdir -p $backup_target/$i
        du -hs $backup_target/$i
        log "@  $backup_host:$i"

        cmd='echo "$(du -hs '$i') $(hostname)/'$i'"'
        if ssh -o BatchMode=yes $backup_host "$cmd"
        then
            if $full_backup
            then
                if rsync --delete -avze ssh $backup_host:/$i $backup_target >> $backup_log
                then
                    log "done  $backup_host @ $i"
                else
                    log "ERROR $backup_host @ $i"
                    echo "ERROR $backup_host @ $i"
                fi
            fi
        else
            echo "!! Connection failed to $backup_host."
        fi
        echo ''
    done
    echo ''
}

## local backup of a host thru an ssh-tunneling proxy-server
function remote_backup {

    backup_proxy="$1"
    backup_host="$2"
    backup_dirs="${@:3}"
    backup_target=$BACKUP_PATH/$backup_host

    for i in $backup_dirs
    do
        backup_log=$backup_target/$i.log
        echo $backup_host:$i 
        mkdir -p $backup_target/$i
        du -hs $backup_target/$i
        log "@  $backup_host:$i"

        cmd='echo "$(du -hs '$i') $(hostname)/'$i'"'
        if ssh -o BatchMode=yes $backup_proxy "ssh -o BatchMode=yes $backup_host '$cmd'"
        then

            if $full_backup
            then
                if rsync --delete -avz -e "ssh -A $backup_proxy ssh" $backup_host:/$i $backup_target >> $backup_log
                then
                    log "done  $backup_host @ $i"
                else
                    log "ERROR $backup_host @ $i"
                    echo "ERROR $backup_host @ $i"
                fi
            fi
        else
            echo "!! Connection failed to $backup_proxy"
        fi
        echo ''
    done
    echo ''
}

## examples:
## create a local backup

    #local_backup /etc /root /srv

## create a remote backup

    #server_backup s1.example.com /etc /root 
    #server_backup s2.example.com /etc /root 

## create a remote tunneled backup

    #remote_backup example.com 10.9.8.7 /etc /srv /mnt

## either add your own settings here, or source this file