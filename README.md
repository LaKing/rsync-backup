Bash script that performs local, remote, and ssh tunneled backups with rsync and disk usage analysis.

To use it, source it!

```
#!/bin/bash

## set the backup target
BACKUP_PATH=/mnt/backup-drive

## update the script
curl https://raw.githubusercontent.com/LaKing/rsync-backup/master/backup.sh > backup.sh

## use the script
source backup.sh

## Action! ... for example:
## create a local backup with pure rsync

    local_backup /etc /root /srv

## create a remote backup from s1 and s2 via ssh

    server_backup s1.example.com /etc /root /srv
    server_backup s2.example.com /etc /root /home

## create a remote backup via ssh tunnel. The proxy is example.com

    remote_backup example.com 10.9.8.7 /etc /srv /var/www/html

```

Make sure all remote servers and all tunnels have ssh key based authentication, and fingeprint identifications set up.
Needless to say, rsync and ssh have to be installed too.