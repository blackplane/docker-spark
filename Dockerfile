FROM debian:stretch
MAINTAINER Getty Images "https://github.com/gettyimages"

# Install system libraries first as root
USER root

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update \
 && apt-get install -y curl wget unzip procps \
    python3 python3-setuptools \
 && ln -s /usr/bin/python3 /usr/bin/python \
 && easy_install3 pip py4j \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin
RUN echo "$LOG_TAG Install java8" && \
    apt-get -y update && \
    apt-get install -y openjdk-8-jdk

# HADOOP
ENV HADOOP_VERSION 3.0.0
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.3.1
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_LOG_DIR /var/log/spark
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME \
 && mkdir $SPARK_LOG_DIR 

RUN echo "$LOG_TAG Install jupyter and toree" && \
    pip install --upgrade jsonschema && \
    pip install --upgrade jsonpointer && \
    pip install jupyter && \
    pip install toree

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.18.0/tini && \
    echo "12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install maven
RUN wget --quiet http://mirror.cc.columbia.edu/pub/software/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip && \
    echo "4d2763e1b73dfcde5c955f586bd754443833f63e20dd9ce4ce4405a2010bfc48324aa3b6bd5b6ac71a614112734b0bc652aa2ac05f492ed28a66de8116c3ef6e  apache-maven-3.5.4-bin.zip" | sha512sum -c - && \
    unzip -d /tmp apache-maven-3.5.4-bin.zip && \
    mv /tmp/apache-maven-3.5.4 /usr/local/share
ENV PATH $PATH:/usr/local/share/apache-maven-3.5.4/bin

# Create a new system user
RUN useradd -ms /bin/bash jupyter
ADD ./startup.sh /startup.sh
RUN chmod +x /startup.sh && \
    chmod 777 $SPARK_LOG_DIR

ADD ./jupyter_notebook_config.py /home/jupyter/.jupyter/jupyter_notebook_config.py
ADD ./data.csv /home/jupyter/data.csv
ADD ./conf/master/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf

# Install any needed packages specified in requirements.txt
ADD ./requirements.txt requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Set the container working directory to the user home folder
WORKDIR /home/jupyter
ADD . /home/jupyter

RUN jupyter toree install --spark_home=$SPARK_HOME --interpreters=Scala,PySpark,SparkR,SQL

USER jupyter

ENTRYPOINT ["tini", "-g", "--"]
CMD /startup.sh

