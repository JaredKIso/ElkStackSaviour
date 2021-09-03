#!/bin/bash

updateSys () {				# This is a function to update and upgrade your system.
	echo -e "\033[1m{*} Starting system update process..."
	sudo apt update -y && sudo apt upgrade -y
	echo -e "\033[1m{*} System update process - Finished."
	echo "---------------------------------"
}

getJava () {				# This is a function to install Java
	echo -e "\033[1m{*} Starting Java 8 install process..."
	sudo apt install openjdk-11-jre-headless -y
	echo -e "\033[1m{*} Java  8 install process - Finished."
	echo "---------------------------------"
}

getElastic () {				# This is a function to install and setup Elastic
	echo -e "\033[1m{*} Starting Elasticsearch install process..."
	sleep 1 
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - 
	sudo apt-get install apt-transport-https
	echo " {*} ... adding repository ..."
	sleep 1
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
	echo " {*} ... checking for updates ..."
	sleep 1
	sudo apt update -y
	echo " {*} ... installing elasticsearch ..."
	sleep 1
	sudo apt install elasticsearch -y
	echo ""
	echo " ------------------------------------------------------"
	echo -e "\033[1m{*} Elasticsearch install process - Finished."
	echo " {*} Directory for the config file: /etc/elasticsearch "
	echo " {*} Config file name: elasticsearch.yml"
	echo " ------------------------------------------------------"
	sleep 1
	echo -e "\033[1m{*} Configuring config with recommended settings."				# The following should configure the config.
	echo " {*} Replacing text in config..."	
	sudo sed -i '56s/.*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
	sudo sed -i '61s/.*/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
	echo " {*} Replaced."
	echo "---------------------------------"
}

getKib () {
	echo -e "\033[1m{*} Starting Kibana install process..."
	sleep 1
	sudo apt install kibana -y
	echo ""
	echo "-------------------------------------------------"
	echo -e "\033[1m{*} Kibina install process - Finished."
	echo " {*} Directory for config: /etc/kibana"
	echo " {*} Confige file name: kibana.yml"
	echo "-------------------------------------------"
	sleep 1
	echo -e "\033[1m{*} Configuring config with recommended settings."				# This will configure the config file..
	echo " {*} Replacing text in config..."	
	sudo sed -i '2s/.*/server.port: 5601/' /etc/kibana/kibana.yml
	sudo sed -i '7s/.*/server.host: "localhost"/' /etc/kibana/kibana.yml 
	sudo sed -i '32s/.*/elasticsearch.hosts: ["http://localhost:9200"]/' /etc/kibana/kibana.yml 
	echo " {*} Configured."
	echo "---------------------------------"
}

getNginx () {				# This function is to install Nginx and to set it up.
	echo -e "\033[1m{*} Starting Nginx install process..."
	sudo apt install nginx apache2-utils -y
	echo -e "\033[1m{*} Nginx install process - Finished." 
	sleep 1
	echo ""
	echo -e "\033[1m{*} Making kibana destination file for nginx..."
	sudo touch /etc/nginx/sites-available kibana
	echo ""
	echo -e "\033[1m{*} File created."
	echo -e "\033[1m{*} Directory for file: /etc/nginx/sites-available"
	sleep 1

	echo ""
	echo -e "\033[1m{*} To avoid possible issues please input a new host name. "
	read -p 'Hostname: ' hostnamevar
	echo -e "\033[1m{*} Thank you, new hostname: $hostnamevar"
	echo ""
	echo -e "\033[1m{*} Changing machines hostname..."
	sudo echo $hostnamevar > /etc/hostname
	echo -e "\033[1m{*} Hostname change - Finish."
	echo -e "\033[1m{*} Adding hostname to system..."
	usrlocip=$(hostname -i)
	sudo echo "$userlocip	$hostnamevar" >> /etc/hosts
	echo -e "\033[1m{*} Hostname has been added."
	
	echo ""
	echo -e "\033[1m{*} Configuring the config for nginx..."                										# Start of configuring nginx file at /etc/nginx/sites-available/kibana
	echo "server {" > /etc/nginx/sites-available/kibana
	echo "	listen 80;" >> /etc/nginx/sites-available/kibana
	echo "" >> /etc/nginx/sites-available/kibana 
	echo "	server_name "$hostnamevar";" 
	echo "" >> /etc/nginx/sites-available/kibana
	echo "	auth_basic \"Restricted Access\";" >> /etc/nginx/sites-available/kibana
	echo "	auth_basic_user_file /etc/nginx/.kibana-user;" >> /etc/nginx/sites-available/kibana
	echo "" >> /etc/nginx/sites-available/kibana
	echo "	location / {" >> /etc/nginx/sites-available/kibana
	echo "		proxy_pass http://localhost:5601;" >> /etc/nginx/sites-available/kibana
	echo "		proxy_http_version 1.1;" >> /etc/nginx/sites-available/kibana
	echo "		proxy_set_header Upgrade \$http_upgrade;" 
	echo "		proxy_set_header Connection 'upgrade';" >> /etc/nginx/sites-available/kibana
	echo "		proxy_set_header Host \$host;" 
	echo "		proxy_cache_bypass \$http_upgrade;" 
	echo "	}" >> /etc/nginx/sites-available/kibana
	echo "}" >> /etc/nginx/sites-available/kibana
	echo -e "\033[1m{*} Done configuring."																		# End of configuring nginx file at /etc/nginx/sites-available/kibana

	echo ""
	echo -e "\033[1m{*} Setting up user account with htpasswd apache command..."
	read -p ' {*} Please enter username: ' usrvar
	echo " {*} Thank you, proceeding..."
	sudo htpasswd -c /etc/nginx/.kibana-user $usrvar
	echo ""
	echo -e "\033[1m{*} Setting up user - Finished."
	echo " {*} Was made at: /etc/nginx/.kibana-user"
	sleep 1

	echo -e "\033[1m{*} Setting up link to Kibana config..." 														# The config will be located at /etc/nginx/sites-available directory.
	sleep 1
	ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/
	echo -e "\033[1m{*} Link has been made..."
	echo " {*} Checking if it was made successfully..."
	nginx -t
	if [ $? -ne 0 ]; then
		echo -e "\033[1m{*} Did not make successfully, check kibana config in "sites-available" directory."
	else echo -e "\033[1m{*} Setting up Kibana link - Finished."
	fi
	echo "---------------------------------"
}

getLogstash () {				# This function is to download Logstash
	echo ""
	echo -e "\033[1m{*} Starting logstash install process..."
	echo " {*} Checking for updates..."
	sudo apt update -y
	echo " {*} Completed updated check."
	echo ""
	echo -e "\033[1m{*} Installing logstash..."
	sleep 1
	sudo apt-get install logstash -y
	if [ $? -ne 0 ]; then
		echo " {*} Error downloading logstash."
	else echo " {*} Logstash install process - Finished."
	fi
	echo "---------------------------------"
}

startServ () {				# This function will start all of the services that the ELK stack needs
	echo "" 
	echo -e "\033[1m{*} Enabling Services for start on boot."
	echo " {*} Starting Elastic, Kibana, Nginx, Logstash Services..."
	sudo /bin/systemctl -q daemon-reload
	sudo /bin/systemctl -q enable elasticsearch
	sudo /bin/systemctl -q enable kibana
	sudo /bin/systemctl -q enable nginx
	sudo /bin/systemctl -q enable logstash
	sudo /bin/systemctl -q start elasticsearch
	sudo /bin/systemctl -q start kibana
	sudo /bin/systemctl -q start nginx
	sudo /bin/systemctl -q start logstash
	echo " {*} All Services started."
	echo "---------------------------------"
}

checkServ () {				# This function will check the status of the services that the ELK stack uses
	echo ""
	echo -e "\033[1m{*} Started and enabled the Services."
	echo ""
	echo -e "\033[1m{*} Checking Service status: "

	/bin/systemctl is-active -q elasticsearch && echo " {*} Elasticsearch is running woo! Better go catch it!" || echo " {*} Elasticsearch is not running... aww."
	/bin/systemctl is-active -q kibana && echo " {*} Kibana is running woo! Better go catch it!" || echo " {*} Kibana is not running... aww."
	/bin/systemctl is-active -q nginx && echo " {*} Nginx is running woo! Better go catch it!" || echo " {*} Nginx is not running... aww."
	/bin/systemctl is-active -q logstash && echo " {*} Logstash is running woo! Better go catch it!" || echo " {*} Logstash is not running...aww."

	echo ""
	echo -e "\033[1m{*} Checking Service status - Finished."
	echo "---------------------------------"
}

while true; do
	sleep 5
	clear
	echo ""
	echo "  .-------------------------------------------------------------------------------. "   # Made By Jared Kell	
        echo " | .-----------------------------------------------------------------------------. |"   # 9/3/2021
	echo " | |                                                                 		 | |"
	echo " | |    _____ __    _____    _____ _____ _____ _____ _____ _____ _____ 	 	 | |"
	echo " | |   |   __|  |  |  |  |  |   __|  _  |  |  |     |     |  |  | __  |		 | |"
	echo " | |   |   __|  |__|    -|  |__   |     |  |  |-   -|  |  |  |  |    -|		 | |"
	echo " | |   |_____|_____|__|__|  |_____|__|__|\___/|_____|_____|_____|__|__|		 | |"
        echo " | |                                                    			 | |"
	echo " | |										 | |"
        echo " | |                                                                             | |"    
	echo " | | {*} $(date)                                         | |"
	echo " | | {*} Starting the ELKsavior process.           	                         | |"
	echo " | | {*} This should work on most Debian-based Systems				 | |"
	echo " | | {*} This will install ELasticsearch - Kibana - Nginx - Logstash             | |"
	echo " | |             								 | |"
	echo " | '-----------------------------------------------------------------------------' |"
	echo "  '-------------------------------------------------------------------------------'"
	echo ""
	PS3="Please select one of the following: "

	choices=("Update System" "Install Java" "Install Kibana" "Install Nginx" "Install Logstash" "Start Services" "Check Services" "Quit")
	select usrchoice in "${choices[@]}"; do

		case $usrchoice in
			"Update System")
				updateSys
				break;;
			"Install Java")
				getJava
				break;;
			"Install Kibana")
				getKib
				break;;
			"Install Nginx")
				getNginx
				break;;
			"Install Logstash")
				getLogstash
				break;;
			"Start Services")
				startServ
				break;;
			"Check Services")
				checkServ
				break;;
			"Quit")
				echo "Exiting due to user request."
				exit
				;;
			*)
				echo "Please enter a valid option: $REPLY";;
		esac
	done
done
