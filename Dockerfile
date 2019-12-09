FROM centos:7

ARG YQ_VERSION=2.4.0
ARG JQ_VERSION=1.6
ARG STERN_VERSION=1.10.0
ARG KUBECTL_VERSION=1.15.0
ARG OC_VERSION=4.2.9
ARG GRAALVM_VERSION=19.2.1
ARG MAVEN_VERSION=3.6.1
ARG QUARKUS_VERSION=1.0.1.Final
ARG YUM_DEPENDENCIES="libxcrypt-compat gcc zlib-devel openssl-devel git httpie buildah podman"
ARG QUARKUS_EXTENSIONS="resteasy-jsonb,hibernate-orm-panache,mariadb,swagger-ui,openapi,reactive-messaging-kafka,reactive-messaging-amqp,kafka-client,kafka-streams,vertx,reactive-streams-operators,health,metrics,smallrye-opentracing,camel-quarkus-core"

ENV MAVEN_HOME=/opt/maven
ENV JAVA_HOME /opt/graalvm-ce
ENV GRAALVM_HOME /opt/graalvm-ce
ENV PATH $PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin

RUN yum update -y -q && yum install -y -q $YUM_DEPENDENCIES && yum clean all

RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -o /usr/local/bin/yq && chmod ugo+x /usr/local/bin/yq

RUN curl -fsSL https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -o /usr/local/bin/jq && chmod ugo+x /usr/local/bin/jq

RUN curl -fsSL https://github.com/wercker/stern/releases/download/${STERN_VERSION}/stern_linux_amd64 -o /usr/local/bin/stern && chmod ugo+x /usr/local/bin/stern

RUN curl -fsSL https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && chmod ugo+x /usr/local/bin/kubectl

RUN curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz | tar xzf - -C /usr/local/bin oc && chmod ugo+x /usr/local/bin/oc

RUN mkdir -p /opt/maven && curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar -xzf - --strip-components=1 -C /opt/maven

RUN mkdir -p /opt/graalvm-ce && curl -fsSL https://github.com/oracle/graal/releases/download/vm-$GRAALVM_VERSION/graalvm-ce-linux-amd64-$GRAALVM_VERSION.tar.gz | tar -xzf - --strip-components=1 -C /opt/graalvm-ce && /opt/graalvm-ce/bin/gu install native-image

WORKDIR /tmp

RUN mvn -q io.quarkus:quarkus-maven-plugin:$QUARKUS_VERSION:create -DclassName=com.redhat.developers.HelloResource -Dextensions=$QUARKUS_EXTENSIONS -B && cd my-quarkus-project && mvn -q clean package && cd .. && rm -fR my-quarkus-project

RUN mvn -q io.quarkus:quarkus-maven-plugin:$QUARKUS_VERSION:create -DclassName=com.redhat.developers.HelloResource -B && cd my-quarkus-project && mvn -q package -Pnative -DskipTests && cd .. && rm -fR my-quarkus-project

RUN rm -f /root/anaconda-ks.cfg

EXPOSE 8080

ADD docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
