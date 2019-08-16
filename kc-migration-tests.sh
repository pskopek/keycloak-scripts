#!/bin/bash

while getopts ":d:" opt; do
	case $opt in
    		d)
			# possible container names: mysql|postgres|mssql2017|mariadb
			container_name=$OPTARG
			if [[ "$container_name" =~ ^(mysql|postgres|mssql2017|mariadb|mariadb101)$ ]]; then
    				echo "Using database $container_name"
			else
			    	echo "Unsupported container $container_name"
				exit 1
			fi
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;	
	esac
done

if [ ${container_name}x != x ] ; then
IP_ADDR=$(sudo podman inspect --format '{{ .NetworkSettings.IPAddress }}' mariadb)
#IP_ADDR=$(sudo podman inspect --format '{{ .NetworkSettings.IPAddress }}' ${container_name})
driver_postgres=org.postgresql.Driver
driver_mysql=com.mysql.cj.jdbc.Driver
driver_mariadb=org.mariadb.jdbc.Driver
driver_mariadb101=org.mariadb.jdbc.Driver
driver_mssql2017=com.microsoft.sqlserver.jdbc.SQLServerDriver
profile_postgres=db-postgres
profile_mssql2017=db-mssql2017
profile_mariadb=db-mariadb
profile_mariadb101=db-mariadb
profile_mysql=db-mysql

eval db_profile"="profile_"\$container_name"
eval db_driver"="driver_"\$container_name"

if [ ${container_name} == "mariadb101" ]; then

	# container init
	sudo podman stop mariadb
	sudo podman rm mariadb
	sudo podman run --name mariadb --publish 3306:3306 --env MARIADB_ROOT_PASSWORD=keycloak --env MARIADB_DATABASE=keycloak --env MARIADB_USER=keycloak --env MARIADB_PASSWORD=keycloak --detach mariadb/server:10.1
	IP_ADDR=$(sudo podman inspect --format '{{ .NetworkSettings.IPAddress }}' mariadb)

mvn -f testsuite/integration-arquillian/pom.xml clean install -Pjpa,auth-server-wildfly,db-mariadb,auth-server-migration -Dsurefire.memory.Xms=512m -Dsurefire.memory.Xmx=1536m -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn -Dtest=MigrationTest -Dmigration.mode=manual -Dmigrated.auth.server.version=4.8.3.Final -Dprevious.product.unpacked.folder.name=keycloak-4.8.3.Final -Dmigration.import.file.name=migration-realm-4.8.3.Final.json -Dauth.server.ssl.required=false \
-Dmaven.test.failure.ignore=false \
-Djdbc.mvn.version.legacy=2.0.3 \
-Djdbc.mvn.groupId=org.mariadb.jdbc \
-Djdbc.mvn.artifactId=mariadb-java-client \
-Djdbc.mvn.version=2.2.4 \
-Djs.browser=chrome -Dwebdriver.chrome.driver=/usr/local/bin/chromedriver -DdroneInstantiationTimeoutInSeconds=240 \
-Ddocker.database.skip=true \
-Dauth.server.db.host=${IP_ADDR:-localhost} \
-Dkeycloak.connectionsJpa.url=jdbc:mysql://${IP_ADDR:-localhost}:3306/keycloak \
-Dkeycloak.connectionsJpa.driver=${!db_driver} \
-Dkeycloak.connectionsJpa.user=keycloak \
-Dkeycloak.connectionsJpa.password=keycloak
else
mvn clean install -f testsuite/integration-arquillian/pom.xml \
-Pjpa,clean-jpa,auth-server-migration,test-73-migration,migration-manual \
-Dtest=MigrationTest \
-Darquillian.debug=true \
-Dsurefire.timeout=0 \
-DXmaven.surefire.debug=true \
-DXauth.server.debug.port=8787 \
-DXauth.server.debug.suspend=y \
-DXauth.server.db.host=${IP_ADDR:-localhost} \
-DXdocker.database.skip=true \
-Dmigration.mode=auto \
-Djdbc.mvn.groupId=mysql \
-Djdbc.mvn.artifactId=mysql-connector-java \
-Djdbc.mvn.version=8.0.12 \
-Djdbc.mvn.version.legacy=5.1.38 \
-Dkeycloak.connectionsJpa.url=jdbc:mysql://${IP_ADDR:-localhost}:3306/keycloak \
-Dkeycloak.connectionsJpa.driver=${!db_driver} \
-Dkeycloak.connectionsJpa.user=keycloak \
-Dkeycloak.connectionsJpa.password=keycloak
fi
else
	echo "Just DB tests for now"
fi

