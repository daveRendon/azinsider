#!/bin/sh

# Install required packages
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
add-apt-repository universe
apt-get -y install apt-transport-https
apt-get -y update
apt-get -y install apache2 dotnet-sdk-2.2 unzip

# Copy site to /var/www/votingweb
unzip -d /var/www/votingweb votingweb.zip
chown -hR www-data:www-data /var/www/votingweb

# Enable required Apache modules
a2enmod headers
a2enmod proxy_html
a2enmod proxy_http

# Disable default Apache site
a2dissite 000-default

# Setup VotingWeb Apache site
cp votingweb.conf /etc/apache2/sites-available
a2ensite votingweb

# Setup VotingWeb as a service
cp votingweb.service /etc/systemd/system
systemctl enable votingweb.service
systemctl start votingweb.service

# Restart Apache
systemctl restart apache2