FROM centos:7

ARG GRAALVM_VERSION=19.1.0
ARG MAVEN_VERSION=3.6.1
ARG QUARKUS_VERSION=0.19.0

ENV MAVEN_HOME=/opt/maven
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0
ENV GRAALVM_HOME /opt/graalvm-ce
ENV PATH $PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin

RUN yum update -y && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel libxcrypt-compat gcc zlib-devel && yum clean all
RUN mkdir -p /opt/maven && curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzf - --strip-components=1 -C /opt/maven
RUN mkdir -p /opt/graalvm-ce && curl -fsSL https://github.com/oracle/graal/releases/download/vm-$GRAALVM_VERSION/graalvm-ce-linux-amd64-$GRAALVM_VERSION.tar.gz | tar -xzf - --strip-components=1 -C /opt/graalvm-ce && /opt/graalvm-ce/bin/gu install native-image

WORKDIR /root

RUN mvn -q io.quarkus:quarkus-maven-plugin:$QUARKUS_VERSION:create -DclassName=com.redhat.developers.HelloResource -Dextensions=resteasy-jsonb,panache,mariadb,swagger-ui,openapi,reactive-messaging-kafka,reactive-messaging-amqp,kafka-client,kafka-streams,vertx,reactive-streams-operators,health,metrics,opentracing,camel-core -B && cd my-quarkus-project && mvn -q clean package && cd .. && rm -fR my-quarkus-project

RUN mvn -q io.quarkus:quarkus-maven-plugin:$QUARKUS_VERSION:create -DclassName=com.redhat.developers.HelloResource -B && cd my-quarkus-project && mvn -q package -Pnative && cd .. && rm -fR my-quarkus-project

RUN rm -f /root/anaconda-ks.cfg
