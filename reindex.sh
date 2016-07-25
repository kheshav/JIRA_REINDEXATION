#!/bin/bash
#Author: Kheshav Sewnundun (arvin_sew_kheshav@hotmail.com)
#TAG: 1.0.0

USERNAME="XXXX"
MDP="XXXX"
JIRAURL="http://127.0.0.1:8080"
JIRABACKGROUND_INDEX="/rest/api/2/reindex?type=BACKGROUND"
LOG="Reindex.log"

ReindexCmd=`curl -u $USERNAME:$MDP -X POST $JIRAURL$JIRABACKGROUND_INDEX`

ReindexProgress=0
PreviousProgress=0


function restartJIRA() {
	status=""
	echo "[`date`]: [Info] Stopping Jira" >> $LOG
	`service jira stop`
	cmd=`ps -u jira`
	if [ $? == 1 ] ; then
		echo "[`date`]: [Info] Jira Stopped" >> $LOG
		echo "[`date`]: [Info] Sarting Jira" >> $LOG
		`service jira start`
		echo "[`date`]: [Info] Jira Started" >> $LOG
		echo "[`date`]: [Info] Checking for Running Status...Please wait.." >> $LOG
		while [ "$status" != "RUNNING" ] ; do
			sleep 10
			dummylogin=`curl -u test:test http://127.0.0.1:8080`
			status=`curl  http://127.0.0.1:8080/status| python -c 'import json,sys;obj=json.load(sys.stdin);print obj["state"]'`
			dummylogin=`curl -u test:test http://127.0.0.1:8080`
			echo "[`date`]: [Warning] Jira status: $status" >> $LOG
			if [ $status == "RUNNING" ] ; then
				echo "[`date`]: [Info] Jira Status Runnning" >> $LOG
			fi
		done
	else
		echo "[`date`]: [Error] Jira NOT Stopped!!!!!" >> $LOG
		exit 1
	fi
}

echo "[`date`]: [INFO] reIndexing in Process" >> $LOG
while [ $ReindexProgress -ne 100 ]; do
	ReindexCmdProgress=`curl -u $USERNAME:$MDP $JIRAURL/rest/api/2/reindex`
	ReindexProgress=`echo $ReindexCmdProgress | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["currentProgress"]'`
	if [ $PreviousProgress -ne $ReindexProgress ] ; then
		sleep 10
		echo $ReindexCmdProgress >> $LOG
	fi
	PreviousProgress=$ReindexProgress
done
if [ $ReindexProgress -ne 100 ] ; then
	echo "[`date`]: [Error] reIndexing not done properly!!!!" >> $LOG
	exit 1
else
	echo "[`date`]: [Sucess] reIndexing DONE" >> $LOG
	if [ $(date +\%d) -le 07 ] ; then
		restartJIRA
	fi
fi
exit 0
