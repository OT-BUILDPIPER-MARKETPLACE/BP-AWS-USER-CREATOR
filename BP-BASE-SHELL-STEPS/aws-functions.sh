# Function to create IAM user
createIAMUser() {
  local user_output
  local user_arn
  local keys_output

  user_output=$(aws iam create-user --user-name "$USERNAME")
  user_arn=$(echo "$user_output" | jq -r '.User.Arn')

  case "$CONSOLE_ACCESS-$PROGRAMMATIC_ACCESS" in
    "yes-yes") createIAMUserConsoleAndProgrammaticAccess ;;
    "no-yes") createIAMUserProgrammaticAccess ;;
    *) createIAMUserConsoleAccess ;;
  esac

  [ -n "$GROUPNAME" ] && aws iam add-user-to-group --user-name "$USERNAME" --group-name "$GROUPNAME" && logInfoMessage "User $USERNAME added to group $GROUPNAME."

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
