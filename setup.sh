# Sets up 3 containers for apache guacamole
# This includes guacd, guacamole, and mariadb

# Pull docker images
docker pull guacamole/guacd
docker pull guacamole/guacamole
docker pull mysql

# Run guacamole
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql  initdb.sql
mkdir /tmp/scripts
cp initdb.sql /tmp/scripts

# Run guacd container
docker run --name guac-mysql -v /tmp/scripts:/tmp/scripts -v mysql_volume:/var/lib/mysql -e MYSQL_ROOT_PASSWORD='sqlpassword' -d mysql:latest

# Create the mariaDB database and columns
mysql -u root -p
 CREATE DATABASE guacamole;
 CREATE USER 'guacamole' IDENTIFIED BY 'sqlpassword';
 GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole.* TO 'guacamole';
 FLUSH PRIVILEGES;
 quit

# enter bash in guacamole container
docker exec -it guacamole /bin/bash
cat /tmp/scripts/initdb.sql | mysql -u root -p guacamole;

# Run the final container
docker run --name guacamole --link guacd:guacd --link guac-mysql:mysql \
-e MYSQL_DATABASE='guacamole' \
-e MYSQL_USER='guacamole' \
-e MYSQL_PASSWORD='sqlpassword' \
-d -p 8080:8080 guacamole/guacamole

# Tomcat hardening
sed -i 's/redirectPort="8443"/redirectPort="8443" server="" secure="true"/g' /usr/local/tomcat/conf/server.xml
sed -i 's/Server port="8005" shutdown="SHUTDOWN"/Server port="-1" shutdown="SHUTDOWN"/g' /usr/local/tomcat/conf/server.xml
rm -Rf /usr/local/tomcat/webapps/docs/
rm -Rf /usr/local/tomcat/webapps/examples/
rm -Rf /usr/local/tomcat/webapps/manager/
rm -Rf /usr/local/tomcat/webapps/host-manager/
chmod -R 400 /usr/local/tomcat/conf
