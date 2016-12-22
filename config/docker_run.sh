#!/bin/sh

RET=1
while [ $RET -ne 0 ]; do
    mysql -h $DB_SERVER -P $DB_PORT -u $DB_USER -p$DB_PASSWD -e "status" > /dev/null 2>&1
    RET=$?
    if [ $RET -ne 0 ]; then
        echo "\n* Waiting for confirmation of MySQL service startup";
        sleep 5
    fi
done

# if not already installed, apply installation (copied from https://github.com/PrestaShop/docker/blob/master/config_files/docker_run.sh)
if [ ! -f ./config/settings.inc.php  ]; then

	echo "\n* Reapplying PrestaShop files for enabled volumes ...";
	bash /tmp/ps-extractor.sh /tmp/data-ps

	if [ $PS_DEV_MODE -ne 0 ]; then
		echo "\n* Enabling DEV mode ...";
		sed -ie "s/define('_PS_MODE_DEV_', false);/define('_PS_MODE_DEV_',\ true);/g" /var/www/html/config/defines.inc.php
	fi

	if [ $PS_HOST_MODE -ne 0 ]; then
		echo "\n* Enabling HOST mode ...";
		echo "define('_PS_HOST_MODE_', true);" >> /var/www/html/config/defines.inc.php
	fi

	if [ $PS_FOLDER_ADMIN != "admin" ]; then
		echo "\n* Renaming admin folder as $PS_FOLDER_ADMIN ...";
		mv /var/www/html/admin /var/www/html/$PS_FOLDER_ADMIN/
	fi

	if [ $PS_HANDLE_DYNAMIC_DOMAIN = 0 ]; then
		rm /var/www/html/docker_updt_ps_domains.php
	else
		sed -ie "s/DirectoryIndex\ index.php\ index.html/DirectoryIndex\ docker_updt_ps_domains.php\ index.php\ index.html/g" $APACHE_CONFDIR/conf-available/docker-php.conf
	fi

	echo "\n* Check database existence ...";
	RET=1
	mysql -h $DB_SERVER -P $DB_PORT -u $DB_USER -p$DB_PASSWD -e "use $DB_NAME" > /dev/null 2>&1
	RET=$?
	if [ $RET -ne 0 ]; then
			echo "\n* Create new database ....";
			mysqladmin -h $DB_SERVER -P $DB_PORT -u $DB_USER -p$DB_PASSWD drop $DB_NAME --force 2> /dev/null;
			mysqladmin -h $DB_SERVER -P $DB_PORT -u $DB_USER -p$DB_PASSWD create $DB_NAME --force 2> /dev/null;
			export PS_DOMAIN=$(hostname -i)

			echo "\n* Installing Prestashop ....";
			php /var/www/html/install/index_cli.php --domain="$PS_DOMAIN" --db_server=$DB_SERVER:$DB_PORT --db_name="$DB_NAME" --db_user=$DB_USER \
				--db_password=$DB_PASSWD --firstname="John" --lastname="Doe" \
				--password=$ADMIN_PASSWD --email="$ADMIN_MAIL" --language=$PS_LANGUAGE --country=$PS_COUNTRY \
				--newsletter=0 --send_email=0
	fi

  # remove install folder
	echo "\n* Removing install folder ...";
  rm -rf /var/www/html/install

	echo "\n* Pre-instaling PrestaShop ...";

  # remove template files
  rm -f /var/www/html/config/xml/default_country_modules_list.xml
  rm -f /var/www/html/config/xml/modules_native_addons.xml
  rm -f /var/www/html/config/xml/must_have_modules_list.xml
  rm -f /var/www/html/config/xml/tab_modules_list.xml

  # remove themes
	rm -rf /var/www/html/config/themes

	# replace configuration file placeholder with env values
	sed -ie "s/%DB_SERVER/$DB_SERVER/g" /tmp/existing/app/config/parameters.yml
	sed -ie "s/%DB_USER/$DB_USER/g" /tmp/existing/app/config/parameters.yml
	sed -ie "s/%DB_PASSWD/$DB_PASSWD/g" /tmp/existing/app/config/parameters.yml
	sed -ie "s/%DB_NAME/$DB_NAME/g" /tmp/existing/app/config/parameters.yml
	sed -ie "s/%PS_LANGUAGE/$PS_LANGUAGE/g" /tmp/existing/app/config/parameters.yml
	sed -ie "s/%PS_COUNTRY/$PS_COUNTRY/g" /tmp/existing/app/config/parameters.yml

	# and merge with provided existing configuration files
  mv /tmp/existing/app/config/parameters.yml /var/www/html/app/config
  mv /tmp/existing/app/Resources/translations/fr-FR /var/www/html/app/Resources/translations
  mv /tmp/existing/config/* /var/www/html/config
  mv /tmp/existing/translations/cldr/datas/main /var/www/html/translations/cldr/datas
  mv /tmp/existing/translations/cldr/main--fr-* /var/www/html/translations/cldr
  mv /tmp/existing/translations/cldr/supplementl--* /var/www/html/translations/cldr
  mv /tmp/existing/translations/0*.zip /var/www/html/translations
  mv /tmp/existing/.htaccess /var/www/html

	chown www-data:www-data -R /var/www/html/app/config
	chown www-data:www-data -R /var/www/html/config
	chmod 740 /var/www/html/.htaccess
	chown www-data:www-data -R /var/www/html/.htaccess

	# cleanup
	rm -rf /tmp/existing
	echo "\n* PrestaShop ready to be used with existing DB !";
fi

echo "\n* Starting Apache ...\n";
exec apache2-foreground