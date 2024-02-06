#!/bin/bash

source ./BP-BASE-SHELL-STEPS/log-functions.sh
source ./BP-BASE-SHELL-STEPS/functions.sh
source ./BP-BASE-SHELL-STEPS/aws-functions.sh

USERNAME="$USERNAME"
GROUPNAME="${GROUPNAME}"
CONSOLE_ACCESS="${CONSOLE_ACCESS}"
PROGRAMMATIC_ACCESS="${PROGRAMMATIC_ACCESS}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD}"
USER_MAIL_ID="${USER_MAIL_ID=}"

TASK_STATUS=0

postfix_conf "$SENDER_MAIL_ID" "$PASSCODE_KEY"
chown -R postfix:postfix /var /etc /app
service postfix restart



# Check if username is provided
[ -z "$USERNAME" ] && { logErrorMessage "User name is not provided. Please provide the Username."; TASK_STATUS=1; saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}; exit 1; }

# Check if groupname is provided, otherwise set default values
[ -z "$GROUPNAME" ] && logWarningMessage "Groupname not provided. Please enter user name for giving resource permission."

# Call the function to create IAM user
createIAMUser

saveTaskStatus ${TASK_STATUS} ${ACTIVITY_SUB_TASK_CODE}
sleep 10s
