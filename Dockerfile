FROM confluentinc/cp-kafka-connect:7.5.0

# Copy PostgreSQL driver to the Kafka Connect plugin directories
COPY lib/postgresql-42.7.5.jar /usr/share/java/kafka/
COPY lib/postgresql-42.7.5.jar /usr/share/java/kafka-connect-jdbc/
COPY lib/postgresql-42.7.5.jar /usr/share/java/
COPY lib/postgresql-42.7.5.jar /usr/share/java/cp-base-new/
COPY lib/postgresql-42.7.5.jar /etc/kafka-connect/jars/

# Register the driver
ENV CLASSPATH="/usr/share/java/kafka/postgresql-42.7.5.jar:/usr/share/java/kafka-connect-jdbc/postgresql-42.7.5.jar" 