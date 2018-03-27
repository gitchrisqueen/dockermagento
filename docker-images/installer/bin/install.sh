#!/bin/bash

set -e

# Wait for mysql and nginx to start first
dockerize -wait tcp://mysql:3306 -wait tcp://nginx:80 -timeout 1800s echo "MySQL and NXING are Ready"

#####################################
# Update the Magento Installation
# Arguments:
#   None
# Returns:
#   None
#####################################
function updateMagento() {
	cd /var/www/html

    # Update Composer
	#composer self-update
	#composer clearcache
	#composer update --prefer-source -vvv

	# Run Composer install/update command
	#composer update -vvv
	#composer update -vvv

}

#####################################
# Print URLs and Logon Information
# Arguments:
#   None
# Returns:
#   None
#####################################
function printLogonInformation() {
	baseUrl="http://$DOMAIN"
	frontendUrl="$baseUrl/"
	backendUrl="$baseUrl/$ADMIN_FRONTNAME"

	echo ""
	echo "phpMyAdmin: $baseUrl:8888"
	echo " - Username: ${MYSQL_USER}"
	echo " - Password: ${MYSQL_PASSWORD}"
	echo ""
	echo "Backend: $backendUrl"
	echo " - Username: ${ADMIN_USERNAME}"
	echo " - Password: ${ADMIN_PASSWORD}"
	echo ""
	echo "Frontend: $frontendUrl"
}


#####################################
# Fix the filesystem permissions for the magento root.
# Arguments:
#   None
# Returns:
#   None
#####################################
function fixFilesystemPermissions() {
	chmod -R go+rw "$MAGENTO_ROOT"
	chmod +x "$MAGENTO_ROOT/cron.sh"
	chmod +x "$MAGENTO_ROOT/cron.php"
}


#####################################
# A never-ending while loop (which keeps the installer container alive)
# Arguments:
#   None
# Returns:
#   None
#####################################
function runForever() {
	while :
	do
		sleep 1
	done
}

#####################################
# Update the base url for the default website and store in the database to use the configured Domain
# Arguments:
#   None
# Returns:
#   None
#####################################
function updateDBSettings() {

baseUrl="http://$DOMAIN/"
baseMediaUrl="${baseUrl}media/"
baseSkinUrl="${baseUrl}skin/"

# Fix the Base URL(s)
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='$baseUrl' where scope_id in (0,1) and path in ('web/unsecure/base_url','web/secure/base_url','admin/url/custom');"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='$baseMediaUrl' where scope_id in (0,1) and path in ('web/unsecure/base_media_url','web/secure/base_media_url');"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='$baseSkinUrl' where scope_id in (0,1) and path in ('web/unsecure/base_skin_url','web/secure/base_skin_url');"


# Make sure js/css merge files settings are turned off
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='0' where scope_id in (0,1) and path in ('dev/js/merge_files','dev/css/merge_css_files');"

# Fix the Solr settings
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='solr' where path = 'catalog/search/solr_server_hostname'";
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:query "UPDATE core_config_data set value='/solr' where path = 'catalog/search/solr_server_path'";

}


#####################################
# Setup the default admin user or update the password
# Arguments:
#   None
# Returns:
#   None
#####################################
function setupAdminUser() {

magerun --skip-root-check --root-dir="$MAGENTO_ROOT" \
		admin:user:create \
		"${ADMIN_USERNAME}" \
		"${ADMIN_EMAIL}" \
		"${ADMIN_PASSWORD}" \
		"${ADMIN_FIRSTNAME}" \
		"${ADMIN_LASTNAME}" \
		"Administrators"
}


# Fix the www-folder permissions
#chgrp -R 33 /var/www/html
chgrp -R 33 /var/www/html/web


# Check if the MAGENTO_ROOT direcotry has been specified
if [ -z "$MAGENTO_ROOT" ]
then
	echo "Please specify the root directory of Magento via the environment variable: MAGENTO_ROOT"
	exit 1
fi

# Check if the specified MAGENTO_ROOT directory exists
if [ ! -d "$MAGENTO_ROOT" ]
then
	mkdir -p $MAGENTO_ROOT
fi

# Check if there is already an index.php. If yes, abort the installation process.
#TODO: Change this so it checks against something else or something additional like connecting to the DB
if [ -e "$MAGENTO_ROOT/index.php" ]
then
	echo "Magento is already installed."

	echo "Preparing the Magerun Configuration"
    substitute-env-vars.sh /etc /etc/n98-magerun.yaml.tmpl

	echo "Updating Magento"
	updateMagento

	echo "Preparing the Magento Configuration"
    substitute-env-vars.sh /etc /etc/local.xml.tmpl

    echo "Overriding Magento Configuration"
    cp -v /etc/local.xml /var/www/html/web/app/etc/local.xml
    chgrp -R 33 $MAGENTO_ROOT/app/etc

	echo "Updating Database Settings"
    updateDBSettings

    echo "Fixing filesystem permissions"
	fixFilesystemPermissions

	echo "Enable Fullpage Cache"
    magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:enable
    magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:clean

    echo "Disable Configuration and Page Blocks Cache"
    magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable config
    magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable layout
    magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable block_html


	echo "Setting up Admin User"
    setupAdminUser

    echo "Update fininished"
	printLogonInformation

	#runForever
	exit 0
fi

echo "Preparing the Magerun Configuration"
substitute-env-vars.sh /etc /etc/n98-magerun.yaml.tmpl

echo "Installing Magento"
updateMagento

echo "Preparing the Magento Configuration"
substitute-env-vars.sh /etc /etc/local.xml.tmpl

echo "Overriding Magento Configuration"
cp -v /etc/local.xml /var/www/html/web/app/etc/local.xml
chgrp -R 33 $MAGENTO_ROOT/app/etc

echo "Installing Sample Data: Database"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:create
#curl -L ftp://firstx.org/magento-1.14.3.2-2017-02-06-07-12-50.tar.gz --user ChrisQ:happ5muhvcL6p7yj014a | tar xz -C $MAGENTO_ROOT

#databaseFilePath="$MAGENTO_ROOT/*.sql"
#magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:import $databaseFilePath
#rm $databaseFilePath

#TODL: Find way to import files from defalut location
#magerun --skip-root-check --root-dir="$MAGENTO_ROOT" db:import --compression="gz" "$MAGENTO_ROOT/2017-05-18_033913_magento.sql.gz"

#TODO: Add dbadmin database user (?)

echo "Updating Database Settings"
updateDBSettings

echo "Installing Sample Data: Reindex"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:clean
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" index:reindex:all

echo "Installing Sample Data: Admin User"
setupAdminUser

echo "Enable Fullpage Cache"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:enable

echo "Disable Configuration and Page Blocks Cache"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable config
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable layout
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:disable block_html

echo "Fixing filesystem permissions"
fixFilesystemPermissions

echo "Installation fininished"
printLogonInformation

runForever
exit 0
