#!/bin/bash

set -e

ZEPPELIN_HOME=/home/zeppelin

ZEPPELIN_DEFAULT_BUILD="-Pspark-1.5 -Dspark.version=1.5.0 -Dhadoop.version=2.6.0 -Phadoop-2.6 -Pyarn -DskipTests"

print(){
	echo "[+] $*"
}

create_zeppelin_user(){
	print "Creating user 'zeppelin'"
	
	if getent passwd zeppelin > /dev/null 2&>1; then
		print "User 'zeppelin' exists. Skipping ..."
	else
		useradd zeppelin
		print "User 'zeppelin' created."
	fi

}
install_git(){
	print "Installing git ..."
	mkdir -p $ZEPPELIN_HOME
	cd $ZEPPELIN_HOME/prerequisites
	wget $GIT_DOWNLOAD_URL -O git-2.4.8.tar.gz > /dev/null 2&>1
	tar xzf git-2.4.8.tar.gz > /dev/null 2&>1
	cd git-2.4.8
	make prefix=$ZEPPELIN_HOME/prerequisites/git all > /dev/null 2&>1
	make prefix=$ZEPPELIN_HOME/prerequisites/git install > /dev/null 2&>1
	echo "export PATH=$PATH:$ZEPPELIN_HOME/prerequisites/bin" >> /home/zeppelin/.bashrc
	source /home/zeppelin/.bashrc
	echo `git --version`
	}

install_java(){
	print "Installing Java ..."
	if [ `uname -m` -eq "x86_64" ]; then
		cd $ZEPPELIN_HOME/prerequisites
		wget --no-check-certificate \
	     --no-cookies \
	     --header 'Cookie: oraclelicense=accept-securebackup-cookie' \
	     http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz \
	     -O jdk-7u79-linux-x64.tar.gz > /dev/null 2&>1
	     tar xvf jdk-7u79-linux-x64.tar.gz > /dev/null 2&>1
	    echo "export JAVA_HOME=$ZEPPELIN_HOME/prerequisites/jdk1.7.0_79" >> /home/zeppelin/.bashrc
	else
		print "Error: Arch not x86_64. Exiting ..."
	fi
	source /home/zeppelin/.bashrc
}
install_maven(){
	print "Installing Maven"
	cd $ZEPPELIN_HOME/prerequisites
	wget ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz > /dev/null 2&>1
	tar xzf apache-maven-3.3.3-bin.tar.gz > /dev/null 2&>1
	cd apache-maven-3.3.3
	export MAVEN_HOME=$ZEPPELIN_HOME/prerequisites/apache-maven-3.3.3
	echo "export PATH=$PATH:$ZEPPELIN_HOME/prerequisites/apache-maven-3.3.3/bin" >> /home/zeppelin/.bashrc
	source /home/zeppelin/.bashrc
	echo `mvn -version`
	}
install_deps(){
	print "Installing dependencies ..."
	yum install -y curl-devel \
		expat-devel \
		gettext-devel \
		openssl-devel \
		zlib-devel \
		gcc \
		perl-ExtUtils-MakeMaker > /dev/null 2&>1
	yum remove -y git > /dev/null 2&>1
	install_git
	install_java
	install_maven
	
	}
install_zeppelin(){
	cd $ZEPPELIN_HOME
	print "Downloading Zeppelin ..."
	git clone https://github.com/apache/incubator-zeppelin.git 
	print "Building Zeppelin ..."
	cd $ZEPPELIN_HOME/incubator-zeppelin
	mvn clean package $ZEPPELIN_DEFAULT_BUILD > /dev/null 2&>1
	print "Configuring Zeppelin ..."
	cd $ZEPPELIN_HOME/incubator-zeppelin/conf/
	touch zeppeline-env.sh
	echo "export JAVA_HOME=$ZEPPELIN_HOME/prerequisites/jdk1.7.0_79" >> zeppeline-env.sh
	echo "export HADOOP_CONF_DIR=/etc/hadoop/conf" >> zeppeline-env.sh
	##Warning:
	### If you see error related to jackson-databind jar.
	### Remove that from zeppelin-server/lib abd zeppelin-zengine/lib directory
	print "WARNING: Make sure hadoop-client is installed."
	print "WARNING: Copy hive-site.xml in $ZEPPELIN_HOME/conf directory."
}

create_zeppelin_user
install_deps
install_zeppelin
echo -e "[+] To start zeppelin:\nsu - zeppelin\n$ZEPPELIN_HOME/incubator-zeppelin/bin/zeppelin-daemon.sh start"
