#!/bin/bash
set -e

# Setup the chroot
/usr/lib/postfix/configure-instance.sh

# fixup syslogging for smtp service.
# currently unsure if this is a misconfig somewhere or a postfix bug but the
# "smtp" daemon is trying to open the postlog socket with an absolute path from
# inside its choort
install -d -o postfix -g postdrop -m 2710 /var/spool/postfix/var/spool/postfix/public/
ln -s --relative /var/spool/postfix/public/postlog  /var/spool/postfix/var/spool/postfix/public/

# Run logging daemon
#echo "postlog   unix-dgram n  -       n       -       1       postlogd" >> /etc/postfix/master.cf

# Log to stdout
postconf -e maillog_file=/dev/stdout

MAILNAME=${MAILNAME:-$(hostname)}
if [[ ! -z "$MAILNAME" ]]; then
	echo "$MAILNAME" > /etc/mailname
	postconf -e myorigin="/etc/mailname"
fi


if [[ ! -z "$ROOT_ALIAS" ]]; then
	if [[ -f /etc/aliases ]]; then
		sed -i '/^root:/d' /etc/aliases
	fi
	echo "root: $ROOT_ALIAS" >> /etc/aliases
	newaliases
fi

if [[ ! -z "$TLS" ]]; then
	# setup tls
	cat >> /etc/postfix/main.cf <<- EOF
	smtp_use_tls = yes
	smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
  smtp_tls_loglevel = 2
	EOF
fi

if [[ ! -z "$SASL_AUTH" ]]; then
  postconf -e smtp_sasl_auth_enable=yes
  postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
  postconf -e smtp_sasl_security_options=noanonymous

	# generate the SASL password map
	echo "$RELAYHOST $SASL_AUTH" > /etc/postfix/sasl_passwd

	# generate a .db file
	postmap /etc/postfix/sasl_passwd

	# cleanup
	rm /etc/postfix/sasl_passwd

	# set permissions
	chmod 600 /etc/postfix/sasl_passwd.db
fi

# Set any recognised configs from ENV vars
for key in $(postconf | awk '{print toupper($1)}' | grep -E '^[A-Z_]+$') ; do
    if [ ! -z "${!key}" ] ; then
        echo "Setting ${key,,} = ${!key}"
        postconf -e "${key,,}"="${!key}"
    fi
done

exec postfix start-fg
