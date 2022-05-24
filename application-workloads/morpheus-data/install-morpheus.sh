# download the relevant .deb package for installation. 
# This package can be acquired from https://morpheushub.com downloads section.
wget https://downloads.morpheusdata.com/files/morpheus-appliance_5.5.0-1_amd64.deb

# install the package onto the machine and configure the morpheus services
sudo dpkg -i morpheus-appliance_5.5.0-1_amd64.deb
sudo morpheus-ctl reconfigure
# Once the installation is complete the web interface will automatically start up. 
# By default it will be resolvable at https://your_machine_name and in many cases this may not be resolvable
# from your browser. The url can be changed by editing /etc/morpheus/morpheus.rb and changing the value of appliance_url. 
# After this has been changed simply run:
# sudo morpheus-ctl reconfigure
# sudo morpheus-ctl stop morpheus-ui
# sudo morpheus-ctl start morpheus-ui


# The morpheus-ui can take 2-3 minutes to startup before it becomes available!