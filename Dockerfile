FROM ubuntu:14.04.3
MAINTAINER tobilg <fb.tools.github@gmail.com>

# Add R list
RUN echo 'deb http://cran.mirrors.hoobly.com/bin/linux/ubuntu vivid/' | sudo tee -a /etc/apt/sources.list.d/r.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

# packages
RUN apt-get update && apt-get install -yq --no-install-recommends --force-yes \
    wget \
    git \
    openjdk-7-jdk \
    maven \
    libjansi-java \
    libsvn1 \
    libcurl3 \
    libsasl2-modules && \
    rm -rf /var/lib/apt/lists/*

# Overall ENV vars
ENV SPARK_VERSION 1.6.0
ENV MESOS_BUILD_VERSION 0.25.0-0.2.70
ENV LIVY_APP_PATH /apps/livy

# Mesos install
RUN wget http://downloads.mesosphere.io/master/ubuntu/14.04/mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
    dpkg -i mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
    rm mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb

# Spark ENV vars
ENV SPARK_VERSION_STRING spark-$SPARK_VERSION-bin-hadoop2.6
ENV SPARK_DOWNLOAD_URL http://d3kbcqa49mib13.cloudfront.net/$SPARK_VERSION_STRING.tgz

# Download and unzip Spark
RUN wget $SPARK_DOWNLOAD_URL && \
    mkdir -p /usr/local/spark && \
    tar xvf $SPARK_VERSION_STRING.tgz -C /tmp && \
    cp -rf /tmp/$SPARK_VERSION_STRING/* /usr/local/spark/ && \
    rm -rf -- /tmp/$SPARK_VERSION_STRING && \
    rm spark-$SPARK_VERSION-bin-hadoop2.6.tgz

# Set SPARK_HOME
ENV SPARK_HOME /usr/local/spark

# Set native Mesos library path
ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so

# Clone Hue/Livy repository
RUN git clone https://github.com/cloudera/hue.git && \
    cd /hue/apps/spark/java && \
    mvn -DskipTests -Dspark.version=$SPARK_VERSION clean package && \
    mkdir -p $LIVY_APP_PATH && \
    cp -a /hue/apps/spark/java/. $LIVY_APP_PATH/ && \
    rm -rf /hue

# Add custom files, set permissions

ENV HADOOP_CONF_DIR /etc/hadoop/conf

EXPOSE 8998

ENTRYPOINT ["/apps/livy/bin/livy-server"]