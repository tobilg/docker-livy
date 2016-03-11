FROM ubuntu:14.04
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
ENV MESOS_BUILD_VERSION 0.27.1-2.0.226

# Set install path for Livy
ENV LIVY_APP_PATH /apps/livy

# Set Hadoop config directory
ENV HADOOP_CONF_DIR /etc/hadoop/conf

# Set Spark home directory
ENV SPARK_HOME /usr/local/spark

# Set native Mesos library path
ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so

# Mesos install
RUN wget http://downloads.mesosphere.io/master/ubuntu/14.04/mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
    dpkg -i mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb && \
    rm mesos_$MESOS_BUILD_VERSION.ubuntu1404_amd64.deb

# Spark ENV vars
ENV SPARK_VERSION_STRING spark-$SPARK_VERSION-bin-hadoop2.6
ENV SPARK_DOWNLOAD_URL http://d3kbcqa49mib13.cloudfront.net/$SPARK_VERSION_STRING.tgz

# Download and unzip Spark
RUN wget $SPARK_DOWNLOAD_URL && \
    mkdir -p $SPARK_HOME && \
    tar xvf $SPARK_VERSION_STRING.tgz -C /tmp && \
    cp -rf /tmp/$SPARK_VERSION_STRING/* $SPARK_HOME && \
    rm -rf -- /tmp/$SPARK_VERSION_STRING && \
    rm spark-$SPARK_VERSION-bin-hadoop2.6.tgz

# Clone Livy repository
RUN mkdir -p /apps && \
    cd /apps && \
	git clone https://github.com/cloudera/livy.git && \
	cd $LIVY_APP_PATH && \
    mvn -DskipTests -Dspark.version=$SPARK_VERSION clean package && \
	mkdir -p $LIVY_APP_PATH/upload
	
# Add custom files, set permissions
ADD entrypoint.sh .

# Remove config defaults
RUN rm $LIVY_APP_PATH/conf/livy-defaults.conf.template

COPY spark-user-configurable-options.conf $LIVY_APP_PATH/conf
COPY livy-defaults.conf $LIVY_APP_PATH/conf

RUN chmod +x entrypoint.sh

# Expose port
EXPOSE 8998

ENTRYPOINT ["/entrypoint.sh"]