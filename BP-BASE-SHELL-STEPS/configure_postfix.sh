#!/bin/bash

function postfix_conf() {

SENDER_MAIL_ID="$1"
PASSCODE_KEY="$2"    
SASL_PASSWD_FILE="/etc/postfix/sasl_passwd"

# Configuration details
CONFIGURATION="[smtp.gmail.com]:587 $SENDER_MAIL_ID:$PASSCODE_KEY"
echo "$CONFIGURATION" > "$SASL_PASSWD_FILE"
# Remove relayhost from main.cf
sed -i '/^relayhost =/d' /etc/postfix/main.cf
# Add configuration to sasl_passwd file

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
