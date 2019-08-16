set -o errexit
cd ~/dev/keycloak
mvn clean install -DskipTests
mvn clean install -f distribution/pom.xml
mvn clean install -f testsuite/integration-arquillian/servers/pom.xml
mvn clean install -f testsuite/integration-arquillian/test-apps/pom.xml

