sudo apt-get update
sudo apt-get upgrade -y

read -p "
https://github.com/inex/IXP-Manager/wiki/Installation-02-Downloading
Press [Enter] key to start
"

echo "
=== Install git
"
sudo apt-get install git -y

echo "
=== Clone IXP Manager from the git repo
"
cd /usr/local
sudo git clone https://github.com/inex/IXP-Manager.git ixp
cd /usr/local/ixp
sudo git checkout v3.8
cd

echo "
=== Install PHP5
"
sudo apt-get install php5 -y

echo "
=== Install Composer
"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

echo "
=== Change owner of ixp directory to myself
"
sudo chown -R `whoami` /usr/local/ixp

echo "
=== Run composer
"
cd /usr/local/ixp
~/composer.phar update

echo "
=== Perl libraries - prerequisites
"
sudo apt-get install build-essential libconfig-general-perl libdbd-mysql-perl libdbi-perl libdaemon-control-perl libnetaddr-ip-perl libnetpacket-perl libnet-snmp-perl mrtg librrds-perl libtemplate-perl -y
sudo cpan Crypt::DES Crypt::Rijndael Digest::SHA1

echo "
=== Perl libraries
"
cd /usr/local/ixp/tools/perl-lib/IXPManager
perl Makefile.PL
sudo make install

read -p "
=== You should set database settings now in /usr/local/etc/ixpmanager.conf
Press [Enter] key to start
"
sudo cp /usr/local/ixp/tools/perl-lib/IXPManager/ixpmanager.conf.dist /usr/local/etc/ixpmanager.conf
sudo nano /usr/local/etc/ixpmanager.conf

read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-03-Database-Creation
Press [Enter] key to start
"

echo "
=== Install MySQL Server
"
sudo apt-get install mysql-server -y

echo "
=== Create database and user
"
read -p "Enter a password for the ixp user:
" -s IXPPASSWORD

echo "
mysql -u root -p
"
echo "
CREATE DATABASE ixp CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
GRANT ALL ON ixp.* TO ixp@127.0.0.1 IDENTIFIED BY '$IXPPASSWORD';
GRANT ALL ON ixp.* TO ixp@localhost IDENTIFIED BY '$IXPPASSWORD';
FLUSH PRIVILEGES;
" | mysql -u root -p

unset IXPPASSWORD


read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-04-Configuration
Press [Enter] key to start
"

echo "
=== Copy the sample application ini
"
cd /usr/local/ixp
cp application/configs/application.ini.dist application/configs/application.ini

read -p "
You now need to edit that file which is commented in detail. Get a cup of coffee first and make sure you read right through it!
Some of the more important areas are:
 * Doctrine2 settings
 * Logger settings
 * SMTP relay host
 * Organisational details

Press [Enter] key to start
"
nano application/configs/application.ini



read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-05-Database-Setup
Press [Enter] key to start
"
echo "
=== set public/.htaccess file
"
cp public/.htaccess.dist public/.htaccess

echo "
=== Install prerequisites
"
sudo apt-get install memcached php5-memcache php5-mysql -y

echo "
=== Creating the Schema
"
cd /usr/local/ixp/bin
./doctrine2-cli.php orm:schema-tool:create

cd /usr/local/ixp
echo "
mysql -u ixp -p ixp < tools/sql/views.sql
"
mysql -u ixp -p ixp < tools/sql/views.sql




read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-06-Apache-Setup
Press [Enter] key to start
"
echo "
=== Enable apache mod_rewrite
"
sudo a2enmod rewrite

read -p "
Copy this text:
    Alias /ixp /usr/local/ixp/public
    <Directory /usr/local/ixp/public>
        Options FollowSymLinks
        AllowOverride None
        Require all granted

        SetEnv APPLICATION_ENV production

        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} -s [OR]
        RewriteCond %{REQUEST_FILENAME} -l [OR]
        RewriteCond %{REQUEST_FILENAME} -d
        RewriteRule ^.*$ - [NC,L]
        RewriteRule ^.*$ /ixp/index.php [NC,L]
    </Directory>

Then press [Enter] key and paste it inside the VirtualHost tags.
"
sudo nano /etc/apache2/sites-available/000-default.conf

echo "
=== Fix permissions so apache can read and write
"
sudo chown -R www-data /usr/local/ixp
sudo chmod -R u+rX /usr/local/ixp
sudo chmod -R u+w /usr/local/ixp/var

echo "
=== Restart apache to apply changes
"
sudo service apache2 restart


read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-07-Creating-Initial-Database-Objects
Press [Enter] key to start
"

echo "
=== Create /usr/local/ixp/bin/fixtures.php
"
cd /usr/local/ixp/bin
sudo cp fixtures.php.dist fixtures.php

read -p "
=== Edit fixtures.php
When you edit fixtures.php, skip to MODIFY YOUR FIXTURES HERE. What you are creating is:
 * the initial customer entry which is your IXP.
 * the initial administrative user.
You need to edit these objects in fixtures.php to match your own scenario.

Press [Enter] key to start editting
"
sudo nano fixtures.php

echo "
=== Fix permissions
"
chown www-data fixtures.php

echo "
=== Run fixtures.php
"
sudo -u www-data ./fixtures.php


read -p "
=== https://github.com/inex/IXP-Manager/wiki/Installation-08-Setting-Up-Your-IXP
Press [Enter] key to start
"

echo "
At this point, you should be able to log into your IXP Manager at http://hostname/ixp using the administrative user you defined in the fixtures.php file from the previous step.

You now need to start adding the nuts and bolts of your IXP into IXP Manager.
"
