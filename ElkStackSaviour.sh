#!/bin/bash

#Colors
normal=$"\e[0m"
green=$"\e[32m"
orange=$"\e[33m"
lightgreen=$"\e[92m"
lightaqua=$"\e[96m"
gray=$"\e[37m"

updateSys () {				# This is a function to update and upgrade your system.
	echo -e "$lightaqua{*} Starting system update process...$gray"
	sudo apt update -y && sudo apt upgrade -y
	echo -e "$orange{*} System update process -$green Finished. $normal"
	echo "---------------------------------"
}

getJava () {				# This is a function to install Java
	echo -e "$lightaqua{*} Starting Java 8 install process...$gray"
	sudo apt install openjdk-11-jre-headless -y
	echo -e "$orange{*} Java  8 install process -$green Finished. $normal"
	echo "---------------------------------"
}

getElastic () {				# This is a function to install and setup Elastic
	echo -e "$lightaqua{*} Starting Elasticsearch install process...$gray"
	sleep 1 
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - 
	sudo apt-get install apt-transport-https
	echo -e "$lightaqua{*} ... adding repository ...$gray"
	sleep 1
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
	echo -e "$lightaqua{*} ... checking for updates ...$gray"
	sleep 1
	sudo apt update -y
	echo -e "$lightaqua{*} ... installing elasticsearch ...$gray"
	sleep 1
	sudo apt install elasticsearch -y
	echo ""
	echo " ------------------------------------------------------"
	echo -e "$orange{*} Elasticsearch install process -$green Finished. $normal"
	echo "{*} Directory for the config file: /etc/elasticsearch "
	echo "{*} Config file name: elasticsearch.yml"
	echo " ------------------------------------------------------"
	sleep 1
	echo -e "$lightaqua{*} Configuring config with recommended settings.$gray"				# The following should configure the config.
	echo "{*} Replacing text in config..."	
	sudo sed -i '56s/.*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
	sudo sed -i '61s/.*/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
	echo -e "$lightaqua{*} Replaced. $normal"
	echo "---------------------------------"
}

getKib () {
	echo -e "$lightaqua{*} Starting Kibana install process...$gray"
	sleep 1
	sudo apt install kibana -y
	echo ""
	echo "-------------------------------------------------"
	echo -e "$orange{*} Kibina install process -$green Finished. $normal"
	echo "{*} Directory for config: /etc/kibana"
	echo "{*} Confige file name: kibana.yml"
	echo "-------------------------------------------"
	sleep 1
	echo -e "$lightaqua{*} Configuring config with recommended settings.$gray"				# This will configure the config file..
	echo "{*} Replacing text in config..."	
	sudo sed -i '2s/.*/server.port: 5601/' /etc/kibana/kibana.yml
	sudo sed -i '7s/.*/server.host: "localhost"/' /etc/kibana/kibana.yml 
	sudo sed -i '32s/.*/elasticsearch.hosts: ["http://localhost:9200"]/' /etc/kibana/kibana.yml 
	echo -e "$lightaqua{*} Configured. $normal"
	echo "---------------------------------"
}

getNginx () {				# This function is to install Nginx and to set it up.
	echo -e "$lightaqua{*} Starting Nginx install process...$gray"
	sudo apt install nginx apache2-utils -y
	echo -e "$orange{*} Nginx install process -$green Finished. $normal" 
	sleep 1
	echo ""
	echo -e "$lightaqua{*} Making kibana destination file for nginx...$gray"
	sudo touch /etc/nginx/sites-available kibana
	echo ""
	echo -e "$gray File created."
	echo -e "$gray Directory for file: $green/etc/nginx/sites-available $normal"
	sleep 1

	echo ""
	echo -e "$lightaqua{*} To avoid possible issues please input a new host name. $gray"
	read -p 'Hostname: ' hostnamevar
	echo -e "$lightaqua{*} Thank you, new hostname: $hostnamevar"
	echo ""
	echo -e "$lightaqua{*} Changing machines hostname...$gray"
	sudo echo $hostnamevar > /etc/hostname
	echo -e "$orange Hostname change -$green Finish. $normal"
	echo -e "$lightaqua{*} Adding hostname to system...$gray"
	usrlocip=$(hostname -i)
	sudo echo "$userlocip	$hostnamevar" >> /etc/hosts
	echo -e "$lightaqua{*} Hostname has been added.$normal"
	
	echo ""
	echo -e "$lightaqua{*} Configuring the config for nginx...$normal"                										# Start of configuring nginx file at /etc/nginx/sites-available/kibana
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
	echo -e "$lightaqua{*} Done configuring.$normal"																		# End of configuring nginx file at /etc/nginx/sites-available/kibana

	echo ""
	echo -e "$lightaqua{*} Setting up user account with htpasswd apache command...$orange"
	read -p '{*} Please enter username: ' usrvar
	echo -e "$lightaqua{*} Thank you, proceeding...$gray"
	sudo htpasswd -c /etc/nginx/.kibana-user $usrvar
	echo ""
	echo -e "$orange{*} Setting up user -$green Finished.$normal"
	echo -e "$orange{*} Was made at: /etc/nginx/.kibana-user"
	sleep 1

	echo -e "$lightaqua{*} Setting up link to Kibana config...$gray" 														# The config will be located at /etc/nginx/sites-available directory.
	sleep 1
	ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/
	echo -e "$orange{*} Link has been made...$gray"
	echo -e "$orange{*} Checking if it was made successfully...$gray"
	nginx -t
	if [ $? -ne 0 ]; then
		echo -e "$lightaqua{*} Did not make successfully, check kibana config in "sites-available" directory.$normal"
	else echo -e "$orange{*} Setting up Kibana link -$green Finished.$normal"
	fi
	echo "---------------------------------"
}

getLogstash () {				# This function is to download Logstash
	echo ""
	echo -e "$lightaqua{*} Starting logstash install process...$gray"
	echo "{*} Checking for updates..."
	sudo apt update -y
	echo -e "$lightaqua{*} Completed updated check."
	echo ""
	echo -e "$lightaqua{*} Installing logstash...$gray"
	sleep 1
	sudo apt-get install logstash -y
	if [ $? -ne 0 ]; then
		echo -e "$lightaqua{*} Error downloading logstash."
	else echo -e "$orange{*} Logstash install process -$green Finished.$normal"
	fi
	echo "---------------------------------"
}

startServ () {				# This function will start all of the services that the ELK stack needs
	echo "" 
	echo -e "$lightaqua{*} Enabling Services for start on boot.$gray"
	echo "{*} Starting Elastic, Kibana, Nginx, Logstash Services..."
	sudo /bin/systemctl -q daemon-reload
	sudo /bin/systemctl -q enable elasticsearch
	sudo /bin/systemctl -q enable kibana
	sudo /bin/systemctl -q enable nginx
	sudo /bin/systemctl -q enable logstash
	sudo /bin/systemctl -q start elasticsearch
	sudo /bin/systemctl -q start kibana
	sudo /bin/systemctl -q start nginx
	sudo /bin/systemctl -q start logstash
	echo -e "$orange{*} All Services started.$normal"
	echo "---------------------------------"
}

checkServ () {				# This function will check the status of the services that the ELK stack uses
	echo ""
	echo -e "$lightaqua{*} Checking Service status: $gray"

	/bin/systemctl is-active -q elasticsearch && echo " {*} Elasticsearch is running woo! Better go catch it!" || echo " {*} Elasticsearch is not running... aww."
	/bin/systemctl is-active -q kibana && echo " {*} Kibana is running woo! Better go catch it!" || echo " {*} Kibana is not running... aww."
	/bin/systemctl is-active -q nginx && echo " {*} Nginx is running woo! Better go catch it!" || echo " {*} Nginx is not running... aww."
	/bin/systemctl is-active -q logstash && echo " {*} Logstash is running woo! Better go catch it!" || echo " {*} Logstash is not running...aww."

	echo ""
	echo -e "$orange{*} Checking Service status -$green Finished.$normal"
	echo "---------------------------------"
}

while true; do
	sleep 2
	clear
	echo -e "$lightgreen"
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
	echo " | | {*} $(date)                                           | |"
	echo " | | {*} Starting the ELKsavior process.           	                         | |"
	echo " | | {*} This should work on most Debian-based Systems				 | |"
	echo " | | {*} This will install ELasticsearch - Kibana - Nginx - Logstash             | |"
	echo " | |             								 | |"
	echo " | '-----------------------------------------------------------------------------' |"
	echo "  '-------------------------------------------------------------------------------'"
	echo -e "$normal$gray"
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
