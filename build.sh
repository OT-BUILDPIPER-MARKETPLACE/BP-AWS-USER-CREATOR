#!/bin/bash

source ./BP-BASE-SHELL-STEPS/configure_postfix.sh
source ./BP-BASE-SHELL-STEPS/log-functions.sh
source ./BP-BASE-SHELL-STEPS/functions.sh
source ./BP-BASE-SHELL-STEPS/aws-functions.sh

USERNAME="$USERNAME"
GROUPNAME="${GROUPNAME}"
CONSOLE_ACCESS="${CONSOLE_ACCESS}"
PROGRAMMATIC_ACCESS="${PROGRAMMATIC_ACCESS}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD}"

postfix_conf "$SENDER_MAIL_ID" "$PASSCODE_KEY"
chown -R postfix:postfix /var /etc /app
service postfix restart



# Check if username is provided
[ -z "$USERNAME" ] && { logErrorMessage "User name is not provided. Please provide the Username."; exit 1; }

# Check if groupname is provided, otherwise set default values
[ -z "$GROUPNAME" ] && logWarningMessage "Groupname not provided. Please enter user name for giving resource permission."

# Call the function to create IAM user
createIAMUser

sleep 10s
