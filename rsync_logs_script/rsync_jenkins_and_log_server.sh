#!/bin/bash

touch rsync_jenkins_log_server.log || exit

echo '******************************************************************************************' >> rsync_jenkins_log_server.log
echo '' >> rsync_jenkins_log_server.log
date >> rsync_jenkins_log_server.log

echo "rsync -uvre "ssh -i rsync-key/log-sync-proxy-rsync-key" jenkins@10.210.49.223:~/os-ci-logs rsync-dir/" >> rsync_jenkins_log_server.log

echo '' >> rsync_jenkins_log_server.log

rsync -uvre "ssh -i rsync-key/log-sync-proxy-rsync-key" jenkins@10.210.49.223:~/os-ci-logs rsync-dir/ >> rsync_jenkins_log_server.log

echo '' >> rsync_jenkins_log_server.log

echo "rsync -urve "ssh -i rsync-key/log-sync-proxy-rsync-key" rsync-dir/os-ci-logs/* radware@192.168.101.46:/data/RADWARE-CI-LOGS/" >> rsync_jenkins_log_server.log

rsync -urve "ssh -i rsync-key/log-sync-proxy-rsync-key" rsync-dir/os-ci-logs/* radware@192.168.101.46:/data/RADWARE-CI-LOGS/ >> rsync_jenkins_log_server.log

echo '******************************************************************************************' >> rsync_jenkins_log_server.log
echo '' >> rsync_jenkins_log_server.log

