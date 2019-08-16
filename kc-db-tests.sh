container_name=mssql2019
IP_ADDR=$(sudo podman inspect --format '{{ .NetworkSettings.IPAddress }}' ${container_name})
driver_postgres=org.postgresql.Driver
driver_mssql2019=com.microsoft.sqlserver.jdbc.SQLServerDriver
profile_postgres=db-mssql2017
profile_mssql2019=db-mssql2017

eval db_profile"="profile_"\$container_name"
eval db_driver"="driver_"\$container_name"

mvn clean install -f testsuite/integration-arquillian/pom.xml -Pjpa,auth-server-wildfly,${!db_profile} \
-Dtest=WelcomePageTest \
-Darquillian.debug=true -Dsurefire.timeout=0 \
-DXmaven.surefire.debug=true \
-DXauth.server.debug.port=8787 \
-DXauth.server.debug.suspend=y \
-Dkeycloak.connectionsJpa.driver=${!db_driver} \
-Dauth.server.db.host=${IP_ADDR} \
-Ddocker.database.skip=true
