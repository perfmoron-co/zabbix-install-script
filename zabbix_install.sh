# error checking always needs improving


#Adapted from script found online
#CHANGES by Vipul Kane:
#enhanced to support Ubuntu 14.10
#enhanced
#server or agent install
#added some error checking
####################################################


#Set Default script variables here before running
DATABASE="mysql" # option ONLY mysql at present
IPv6=true # options true or false
VERSION="2.4.7"
DB_USER="zabbix"
DB_PASS="zabb1x"
DB_HOST="localhost"
SERVER_IP="xxx.xxx.xxx.xxx" # IP of zabbix server for agents to communicate with.
SERVER_INSTALL=true # if false assumed to be agent only install


#echo "-----------------------------------------------------"
#echo "$DATABASE"
#echo "$IPv6"
#echo "$VERSION"
#echo "$DB_USER"
echo "$DB_PASS"
#echo "$DB_HOST"
#echo "$SERVER_IP"
#echo "$SERVER_INSTALL"
#echo "-----------------------------------------------------"


#====END of User Varables==================
IPv4_ADDR=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
MYSQL="$(which mysql)"
HOSTNAME=$(hostname -f)
clear


# Get Input from Users
echo "Capture User Options:"
echo "====================="
echo "Please answer the following questions."
echo "Hitting return will continue with the default option"
echo
echo
# Get_Server - Do they require a Server Install?
read -p "Install Zabbix Server? true/false [$SERVER_INSTALL]: " t1
if [ -n "$t1" ]
then
  SERVER_INSTALL="false"
  #Now we ASSUME that this is a Agent ONLY install
  # Get_Server_IP - What Version of Zabbix do they require?
  read -p "What is the Zabbix Server IP Address? [$SERVER_IP]: "  t1
  if [ -n "$t1" ]
  then
     SERVER_IP="$t1"
  else
     SERVER_IP="127.0.0.1"
  fi
  #====END Get_Server_IP
else
  SERVER_INSTALL="true"
fi
#====END Get_Server

# Get_Version - What Version of Zabbix do they require?
read -p "Which version? [$VERSION]: "  t1
if [ -n "$t1" ]
then
  VERSION="$t1"
else
  VERSION="2.4.7"
fi
#====END Get_Version
 
# Get_IPv6 - Do they require IPv6 support?
read -p "Is support for IPv6 required? true/false [$IPv6]: " t1
if [ -n "$t1" ]
then
  IPv6="false"
else
  IPv6="true"
fi
#====END Get_IPv6

# Step 1 ================================
# nothing to do for agent only installs
echo
echo "Installation Step 1 Started"

################
#updating system
################

apt-get -qq 
sleep 2
if [ $? -eq 0 ]; then
   echo "Step 1 completed successfully!"
else
   echo "Step 1 FAILED!"  
   exit
fi

# Step 2 ================================

if $SERVER_INSTALL ; then
   #################################################
   #install requirements and dependencies
   #################################################
   echo
   echo "Installation Step 2 Started"

   if ! dpkg-query -W fping; then apt-get install -qq -y fping; sleep 2; fi
   if ! dpkg-query -W apache2; then apt-get install -qq -y apache2; sleep 2; fi
   if ! dpkg-query -W php5; then apt-get install -qq -y php5; sleep 2; fi
   if ! dpkg-query -W php5-gd; then apt-get install -qq -y php5-gd;  sleep 2; fi
   #### May have to install Manually
   if ! dpkg-query -W libsnmp-dev; then apt-get install -qq -y libsnmp-dev;  sleep 2; fi
   if ! dpkg-query -W libcurl4-openssl-dev; then apt-get install -qq -y libcurl4-openssl-dev; sleep 2; fi
   if ! dpkg-query -W libapache2-mod-php5; then apt-get install -qq -y libapache2-mod-php5; sleep 2; fi
   if ! dpkg-query -W libiksemel-dev; then apt-get install -qq -y libiksemel-dev;  sleep 2; fi
   if ! dpkg-query -W libssh2-1-dev; then apt-get install -qq -y libssh2-1-dev; sleep 2; fi
   if ! dpkg-query -W libopenipmi-dev; then apt-get install -qq -y libopenipmi-dev;  sleep 2; fi
   if ! dpkg-query -W libmysqlclient-dev; then apt-get install -qq -y libmysqlclient-dev; sleep 2; fi
   if ! dpkg-query -W mysql-server; then apt-get install -qq -y mysql-server; sleep 2; fi
   if ! dpkg-query -W libapache2-mod-auth-mysql; then apt-get install -qq -y libapache2-mod-auth-mysql; sleep 2; fi
   if ! dpkg-query -W php5-mysql; then apt-get install -qq -y php5-mysql;  sleep 2;  fi
   #### May have to manually install
   if ! dpkg-query -W libmysqld-dev; then apt-get install -qq -y php5-mysql; sleep 2; fi
fi

if ! dpkg-query -W build-essential; then apt-get install -qq -y build-essential; sleep 2; fi

echo "Step 2 completed successfully!"

# Step 3 ================================

#######################
#Initial Database setup
#######################
echo
echo "Installation Step 3 Started"

# create zabbix system user
adduser zabbix -no-create-home -system -group -disabled-password -shell /bin/false -quiet
if [ $? -eq 0 ]; then
   echo "   User zabbix created"
else
   echo "   FAILED to create User zabbix"
   exit 1
fi

DATABASE="mysql"
echo "database :$DATABASE"

if $SERVER_INSTALL ; then

echo '**********Test1***************'
   if [ $DATABASE == "mysql" ]; then
      echo -n "   Input the MySQL admin user name: "
      read MySQLADMIN

      echo -n "   Input the MySQL root admin user password: "
      read MySQLADMINPASS

      $DATABASE -u$MySQLADMIN -p$MySQLADMINPASS -Bse 'CREATE DATABASE zabbix;'
      $DATABASE -u$MySQLADMIN -p$MySQLADMINPASS zabbix -Bse "GRANT ALL ON zabbix.* TO zabbix@localhost;"
      echo "   mysql database and user created"
    
   else
     
      echo "postgresql initial DB setup"
      #postgresql initial DB setup

      echo -n "Input the postgre USERNAME for this database: "
      read e DB_USER

      echo -n "Input the MySQL ADMIN user password: "
      read e MySQLADMINPASS

   fi

   echo "Step 3 completed successfully!"
fi



# Step 4 ================================
################
#Zabbix download
################
echo
echo "Installation Step 4 Started"

cd /tmp/

DIRECTORY=/tmp/install
if [ ! -d "$DIRECTORY" ]; then
    mkdir /tmp/install
fi

cd /tmp/install
echo " temporary install directory created"
echo " downloading zabbix source from: http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$VERSION/zabbix-$VERSION.tar.gz"
#VERSION="2.0.5"

if ! [ -e "zabbix-$VERSION.tar.gz" ]
then
  #wget -nv http://prdownloads.sourceforge.net/zabbix/zabbix-$VERSION.tar.gz
  wget -nv http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/$VERSION/zabbix-$VERSION.tar.gz?r=&ts=1448232400&use_mirror=iweb
  echo "   downloaded zabbix source"
else
  echo "   zabbix source of correct version already exists"
fi

echo " untar zabbix source"
tar zxf zabbix-$VERSION.tar.gz

echo " prepare directory and file permissions"
chmod -R 777 /tmp/install/*
cd /tmp/install/zabbix-$VERSION
chmod +x ./configure

if $SERVER_INSTALL ; then
   # DB integration
   echo " load mysql with provided schemas"
   
   #For Older Zabbix Versions than 2.0, Schemas lie elsewhere please change the directory
   cd /tmp/install/zabbix-$VERSION/database/mysql
  
	 if [ -n  $MySQLADMIN]
  	 then
		MySQLADMIN="root"
		MySQLADMINPASS="Password99"
 	 fi

   cat schema.sql | mysql -u$MySQLADMIN -p$MySQLADMINPASS zabbix
   cat images.sql | mysql -u$MySQLADMIN -p$MySQLADMINPASS zabbix
   cat data.sql | mysql -u$MySQLADMIN -p$MySQLADMINPASS zabbix
fi

echo " prepare compile build options"
if $SERVER_INSTALL ; then
   #Server DB and other build options
   build_opts=" -prefix=/usr -mandir=\${prefix}/share/man -infodir=\${prefix}/share/info "

   if $IPv6 ; then
      build_opts=" -enable-ipv6 $build_opts"
   fi

   # —with-mysql
   build_opts=" -with-mysql $build_opts"

   cd /tmp/install/zabbix-$VERSION
   echo "Using configure set like this: "
   sleep 1
   
   echo "configure -quiet -enable-server -with-net-snmp -with-libcurl -with-openipmi -with-jabber -with-ssh2 -enable-agent $build_opts"

   #echo ""
   #./configure -quiet -enable-server -with-net-snmp -with-libcurl -with-openipmi -with-jabber -with-ssh2 -enable-agent $build_opts
   echo ""
   ./configure -quiet -enable-server -with-net-snmp -with-libcurl -with-openipmi -with-ssh2 -enable-agent $build_opts
else
   #Agents only build options
   build_opts=" -prefix=/usr -mandir=\${prefix}/share/man -infodir=\${prefix}/share/info "

   if $IPv6 ; then
      build_opts=" -enable-ipv6 $build_opts"
   fi
   cd /tmp/install/zabbix-$VERSION
   echo "Using configure set like this: "
   echo "configure -quiet -enable-agent $build_opts"

   echo ""
   ./configure -quiet -enable-agent $build_opts

fi


echo "   Ready to compile"
cd /tmp/install/zabbix-$VERSION

make -s install
if [ $? -eq 0 ]; then
   echo "Step 4 completed successfully!"
else
   echo "Step 4 Compile FAILED!"
   exit
fi

sleep 5

#step 5 for Server installations
if $SERVER_INSTALL ; then
   #############################
   #Zabbix $VERSION installation
   #FRONTEND installation
   #############################
   echo "Step 5 FRONTEND installation"

   sed -i.backup -e "s/post_max_size = 8M/post_max_size = 32M/g" /etc/php5/apache2/php.ini
   sed -i.backup -e "s/max_execution_time = 30/max_execution_time = 600/g" /etc/php5/apache2/php.ini
   sed -i.backup -e "s/max_input_time = 60/max_input_time = 600/g" /etc/php5/apache2/php.ini
   sed -i,backup -e '/date.timezon/a\date.timezone = "Pacific/Auckland"' /etc/php5/apache2/php.ini
   cd /tmp/install/zabbix-$VERSION/frontends/php
   echo "   Sleeping for 5 Seconds "
   sleep 5
   echo "   Make web directory"
   DIRECTORY=/var/www/html/zabbix
   if [ ! -d "$DIRECTORY" ]; then
      mkdir /var/www/html/zabbix
   fi
   echo "   Copy zabbix web frontend to web directory"
   cp -a . /var/www/html/zabbix
   echo "   Change the permissions to default apache2"
   chown www-data:www-data -R /var/www/html/zabbix


cat <<EOF > /etc/apache2/sites-available/zabbix
	
	<VirtualHost /zabbix>
        	ServerAdmin webmaster@localhost

        	DocumentRoot /var/www/html/zabbix
        	<Directory />
                	Options FollowSymLinks Indexes MultiViews
	                AllowOverride None
        	</Directory>
p
	</VirtualHost>
EOF

   echo "   Zabbix $VERSION installation"
fi

#step 5 for agents only they join here…

ln -s /usr/bin/fping /usr/sbin/fping
if $IPv6 ; then
   ln -s /usr/bin/fping6 /usr/sbin/fping6
fi

DIRECTORY=/etc/zabbix
if [ ! -d "$DIRECTORY" ]; then
   mkdir $DIRECTORY
fi

DIRECTORY=/var/log/zabbix
if [ ! -d "$DIRECTORY" ]; then
   mkdir $DIRECTORY
   chown zabbix:zabbix -R $DIRECTORY
   chmod 766 $DIRECTORY
fi

DIRECTORY=/var/run/zabbix
if [ ! -d "$DIRECTORY" ]; then
    mkdir $DIRECTORY
    chown zabbix:zabbix -R $DIRECTORY
    chmod 766 $DIRECTORY
fi

cp /tmp/install/zabbix-$VERSION/conf/zabbix_agentd.conf /etc/zabbix

#check for server install
echo "**** Checking for server instllation ****"
if $SERVER_INSTALL ; then
   cp /tmp/install/zabbix-$VERSION/conf/zabbix_server.conf /etc/zabbix
   sed -i.backup -e "s/DBUser=root/DBUser=$DB_USER/g" -e "s|/tmp/zabbix_server.log|/var/log/zabbix/zabbix_server.log|g" -e "s|# PidFile=/tmp/zabbix_server.pid|PidFile=/var/run/zabbix/zabbix_server.pid|g" /etc/zabbix/zabbix_server.conf
fi
sed -i.backup -e "s|/tmp/zabbix_agentd.log|/var/log/zabbix/zabbix_agentd.log|g" -e "s|# PidFile=/tmp/zabbix_agentd.pid|PidFile=/var/run/zabbix/zabbix_agentd.pid|g" /etc/zabbix/zabbix_agentd.conf

chown zabbix:zabbix -R /etc/zabbix

cp /tmp/install/zabbix-$VERSION/misc/init.d/debian/zabbix* /etc/init.d/

#check for server install
if $SERVER_INSTALL ; then
   sed -i.backup -e "s|/usr/local/sbin/|/usr/sbin/|" /etc/init.d/zabbix-server
   chmod 775 /etc/init.d/zabbix-server
   update-rc.d zabbix-server defaults
   echo "   Starting the zabbix server"
   /etc/init.d/zabbix-server start
   echo "   Restarting Apache for changes to take effect"
   /etc/init.d/apache2 restart
   sleep 5
   if [ "$(pidof zabbix_server)" ]
   then
      echo "Server Installation Complete!"
      echo "zabbix can be found at: "
      echo "http://$IPv4_ADDR/zabbix"
      echo "  Login:  admin"
      echo "  Passwd: zabbix"
   else
      echo "Installation FAILED!"
      echo "zabbix server process is NOT running."
      echo "Not sure what went wrong."
   fi
else
   sed -i.backup -e "s|/tmp/zabbix_agentd.log|/var/log/zabbix/zabbix_agentd.log|g" -e "s|# PidFile=/tmp/zabbix_agentd.pid|PidFile=/var/run/zabbix/zabbix_agentd.pid|g" -e "s|Server=127.0.0.1|Server=$SERVER_IP|g" -e "s|Hostname=Zabbix server|Hostname=$HOSTNAME|g" /etc/zabbix/zabbix_agentd.conf

fi

sed -i.backup -e "s|/usr/local/sbin/|/usr/sbin/|" /etc/init.d/zabbix-agent
chmod 775 /etc/init.d/zabbix-agent
update-rc.d zabbix-agent defaults
echo "   Starting the zabbix agent"
/etc/init.d/zabbix-agent start
sleep 5

if [ "$(pidof zabbix_agentd)" ]
   then
      #cleaning up
      rm -rf /tmp/install
      echo "Agent Installation Complete!"
   else
      echo "Agent Installation FAILED!"
      echo "zabbix agent process is NOT running."
      echo "Not sure what went wrong."
   fi

exit
