#!/bin/bash

function bucketExist() {
    BUCKET="$1"

    BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$BUCKET" 2>&1 || true)
    if [ -z "$BUCKET_EXISTS" ]; then
        echo 0
    else
        echo 1
    fi
}

function getAccountId() {
    aws sts get-caller-identity --query "Account" --output text
}

function copyFileToS3() {
    SOURCE_FILE="$1"
    S3_BUCKET="$2"
    KEY_NAME="$3"

    aws s3 cp "${SOURCE_FILE}" "s3://${S3_BUCKET}/${KEY_NAME}"
}

function copyFileFromS3() {
    S3_BUCKET="$1"
    FILE_KEY="$2"
    FILE_PATH="$3"
    aws s3 cp "s3://${S3_BUCKET}/${FILE_KEY}" "${FILE_PATH}"
}

function policyExists() {
    POLICY_ARN="$1"

    aws iam get-policy --policy-arn "${POLICY_ARN}" >/dev/null 2>&1
    echo $?
}

function createPolicy() {
    POLICY_NAME="$1"
    POLICY_FILE_PATH="$2"

    aws iam create-policy \
    --policy-name "${POLICY_NAME}" --no-paginate \
    --policy-document "file://${POLICY_FILE_PATH}"
}

function roleExists() {
    ROLE_NAME="$1"

    aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1
    echo $?
}

function createRole() {
    ROLE_NAME="$1"
    POLICY_DOCUMENT="$2"
    aws iam create-role --role-name "${ROLE_NAME}" --no-paginate --assume-role-policy-document "file://${POLICY_DOCUMENT}"
}

# Function to create IAM user
createIAMUser() {
  local user_output
  local user_arn
  local keys_output

  # Check if the user already exists
  if aws iam get-user --user-name "$USERNAME" &>/dev/null; then
    logInfoMessage "User $USERNAME already exists."
    TASK_STATUS=1
    return
  fi

  # If the user does not exist, create the user
  user_output=$(aws iam create-user --user-name "$USERNAME")
  user_arn=$(echo "$user_output" | jq -r '.User.Arn')

  case "$CONSOLE_ACCESS-$PROGRAMMATIC_ACCESS" in
    "yes-yes") createIAMUserConsoleAndProgrammaticAccess ;;
    "no-yes") createIAMUserProgrammaticAccess ;;
    *) createIAMUserConsoleAccess ;;
  esac

  [ -n "$GROUPNAME" ] && aws iam add-user-to-group --user-name "$USERNAME" --group-name "$GROUPNAME" && logInfoMessage "User $USERNAME added to group $GROUPNAME."

# Creating Credential File
createCredentialFile

# Sending Creds file to User
  mail -s "$USERNAME AWS Credentials" $SENDER_MAIL_ID <Credential.txt
}

# Function to create IAM user with Console and Programmatic Access

changePasswordPolicy(){
aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

accessSecretKey(){
  keys_output=$(aws iam create-access-key --user-name "$USERNAME")
  access_key_id=$(echo "$keys_output" | jq -r '.AccessKey.AccessKeyId')
  secret_access_key=$(echo "$keys_output" | jq -r '.AccessKey.SecretAccessKey')
}

loginProfile(){
aws iam create-login-profile --user-name "$USERNAME" --password "$DEFAULT_PASSWORD" --password-reset-required
}
createIAMUserConsoleAndProgrammaticAccess() {
  logInfoMessage "Creating IAM user $USERNAME with Console and Programmatic Access"
    changePasswordPolicy
    loginProfile
    accessSecretKey
}

# Function to create IAM user with Programmatic Access only
createIAMUserProgrammaticAccess() {
  logInfoMessage "Creating IAM user $USERNAME with Programmatic Access..."
    accessSecretKey
}

# Function to create IAM user with Console Access only
createIAMUserConsoleAccess() {
  logInfoMessage "Creating IAM user $USERNAME with only Console Access."
    changePasswordPolicy
    loginProfile
}

# Function to create Credential file

createCredentialFile() {
case "$PROGRAMMATIC_ACCESS" in
  "yes")
    {
      echo "Hi $USERNAME, Please find your 'AWS Credentials' below:"
      echo
      echo "#### User Details ####"
      echo
      echo "1. USERNAME: $USERNAME"
      echo "2. Default Password: $DEFAULT_PASSWORD"
      echo "3. USER Attached to GROUP: $GROUPNAME"
      echo "4. User_Arn: $user_arn"
      echo "5. Access Key ID: $access_key_id"
      echo "6. Secret Access Key: $secret_access_key"
      echo 
      echo "Kindly let us know if you face any issue in logging."
      echo
      echo "Thanks & Regards"
      echo "BuildPiper -Microservice DevOps Simplified"
    } >>Credential.txt
    ;;
  *)
    {
      echo "Hi $USERNAME, Please find your 'AWS Credentials' below:"
      echo
      echo "*#### User Details ####"
      echo
      echo "1. USERNAME: $USERNAME"
      echo "2. Default Password: $DEFAULT_PASSWORD"
      echo "3. USER Attached to GROUP: $GROUPNAME"
      echo "4. User_Arn: $user_arn"
      echo
      echo "Kindly let us know if you face any issue in logging"
      echo "Thanks & Regards"
      echo
      echo "BuildPiper -Microservice DevOps Simplified"

    } >>Credential.txt
    ;;
esac
}

function postfix_conf() {
SENDER_MAIL_ID="$1"
PASSCODE_KEY="$2"
SASL_PASSWD_FILE="/etc/postfix/sasl_passwd"

# Configuration details
CONFIGURATION="[smtp.gmail.com]:587 $SENDER_MAIL_ID:$PASSCODE_KEY"
echo "$CONFIGURATION" > "$SASL_PASSWD_FILE"
# Remove relayhost from main.cf
sed -i '/^relayhost =/d' /etc/postfix/main.cf

# Run postmap command
postmap "$SASL_PASSWD_FILE"

# Update main.cf
cat <<EOL >> /etc/postfix/main.cf
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
EOL
}
