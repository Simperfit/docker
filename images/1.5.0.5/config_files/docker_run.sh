#!/bin/sh

if [ $DB_SERVER = "localhost" ] || [ $DB_SERVER = "127.0.0.1" ]; then
	service mysql start
fi

if [ $PS_DEV_MODE -ne 0 ]; then
	#echo "Set DEV MODE > true";
	sed -ie "s/define('_PS_MODE_DEV_', false);/define('_PS_MODE_DEV_',\ true);/g" /var/www/html/config/defines.inc.php
fi

if [ $PS_HOST_MODE -ne 0 ]; then
	#echo "Set HOST MODE > true";
	echo "define('_PS_HOST_MODE_', true);" >> /var/www/html/config/defines.inc.php
fi

if [ $PS_INSTALL_AUTO = 0 ]; then
	echo "\nExecuting PrestaShop without installation ...";
	rm /var/www/html/docker_updt_ps_domains.php
else
	echo "Installing PrestaShop, this may take a while ...";
	if [ $DB_PASSWD = "" ]; then
		mysqladmin -h $DB_SERVER -u $DB_USER drop $DB_NAME --force 2> /dev/null;
		mysqladmin -h $DB_SERVER -u $DB_USER create $DB_NAME --force 2> /dev/null;
	else
		mysqladmin -h $DB_SERVER -u $DB_USER -p$DB_PASSWD drop $DB_NAME --force 2> /dev/null;
		mysqladmin -h $DB_SERVER -u $DB_USER -p$DB_PASSWD create $DB_NAME --force 2> /dev/null;
	fi

	sed -ie "s/DirectoryIndex\ index.php\ index.html/DirectoryIndex\ docker_updt_ps_domains.php\ index.php\ index.html/g" /etc/apache2/apache2.conf

	php /var/www/html/install-dev/index_cli.php --domain=$(hostname -i) --db_server=$DB_SERVER --db_name="$DB_NAME" --db_user=$DB_USER \
		--db_password=$DB_PASSWD --firstname="John" --lastname="Doe" \
		--password=$ADMIN_PASSWD --email="$ADMIN_MAIL" --language=$PS_LANGUAGE\
		--newsletter=0 --send_email=0

	chown www-data:www-data -R /var/www/html/
fi

/usr/sbin/apache2ctl -D FOREGROUND
