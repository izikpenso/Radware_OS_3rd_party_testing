#!/bin/bash

GERRIT_USER="radware3rdpartytesting"
GERRIT_JSON_FILE="gerrit.json"
CURRENT_TIMESTAMP=$(date +%s)
RECHECK_NO_BUG="*recheck bug*"
RECHECK_BUG="*recheck no bug*"
touch $GERRIT_JSON_FILE
TRIGGER_FLAG=false
if [ $GERRIT_EVENT_TYPE="comment-added" ]; then
        ssh -p 29418 $GERRIT_USER@$GERRIT_HOST gerrit query --format=JSON --comments $GERRIT_CHANGE_ID > $GERRIT_JSON_FILE
        COUNT=$(cat $GERRIT_JSON_FILE | grep -o message | wc -l)
        for (( i=0; i < $COUNT; i++ ))
        do
                COMMENT_TIMESTAMP=$(cat $GERRIT_JSON_FILE | jq '.comments['"$i"'].timestamp'| head -1)
                DIFF=$(($CURRENT_TIMESTAMP-$COMMENT_TIMESTAMP))
                DIFF_MIN=$(($DIFF / 60))
                DIFF_SEC=$(($DIFF % 60))
                if [ $DIFF_MIN -eq 0 ]  && [ $DIFF_SEC -lt 40 ]; then
                        echo " with in the last 35 sec"
                        COMMENT_MESSAGE=$(cat $GERRIT_JSON_FILE | jq '.comments['"$i"'].message'| head -1)
                        if [[ ${COMMENT_MESSAGE} == $RECHECK_NO_BUG || ${COMMENT_MESSAGE} == $RECHECK_BUG ]]; then
                           TRIGGER_FLAG=true
                           break;
                        fi
                fi
        done
        echo "export TRIGGER_FLAG=$TRIGGER_FLAG" >> $1
fi

