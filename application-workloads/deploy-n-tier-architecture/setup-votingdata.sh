#!/bin/sh

# Install required packages
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
add-apt-repository universe
apt-get -y install apt-transport-https
apt-get -y update
apt-get -y install apache2 dotnet-sdk-2.2 unzip

# Copy site to /var/www/votingdata
unzip -d /var/www/votingdata votingdata.zip

# Setup the SQL Server bits
# First parameter is the Azure SQL Server name
sed -i "s/%SQLSERVER%/$1/g" /var/www/votingdata/appsettings.json
# Second parameter is the username
sed -i "s/%USERNAME%/$2/g" /var/www/votingdata/appsettings.json
# Third parameter is the password
sed -i "s/%PASSWORD%/$3/g" /var/www/votingdata/appsettings.json

chown -hR www-data:www-data /var/www/votingdata

# Enable required Apache modules
a2enmod headers
a2enmod proxy_html
a2enmod proxy_http

# Disable default Apache site
a2dissite 000-default

# Setup VotingData Apache site
cp votingdata.conf /etc/apache2/sites-available
a2ensite votingdata

# Setup VotingData as a service
cp votingdata.service /etc/systemd/system
systemctl enable votingdata.service
systemctl start votingdata.service

# Restart Apache
systemctl restart apache2