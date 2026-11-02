## rpm_dependencies.sh BEGIN ##
# $Id: rpm_dependencies.sh,v 1.27 2025/02/04 23:55:03 mtacci Exp $ ##
IBM_Copyright() {
cat -<<EOC
##----------------------------------------------------------------------------------------------------------##
#@(#) Description: shell script                                                                             ##
#@(#) Author: mtacci 
#@(#) Copyright: Property of IBM, Copyright © 2017-2019 IBM Corporation, Armonk, NY. All Rights Reserved.   ##
#@(#)     The source code for this program is not published or otherwise divested of its trade secrets,     ##
#@(#)     irrespective of what has been deposited with the U.S. Copyright Office.                           ##
#@(#)     Use of this material without the express consent of IBM or assignees is unlawful and subject to   ##
#@(#)     prosecution to the fullest extent of the law.                                                     ##
##----------------------------------------------------------------------------------------------------------##
EOC
}

gen_rpm_dependencies(){
myOS=$1
devel=$2
multi=$3

if [ -n "$myOS" ] &&\
 [ "$myOS" != "rhel" ] &&\
 [ "$myOS" != "centos" ] &&\
 [ "$myOS" != "aldm" ] &&\
 [ "$myOS" != "dce" ] &&\
 [ "$myOS" != "prod" ] &&\
 [ "$myOS" != "devel" ]; then 
 return
fi

if [ "$myOS" = "rhel" ] ||  [ "$(awk '{print tolower($1)}' /etc/redhat-release)" = "red" ] ;then
 OSRELEASEFILE="/etc/os-release"
 source $OSRELEASEFILE
 for w in ID VERSION_ID; do
    x=$(printf "$%s" ${w})
    eval $w=$x
 done
elif [ "$myOS" = "centos" ] ||  [ "$(awk '{print tolower($1)}' /etc/redhat-release)" = "centos" ] ;then
 #CentOS Linux release 7.7.1908 (Core)
 OSRELEASEFILE="/etc/redhat-release"
 ID=centos
 VERSION_ID=$(awk '{split($4,a,".");printf("%d.%d",a[1],a[2])}' $OSRELEASEFILE )
fi

 RPMLIST7='
	audit-libs-2.8.5-4.el7.x86_64
	audit-libs-python-2.8.5-4.el7.x86_64
	audit-2.8.5-4.el7.x86_64
	checkpolicy-2.5-8.el7.x86_64
	device-mapper-multipath-libs-0.4.9-133.el7.x86_64
	device-mapper-multipath-0.4.9-133.el7.x86_64
	device-mapper-persistent-data-0.8.5-3.el7.x86_64
	libaio-0.3.109-13.el7.x86_64
	libcgroup-0.41-21.el7.x86_64
	libseccomp-2.3.1-4.el7.x86_64
        libsemanage-python-2.5-14.el7.x86_64
	libtirpc-0.2.4-0.16.el7.x86_64
	net-tools-2.0-0.25.20131004git.el7.x86_64
	policycoreutils-2.5-34.el7.x86_64
	policycoreutils-python-2.5-34.el7.x86_64
	policycoreutils-restorecond-2.5-34.el7.x86_64
	python3-libs-3.6.8-17.el7.x86_64
	python3-3.6.8-17.el7.x86_64
	python3-pip-9.0.3-8.el7.noarch
	python3-setuptools-39.2.0-10.el7.noarch
	python-chardet-2.2.1-3.el7.noarch
        python-kitchen-1.1.1-5.el7.noarch 
	python-IPy-0.75-6.el7.noarch
	setools-libs-3.3.8-4.el7.x86_64
	sharutils-4.13.3-8.el7.x86_64
	unzip-6.0-21.el7.x86_64
	zip-3.0-11.el7.x86_64
'
 RPMLIST8='
	audit-libs-3.0.7-5.el8.x86_64
	python3-audit-3.0.7-5.el8.x86_64
	audit-3.0.7-5.el8.x86_64
	checkpolicy-2.9-1.el8.x86_64
	libaio-0.3.112-1.el8.x86_64
	libcgroup-0.41-19.el8.x86_64
        libseccomp-2.5.2-1.el8.x86_64
	python3-libsemanage-2.9-9.el8.x86_64
	libtirpc-1.1.4-8.el8.x86_64
	net-tools-2.0-0.52.20160912git.el8.x86_64
	policycoreutils-2.9-24.el8.x86_64
	python3-policycoreutils-2.9-24.el8.noarch
	policycoreutils-restorecond-2.9-24.el8.x86_64
        python3-libs-3.6.8-62.el8.x86_64 
	python3-setuptools-39.2.0-7.el8.noarch
	setools-console-4.3.0-5.el8.x86_64
	unzip-6.0-46.el8.x86_64
	yum-utils-4.0.21-23.el8.noarch
	zip-3.0-23.el8.x86_64
'
 RPMLIST8mp='
	device-mapper-multipath-0.8.4-39.el8.x86_64
	device-mapper-multipath-libs-0.8.4-39.el8.x86_64
	device-mapper-persistent-data-0.9.0-7.el8.x86_64
'
 RPMLIST8mp7='
	device-mapper-multipath-0.8.4-28.el8.x86_64
	device-mapper-multipath-libs-0.8.4-28.el8.x86_64
	device-mapper-persistent-data-0.9.0-7.el8.x86_64
'
 RPMLIST8pp7='
	python2-2.7.18-11.module_el8.7.0+1179+42dadd5f.x86_64
 	python2-setuptools-wheel-39.0.1-13.module_el8.4.0+642+1dc4fb01.noarch
	python2-pip-wheel-9.0.3-19.module_el8.6.0+987+71f62bb6.noarch
	python2-libs-2.7.18-11.module_el8.7.0+1179+42dadd5f.x86_64
'
 RPMLIST8pp9='
	python2-2.7.18-17.module_el8+770+d35395c9.x86_64
	python2-setuptools-wheel-39.0.1-14.module_el8+733+876ccfdb.noarch
	python2-pip-wheel-9.0.3-19.module_el8+570+db61b4f9.noarch
	python2-libs-2.7.18-17.module_el8+770+d35395c9.x86_64
'
 RPMLIST8x='
	xz-libs-5.2.4-3.el8.x86_64
	xz-5.2.4-3.el8.x86_64
'
 RPMLIST8x6='
	xz-libs-5.2.4-4.el8.x86_64
	xz-5.2.4-4.el8.x86_64
'
 RPMLIST8l='
 	libtool-ltdl-2.4.6-25.el8.x86_64
	libxml2-2.9.7-9.el8_4.2.x86_64
	python3-libxml2-2.9.7-9.el8_4.2.x86_64
	device-mapper-libs-1.02.177-10.el8.x86_64
	device-mapper-1.02.177-10.el8.x86_64
	device-mapper-event-libs-1.02.177-10.el8.x86_64
	device-mapper-event-1.02.177-10.el8.x86_64
	lvm2-libs-2.03.12-10.el8.x86_64
	lvm2-2.03.12-10.el8.x86_64
'
 RPMLST8l6='
 	libtool-ltdl-2.4.6-25.el8.x86_64
	libxml2-2.9.7-14.el8.x86_64
	python3-libxml2-2.9.7-13.el8.x86_64
        device-mapper-libs-1.02.181-3.el8.x86_64
        device-mapper-1.02.181-3.el8.x86_64
	device-mapper-event-libs-1.02.181-3.el8.x86_64
	device-mapper-event-1.02.181-3.el8.x86_64
	lvm2-libs-2.03.12-10.el8.x86_64
	lvm2-2.03.12-10.el8.x86_64
'
 RPMLIST8l7='
 	libtool-ltdl-2.4.6-25.el8.x86_64
	libxml2-2.9.7-15.el8.x86_64
	python3-libxml2-2.9.7-15.el8.x86_64
        device-mapper-libs-1.02.181-6.el8.x86_64
        device-mapper-1.02.181-6.el8.x86_64
	device-mapper-event-libs-1.02.181-6.el8.x86_64
	device-mapper-event-1.02.181-6.el8.x86_64
	lvm2-libs-2.03.14-6.el8.x86_64
	lvm2-2.03.14-6.el8.x86_64
'
 ##libtool??? 
 RPMLIST8l9='
	libxml2-2.9.7-18.el8.x86_64
	python3-libxml2-2.9.7-18.el8.x86_64
	device-mapper-libs-1.02.181-14.el8.x86_64
	device-mapper-1.02.181-14.el8.x86_64
	device-mapper-event-libs-1.02.181-14.el8.x86_64
	device-mapper-event-1.02.181-14.el8.x86_64
	lvm2-libs-2.03.14-14.el8.x86_64
	lvm2-2.03.14-14.el8.x86_64
'
 RPMLIST8l9p='
 	python2-2.7.18-17.module_el8+770+d35395c9.x86_64
	python2-pip-wheel-9.0.3-19.module_el8+570+db61b4f9.noarch
	python2-libs-2.7.18-17.module_el8+770+d35395c9.x86_64
'

 RPMLIST8P='
	python2-2.7.18-15.module+el8.9.0+20125+68111a8f.x86_64
	python2-chardet-3.0.4-18.module+el8.9.0+19487+7dc18407.noarch
        python-kitchen-1.2.6.el8.noarch
	python-IPy-0.75-6.el7.noarch
'
#libs
 RPMLIST72='
	libtool-ltdl-2.4.2-22.el7_3.x86_64
'
 RPMLIST75='
	libxml2-2.9.1-6.el7.5.x86_64
	libxml2-python-2.9.1-6.el7.5.x86_64
'
 RPMLIST77='
	device-mapper-libs-1.02.170-6.el7.x86_64
	device-mapper-1.02.170-6.el7.x86_64
	device-mapper-event-libs-1.02.170-6.el7.x86_64
	device-mapper-event-1.02.170-6.el7.x86_64
	lvm2-libs-2.02.187-6.el7.x86_64
	lvm2-2.02.187-6.el7.x86_64
'
 RPMLIST78='
	yum-utils-1.1.31-54.el7_8.noarch
'
 RPMLIST80='
	sharutils-4.15.2-11.el8.x86_64
'
#docker
 RPMLIST7d='
	docker-ce-19.03.5-3.el7.x86_64
	docker-ce-cli-19.03.5-3.el7.x86_64
        containerd.io-1.2.10-3.2.el7.x86_64
'
 
 #local fetch for RPMLIST8a
 RPMLIST8a='
        python36-3.6.8-2.module+el8.1.0+3334+5cb623d7.x86_64	
'
 RPMLIST8a6='
        python36-3.6.8-38.module+el8.5.0+12207+5c5719bc.x86_64
'
 RPMLIST8a9='
python36-3.6.8-38.module+el8.9.0+20976+d3c38525.x86_64
'
 RPMLIST8d='
	criu-3.15-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	runc-1.0.0-74.rc95.module+el8.4.0+11822+6cc1e7d7.x86_64
	libslirp-4.3.1-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	slirp4netns-1.1.8-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	fuse3-libs-3.2.1-12.el8.x86_64
	fuse-overlayfs-1.6-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	fuse-common-3.2.1-12.el8.x86_64
	fuse3-3.2.1-12.el8.x86_64
	systemd-container-239-45.el8_4.3.x86_64
	containers-common-1.3.1-5.module+el8.4.0+11990+22932769.x86_64
	conmon-2.0.29-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	containernetworking-plugins-0.9.1-1.module+el8.4.0+11822+6cc1e7d7.x86_64
	iptables-1.8.4-17.el8_4.1.x86_64
	podman-3.2.3-0.11.module+el8.4.0+12050+ef972f71.x86_64
	podman-catatonit-3.2.3-0.11.module+el8.4.0+12050+ef972f71.x86_64
	podman-docker-3.2.3-0.11.module+el8.4.0+12050+ef972f71.noarch
'
 RPMLIST8d6='
 	criu-3.15-3.module+el8.6.0+14877+f643d2d6.x86_64
	runc-1.0.3-2.module+el8.6.0+14877+f643d2d6.x86_64
	libslirp-4.4.0-1.module+el8.6.0+14877+f643d2d6.x86_64
	slirp4netns-1.1.8-2.module+el8.6.0+14877+f643d2d6.x86_64
	fuse3-libs-3.3.0-15.el8.x86_64
	fuse-overlayfs-1.8.2-1.module+el8.6.0+14877+f643d2d6.x86_64
	fuse-common-3.3.0-15.el8.x86_64
	fuse3-3.3.0-15.el8.x86_64
	systemd-container-239-58.el8.x86_64
	containers-common-1-27.module+el8.6.0+14877+f643d2d6.x86_64
	conmon-2.1.0-1.module+el8.6.0+14877+f643d2d6.x86_64
	containernetworking-plugins-1.0.1-2.module+el8.6.0+14877+f643d2d6.x86_64
	iptables-1.8.4-22.el8.x86_64
	shadow-utils-subid-4.6-16.el8.x86_64
	podman-4.0.2-6.module+el8.6.0+14877+f643d2d6.x86_64
	podman-catatonit-4.0.2-6.module+el8.6.0+14877+f643d2d6.x86_64
	podman-docker-4.0.2-6.module+el8.6.0+14877+f643d2d6.noarch
'
 RPMLIST8d7='
 	criu-3.15-3.module+el8.7.0+17498+a7f63b89.x86_64
	runc-1.1.4-1.module+el8.7.0+17498+a7f63b89.x86_64
	libslirp-4.4.0-1.module+el8.7.0+17498+a7f63b89.x86_64
	slirp4netns-1.2.0-2.module+el8.7.0+17498+a7f63b89.x86_64
	fuse3-libs-3.3.0-16.el8.x86_64
	fuse-overlayfs-1.9-1.module+el8.7.0+17498+a7f63b89.x86_64
	fuse-common-3.3.0-16.el8.x86_64
	fuse3-3.3.0-16.el8.x86_64
	systemd-container-239-68.el8_7.2.x86_64
	containers-common-1-44.module+el8.7.0+17498+a7f63b89.x86_64
	conmon-2.1.4-1.module+el8.7.0+17498+a7f63b89.x86_64
	containernetworking-plugins-1.1.1-3.module+el8.7.0+17498+a7f63b89.x86_64
	iptables-1.8.4-23.el8.x86_64
	shadow-utils-subid-4.6-17.el8.x86_64
	podman-4.2.0-6.module+el8.7.0+17498+a7f63b89.x86_64
	podman-catatonit-4.2.0-6.module+el8.7.0+17498+a7f63b89.x86_64
	podman-docker-4.2.0-6.module+el8.7.0+17498+a7f63b89.noarch
'
 RPMLIST8d9='
	criu-3.18-4.module+el8.9.0+21697+6a5e98e7.x86_64
	runc-1.1.12-1.module+el8.9.0+21697+6a5e98e7.x86_64
	libslirp-4.4.0-1.module+el8.9.0+21697+6a5e98e7.x86_64
	slirp4netns-1.2.1-1.module+el8.9.0+21697+6a5e98e7.x86_64
	fuse3-libs-3.3.0-17.el8.x86_64
	fuse-overlayfs-1.12-1.module+el8.9.0+21697+6a5e98e7.x86_64
	fuse-common-3.3.0-17.el8.x86_64
	fuse3-3.3.0-17.el8.x86_64
	systemd-container-239-78.el8.x86_64
	containers-common-1-71.module+el8.9.0+21697+6a5e98e7.x86_64
	conmon-2.1.8-1.module+el8.9.0+21697+6a5e98e7.x86_64
	containernetworking-plugins-1.3.0-8.module+el8.9.0+21697+6a5e98e7.x86_64
	iptables-1.8.5-11.el8_9.x86_64
	
	podman-4.6.1-9.module+el8.9.0+21697+6a5e98e7.x86_64
	podman-catatonit-4.6.1-9.module+el8.9.0+21697+6a5e98e7.x86_64
	podman-docker-4.6.1-9.module+el8.9.0+21697+6a5e98e7.noarch
'
#application #dce
 RPMLIST7e='
	epel-release-7-14.noarch
'
 RPMLIST8e='
	epel-release-8-20.el8.noarch 
'
 RPMLIST7j='
	jq-1.5-1.el7.x86_64
'
 RPMLIST8j='
	jq-1.6-7.el8.x86_64
'
	#jq-1.6-3.el8.x86_64
 RPMLIST7m='
        make-3.82-24.el7.x86_64
'
 RPMLIST8m='
 	make-4.2.1-11.el8.x86_64
'
 RPMLIST7o='
	oniguruma-6.8.2-2.el7.x86_64
'
 RPMLIST8o='
	oniguruma-6.8.2-3.el8.x86_64
'
#optonal
 RPMLIST7s='
	container-selinux-2.107-1.el7_6.noarch
'
 RPMLIST8s4='
        container-selinux-2.167.0-1.module+el8.4.0+12646+b6fd1bdf.noarch
'
 RPMLIST8s61='
 	policycoreutils-python-utils-2.9-19.el8.noarch
	selinux-policy-3.14.3-95.el8_6.1.noarch
	selinux-policy-targeted-3.14.3-95.el8_6.1.noarch
	rpm-plugin-selinux-4.14.3-23.el8.x86_64
'
 RPMLIST8s62='
	container-selinux-2.188.0-1.module+el8.6.0+15917+093ca6f8.noarch
'
 RPMLIST8s71='
 	policycoreutils-python-utils-2.9-20.el8.noarch
	selinux-policy-3.14.3-95.el8_6.1.noarch
	selinux-policy-targeted-3.14.3-95.el8_6.1.noarch
	rpm-plugin-selinux-4.14.3-23.el8.x86_64
'
 RPMLIST8s72='
	container-selinux-2.188.0-1.module+el8.6.0+15917+093ca6f8.noarch
'
 RPMLIST8s9='
	container-selinux-2.229.0-1.module+el8.9.0+21697+6a5e98e7.noarch
'


##development rpms
#node
 RPMLIST7n='
        nodejs-13.0.1-1nodesource.x86_64
'
#/usr/local/bin/node --version # v13.14.1-pre
#node --version v14.18.2
 RPMLIST8n='
	nodejs-1:14.18.2-2.module+el8.5.0+13644+8d46dafd.x86_64
	npm-1:6.14.15-1.14.18.2.2.module+el8.5.0+13644+8d46dafd.x86_64
'
        #nodejs-full-i18n-1:14.18.2-2.module+el8.5.0+13644+8d46dafd.x86_64
#yarn
#https://github.com/yarnpkg/yarn/releases/download/v1.22.4/yarn-1.22.4-1.noarch.rpm
#https://master.dl.sourceforge.net/project/yarn.mirror/v1.22.4/
 RPMLIST7y='
        yarn-1.22.4-1.noarch
'
 RPMLIST8y='
	yarn-1.22.17-1.noarch
'
#gcc
 RPMLIST7g='
        gcc-4.8.5-44.el7.x86_64
        gcc-c++-4.8.5-44.el7.x86_64
        libgcc-4.8.5-44.el7.x86_64
        cmake-2.8.12.2-2.el7.x86_64
        make-3.82-24.el7.x86_64
'
 #local fetch for RPMLIST8g
 RPMLIST8g='
	python3-pip-9.0.3-23.el8_9.1.noarch
	libgcc-8.5.0-20.el8.x86_64
	gcc-8.5.0-20.el8.x86_64
	gcc-c++-8.5.0-20.el8.x86_64
	cmake-3.26.5-1.el8_9.x86_64
	make-4.2.1-11.el8.x86_64
	openssl-1.1.1k-12.el8_9.x86_64
	openssl-devel-1.1.1k-12.el8_9.x86_64
	openssl-libs-1.1.1k-12.el8_9.x86_64
'
#perl
 RPMLIST7p='
        perl-5.16.3-297.el7.x86_64
        perl-libs-5.16.3-297.el7.x86_64
        perl-devel-5.16.3-297.el7.x86_64 
	'
 RPMLIST7p2='
	keyutils-libs-devel-1.5.8-3.el7.x86_64
        krb5-devel-1.15.1-50.el7.x86_64
        libkadm5-1.15.1-50.el7.x86_64
        libcom_err-devel-1.42.9-19.el7.x86_64
        libselinux-devel-2.5-15.el7.x86_64
        libsepol-devel-2.5-10.el7.x86_64
        libverto-devel-0.2.5-4.el7.x86_64
        openssl-devel-1.0.2k-19.el7.x86_64
        pcre-devel-8.32-17.el7.x86_64
        zlib-devel-1.2.7-18.el7.x86_64
'
 RPMLIST8p='
	perl-5.26.3-422.el8.x86_64
	perl-libs-5.26.3-422.el8.x86_64
	perl-devel-5.26.3-422.el8.x86_64
'
 RPMLIST8p2='
 	keyutils-libs-devel-1.5.10-9.el8.x86_64
	krb5-devel-1.18.2-26.el8_9.x86_64
	libcom_err-devel-1.45.6-5.el8.x86_64
	libkadm5-1.18.2-26.el8_9.x86_64
	libselinux-devel-2.9-8.el8.x86_64
	libsepol-devel-2.9-3.el8.x86_64
	libverto-devel-0.3.2-2.el8.x86_64
	pcre-cpp-8.42-6.el8.x86_64
	pcre-utf16-8.42-6.el8.x86_64
	pcre-utf32-8.42-6.el8.x86_64
	pcre-devel-8.42-6.el8.x86_64
	zlib-devel-1.2.11-25.el8.x86_64
'
 RPMLIST8jdk='
	java-1.8.0-openjdk-1.8.0.342.b07-2.el8_6.x86_64	
	java-1.8.0-openjdk-devel-1.8.0.342.b07-2.el8_6.x86_64	
'
 ## OS switching 
 major=${VERSION_ID%.*}
 minor=${VERSION_ID#*.*}
 test $major -eq $major || major=0 
 test $minor -eq $minor || minor=0 

 ##composites
 RPMLIST7C="$RPMLIST7 $RPMLIST72 $RPMLIST75 $RPMLIST77 $RPMLIST78" #Centos

 ## app specific
 RPMLIST7D="$RPMLIST7e  $RPMLIST7j  $RPMLIST7o $RPMLIST7m" #dce
 RPMLIST8D="$RPMLIST8e  $RPMLIST8j  $RPMLIST8o $RPMLIST8m" #dce
 RPMLIST7A="$RPMLIST7n  $RPMLIST7g  $RPMLIST7y $RPMLIST7p $RPMLIST7p2" #aldm devel
 RPMLIST8A="$RPMLIST8n  $RPMLIST8g  $RPMLIST8y $RPMLIST8jdk " #RPMLIST8p RPMLIST8p2 #aldm devel


#correct for interim or multiple versions
 [ $minor -le 5 ] && [ $minor -gt 0 ] && minor=4
# [ $minor -ge 6 ] && minor=6
 [ "$multi" == "4" ]  && minor=4 ; [ "$multi" == "6" ]  && minor=6 ; [ "$multi" == "7" ]  && minor=7 

 # monor switching and #composites
 if [ $major -ge 8 ]; then
	[ $minor -eq 7 ] ||\
	       	RPMLIST8="$RPMLIST8 $RPMLIST8mp"
	[ $minor -eq 4 ] &&\
	       	RPMLIST8l=$RPMLIST8l4 
	[ $minor -ge 6 ] &&\
	       	RPMLIST8x=$RPMLIST8x6 &&\
	       	RPMLIST8a=$RPMLIST8a6 
	[ $minor -eq 6 ] &&\
	       	RPMLIST8d=$RPMLIST8d6 &&\
	       	RPMLIST8l=$RPMLIST8l6  
	[ $minor -eq 7 ] &&\
	       	RPMLIST8d=$RPMLIST8d7 &&\
	       	RPMLIST8l=$RPMLIST8l7 &&\
	       	RPMLIST8="$RPMLIST8 $RPMLIST8mp7 "
	[ $minor -eq 9 ] &&\
	       	RPMLIST8d=$RPMLIST8d9 &&\
	       	RPMLIST8l="$RPMLIST8l9 $RPMLIST8lp" &&\
	       	RPMLIST8="$RPMLIST8 $RPMLIST8mp9 "
       #RPMLIST8C="$RPMLIST8 $RPMLIST8l $RPMLIST8d $RPMLIST8x " 
       RPMLIST8C="$RPMLIST8 $RPMLIST8x $RPMLIST8l " 
 fi  
 ## summary
 RPMLIST7R="$RPMLIST7 $RPMLIST7s $RPMLIST7d $RPMLIST72 $RPMLIST75 $RPMLIST77 $RPMLIST78" #all required order is important
 RPMLIST7X="" #extra 

 RPMLIST8R="$RPMLIST8 $RPMLIST8x $RPMLIST8a $RPMLIST8s $RPMLIST8d $RPMLIST80 $RPMLIST8l " #all required order is important
 RPMLIST8X="" #extra 

 #dec adds
 [ "$myOS" == "dce" ] || [ "$myOS" == "prod" ] &&\
     RPMLIST7X="$RPMLIST7X $RPMLIST7D" &&\
     RPMLIST8X="$RPMLIST8X $RPMLIST8D"

 [ "$myOS" == "devel" ] && RPMLIST7X="$RPMLIST7X $RPMLIST7D $RPMLIST7A "
 [ "$myOS" == "devel" ] && RPMLIST8X="$RPMLIST8X $RPMLIST8D $RPMLIST8A $RPMLIST8p $RPMLIST8p2"

 #selinux
 if [ $major -ge 8 ]; then
	[ $minor -eq 4 ] && RPMLIST8s="$RPMLIST8s4" ## 8.4+
	[ $minor -eq 6 ] && RPMLIST8s="$RPMLIST8s61 $RPMLIST8s62" ## 8.6+
	[ $minor -eq 7 ] && RPMLIST8s="$RPMLIST8s71 $RPMLIST8s72" ## 8.7+
 fi  


 ## OS swicthing was forced by passing a os major
 if [ "$devel" -eq "$devel" ] 2>/dev/null; then
   [ $devel -eq 7 ] && eval echo \$RPMLIST7R \$RPMLIST7X # 7
   [ $devel -eq 8 ] && eval echo \$RPMLIST8R \$RPMLIST8X  \$RPMLIST8pp9 # 8
   MAJOR=$devel
   [ "$multi" == "46" ] && RPMLIST8s="$RPMLIST8s4 $RPMLIST8s61 $RPMLIST8s62" 
   [ "$multi" == "47" ] && RPMLIST8s="$RPMLIST8s4 $RPMLIST8s71 $RPMLIST8s72" 
   [ "$multi" == "467" ] && RPMLIST8s="$RPMLIST8s4 $RPMLIST8s61 $RPMLIST8s62 $RPMLIST8s71 $RPMLIST8s72" 
   [ $minor -eq 7 ] && RPMLIST8d6=$RPMLIST8d7  && RPMLIST8l6=$RPMLIST8l7
   [ $minor -eq 9 ] && RPMLIST8d6=$RPMLIST8d9  && RPMLIST8l6="$RPMLIST8l9 $RPMLIST8l9" && RPMLIST8pp7=$RPMLIST8pp9
   RPMLIST8R="$RPMLIST8 $RPMLIST8x $RPMLIST8x6 $RPMLIST8a $RPMLIST8s $RPMLIST8d $RPMLIST8d6 $RPMLIST80 $RPMLIST8l $RPMLIST8l6" #all required order is important
 else
   [ $major -eq 7 ] && [ $minor -ge 2 ] && eval echo \$RPMLIST7R \$RPMLIST7X ## 7.2+
   [ $major -eq 8 ] && [ $minor -ge 7 ] && eval echo \$RPMLIST8R \$RPMLIST8X \$RPMLIST8pp9 ## 8.7+
 fi


 R3PRE="rpms/${MAJOR:-$major}"
 if [ ${MAJOR:-$major} -eq 7 ] ; then
  #required RPMLIST7R 
  installed_dependencies_urls  "http://mirror.centos.org/centos/7/os/x86_64/Packages" \$RPMLIST7C 
  installed_dependencies_urls  "http://mirror.centos.org/centos/7/extras/x86_64/Packages" \$RPMLIST7s
  installed_dependencies_urls  "https://download.docker.com/linux/centos/7/x86_64/stable/Packages" \$RPMLIST7d
  if [ "$myOS" == "devel" ] || [ "$myOS" == "dce" ] || [ "$myOS" == "prod" ]; then 
  #dce 
   installed_dependencies_urls  "http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e" \$RPMLIST7e
   installed_dependencies_urls  "https://cbs.centos.org/kojifiles/packages/jq/1.5/1.el7/x86_64" \$RPMLIST7j
   installed_dependencies_urls  "http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/o" \$RPMLIST7o
   installed_dependencies_urls  "http://mirror.centos.org/centos/7/os/x86_64/Packages" \$RPMLIST7m 
  fi
  #devel
  if [ "$myOS" == "devel" ]; then 
   installed_dependencies_urls  "https://rpm.nodesource.com/pub_13.x/el/7/x86_64" \$RPMLIST7n
   installed_dependencies_urls  "https://master.dl.sourceforge.net/project/yarn.mirror/v1.22.4" \$RPMLIST7y
   installed_dependencies_urls  "http://mirror.centos.org/centos/7/os/x86_64/Packages" \$RPMLIST7g \$RPMLIST7p \$RPMLIST7p2
  fi
 fi

 if [ ${MAJOR:-$major} -eq 8 ] ; then
  #required RPMLISTR8 
  installed_dependencies_urls  "https://vault.centos.org/8-stream/BaseOS/x86_64/os/Packages/" \$RPMLIST8C 
  installed_dependencies_urls  "https://vault.centos.org/centos/8-stream/PowerTools/x86_64/os/Packages/" \$RPMLIST80 
  installed_dependencies_urls  "https://vault.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/" \$RPMLIST8pp9
  installed_dependencies_urls_local \$RPMLIST8s \$RPMLIST8d \$RPMLIST8a  #local fetch

  #dce 
  if [ "$myOS" == "devel" ] || [ "$myOS" == "dce" ] || [ "$myOS" == "prod" ]; then 
   installed_dependencies_urls "https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/e/" \$RPMLIST8e
   installed_dependencies_urls  "https://vault.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/" \$RPMLIST8j 
   installed_dependencies_urls  "https://vault.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/" \$RPMLIST8o
   installed_dependencies_urls_local \$RPMLIST8m  
  fi
  if [ "$myOS" == "devel" ]; then 
   installed_dependencies_urls_local \$RPMLIST8n
   installed_dependencies_urls  'https://master.dl.sourceforge.net/project/yarn.mirror/v1.22.17/' \$RPMLIST8y
   installed_dependencies_urls_local \$RPMLIST8g \$RPMLIST8p \$RPMLIST8p2 \$RPMLIST8jdk 
 fi
fi

 if [ ${MAJOR:-$major} -eq 9 ] ; then
   installed_dependencies_urls "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/Packages/" \$RPMLIST9C
 fi
}

installed_dependencies() {
myRPMLIST=$1
 found=""; alfound="";unfound=""
 >/tmp/f.lst;>/tmp/a.lst; >/tmp/u.lst
 for n in $myRPMLIST; do
    p=$(echo $n|sed -e 's/\(^[a-zA-Z2-9+-]*\)\-[0-9].*/\1/')
    #printf "%s=%s\n " $n $p >> /tmp/8.lst #debug
    if rpm -q $n >/dev/null 2>/dev/null; then
       found="$found $(rpm -q $n 2>/dev/null)"
    elif rpm -q $p >/dev/null 2>/dev/null; then
       alfound="$alfound $(rpm -q $p 2>/dev/null)"
    else
       unfound="$unfound $n"
    fi
 done
 printf "\nFOUND: $(echo $found|sed 'y/\n/ /')\n"
 printf "\nALTFOUND: $(echo $alfound|sed 'y/\n/ /')\n"
 printf "\nMISSING: $(echo $unfound|sed 'y/\n/ /')\n"
 if [ $DEBUG ]; then 
 	echo $alfound|sed 'y/ /\n/' > /tmp/a.lst
 	echo $found|sed 'y/ /\n/' > /tmp/f.lst
 	echo $unfound|sed 'y/ /\n/' > /tmp/u.lst
 fi
}

get_pythonV(){
  declare -a P=("python" "python2" "python3")
  n=-1
  success=0
  while [ $n -le 2 ] && [ $success -eq 0 ] ;do
     ((n++))
     hash ${P[$n]} 2>/dev/null && success=1
  done
 [ $success -eq 1 ] && ${P[$n]} -V 2>&1
}

installed_applications(){
errs=0;warns=0
## prereq packages
    rApps="python"
    iApps=$(get_pythonV)

    if [ -n "$iApps" ]  && [ "$(echo "$iApps" | cut -c2-6)"  == "ython" ]; then
	    printf "\nFOUND: $(echo $iApps|sed 'y/\n/ /')\n"
    else
	    printf "\nMISSING: $(echo $rApps|sed 'y/\n/ /')\n"
    fi
}

installed_dependencies_urls() {
myURL=$1 ; shift
myRPMLIST=$@
 rpms=`eval echo $myRPMLIST` 
 for n in $rpms; do
   p="$myURL/${n}.rpm"
   q="${n}.rpm"
   echo "$p"| sed -e '/^$/d' >>/tmp/r.lst
   echo "${R3PRE}/$q"| sed -e '/^$/d' >>/tmp/r3.lst
 done
}

installed_dependencies_urls_local() {
myRPMLIST=$@
 rpms=`eval echo $myRPMLIST` 
 for n in $rpms; do
   q="${n}.rpm"
   echo "$q"| sed -e '/^$/d' >>/tmp/r2.lst
   echo "${R3PRE}/$q"| sed -e '/^$/d' >>/tmp/r3.lst
 done
}

fetch_dependencies() {
err=0
infile=$1
outdir=$2
: ${outdir:="/tmp/rpms"}
[ -d $outdir ] || mkdir -p  $outdir
 #curl -# https://pypi.python.org/pypi/kitchen/python-kitchen-1.1.1-5.el7.noarch.rpm -o /tmp/rpms/python-kitchen-1.1.1-5.el7.noarch.rpm
 #curl -# http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages/gcc-8.5.0-3.el8.x86_64.rpm -o /tmp/rpms/gcc-8.5.0-3.el8.x86_64.rpm

 while read n; do
   [ -f ${outdir}/${n##*/} ] || sh -c "curl -# $n -o $outdir/${n##*/}"
   if !(file $outdir/${n##*/}|grep -q RPM);then
	rm -f $outdir/${n##*/}
	echo "error: PKG  ${n##*/} not found in repo ${n%*/*}/" 
	echo "trying again" && sh -c "wget -nv -O $outdir/${n##*/} $n"
   	if !(file $outdir/${n##*/}|grep -q RPM);then
	  echo "error: PKG  ${n##*/} not found in repo ${n%*/*}/" |tee -a /tmp/fe.lst
  	  ((errs++))
   	fi
   fi
 done <$infile
 #rm -f $infile
  echo "Errors:$errs" 
 return $errs
}

fetch_dependencies_local() {
 infile=$1
 outdir=$2
/usr/libexec/platform-python -c "import dnf, json; db = dnf.dnf.Base(); print(json.dumps(db.conf.substitutions, indent=2))"
: ${outdir:="/tmp/rpms"}
[ -d $outdir ] || mkdir -p  $outdir
 while read n; do
   p=$(echo ${n%*-*}|sed -e 's/-[0-9]\..*$//')
   #printf "\rLooking for ${outdir}/${n}                                                                               "
   printf "."; sleep .3
   if [ ! -f ${outdir}/${n} ] ; then
   	#printf "\rNot Found ${outdir}/${n}                                                                                 \n"
	sh -c "dnf  --downloadonly --downloaddir $outdir download ${n%*.rpm} 2>/dev/null" ||\
		sh -c "dnf  --downloadonly --downloaddir $outdir download $p 2>/dev/null"
	[ -f ${outdir}/${n} ] &&\
	   grep -q x86_64 ${outdir}/${n} 2>/dev/null &&\
	   i=$(echo $n|sed -e 's/x86_64/i686/') &&\
	   [ -f ${outdir}/${i} ] &&\
	   rm -f ${outdir}/${i}
   fi
 done <$infile
   printf "\r                                                                                                                              \n"
}

install_requirements(){
myOS=$1
errs=0;warns=0
ADDURLS="https://download.docker.com https://dl.fedoraproject.org"

## OS
printf " ------ System requirements check ------ \n\n" |tee /tmp/ir.log || (sudo rm -f /tmp/ir.log && echo "run again please")
if [ "$myOS" = "rhel" ] ||  [ "$(awk '{print tolower($1)}' /etc/redhat-release)" = "red" ] ;then
 OSRELEASEFILE="/etc/os-release"
 source $OSRELEASEFILE
 for w in ID VERSION_ID; do
    x=$(printf "$%s" ${w})
    eval $w=$x
 done
 myOS=rhel
elif [ "$myOS" = "centos" ] ||  [ "$(awk '{print tolower($1)}' /etc/redhat-release)" = "centos" ] ;then
 #CentOS Linux release 7.7.1908 (Core)
 OSRELEASEFILE="/etc/redhat-release"
 ID=centos
 VERSION_ID=$(awk '{split($4,a,".");printf("%d.%d",a[1],a[2])}' $OSRELEASEFILE )
 myOS=centos
fi

 #version?
 major=${VERSION_ID%.*}; minor=${VERSION_ID#*.*}
 if [ "$ID" == "$myOS" ] &&\
  test "$major" -eq "$major" &&\
  test "$minor" -eq "$minor" &&\
  ([ $major -eq 7 ] && [ $minor -ge 2 ] || [ $major -eq 8 ] && [ $minor -ge 4 ]) ;then
  echo "ID=$ID VERSION_ID=$VERSION_ID KERNEL=$(uname -r)" |tee -a /tmp/ir.log
 else
  echo "Error: not ostype=$myOS" |tee -a /tmp/ir.log
  ((errs++))
 fi 

 ## repos
 if ( hash subscription-manager 2>/dev/null);then
    if [ $(id -u) -eq 0 ] ;then
        subscription-manager list | tee -a /tmp/ir.log
        subscription-manager status | tee -a /tmp/ir.log
    fi
 else
    echo "Warn: Unable to discover RHN  subscription manager" |tee -a /tmp/ir.log
    ((warns++))
    ADDURLS="$ADDURLS https://access.redhat.com "
 fi
 if [ $(id -u) -eq 0 ] ;then
  if ( yum  repolist -v >/dev/null 2>&1 ); then
   urls=$(yum  repolist -v|grep 'Repo-\(baseurl\|metalink\)'|cut -d: -f2-4|cut -d/ -f1-3)
   urls="$urls $ADDURLS"
   for n in $urls;do
     if  curl -s --head $n > /dev/null ;then
       echo "URL ok: $n" | tee -a /tmp/ir.log
     else
       echo "Warn: URL failed: $n" | tee -a /tmp/ir.log
       ((warns++))
     fi
   done
  else
   echo "Warn: Unable to discover YUM repositories" |tee -a /tmp/ir.log
   ((warns++))
  fi
 fi

 ## hardware
 cpus=$(cat /proc/cpuinfo | awk -F: ' $1 ~ /processor/ {printf("%d\n",$2+1)}'|tail -1)
 mem=$(cat /proc/meminfo | awk -F: ' $1 ~ /MemTotal/ {printf("%d\n",$2/1000/1000)}')
 gb=$(df -k|awk ' $1 ~ /\/dev/ {n=n+$4;print int(n/1024/1024)}'|tail -1)
 dcedev="$(mount|awk ' $3 ~ /\dce/ {print $1}')"
 mcpu=2
 mmem=3
 mgb=60
 if [ -n "$cpus" ] && [ -n "$mem" ] && [ -n "$gb" ] ;then 
    echo "CPUS:$cpus  MEM:$mem GB  AVAILABLE_STORAGE:$gb GB" |tee -a /tmp/ir.log
    if [ $cpus -lt 2 ] || [ $mem -lt 3 ] || [ $gb -lt 60 ] ; then
       echo "Warn: System size does not meet minumums !" |tee -a /tmp/ir.log
       ((warns++))
    fi
    if [ $cpus -lt $mcpu ] || [ $mem -lt $mmem ] || [ $gb -lt $mgb ] ; then
       echo "Warn: System size may be insuffcient !" |tee -a /tmp/ir.log
       echo "Minimum CPUS:$mcpu  MEM:$mmem GB  AVAILABLE_STORAGE:$mgb GB" |tee -a /tmp/ir.log
       ((warns++))
    fi
    if [ -n "$dcedev" ] ;then
     echo "The $dcedev is mounted for the required '/dce' directory "
     echo "Please ensure that $(df -k /dce |tail -1|awk '{n=$4;print int(n/1024/1024),"GB"}') is sufficent in size " 
    else
     echo "Warn: There is no '/dce' filessystem on the system" |tee -a /tmp/ir.log
       ((warns++))
    fi
 else 
  echo "Error: Unable to determine system size" |tee -a /tmp/ir.log
       ((errs++))
 fi

## conclusion
  echo "Errors:$errs" 
  echo "Warnings:$warns" 
 return $errs
}

install_rpm_dependencies_now(){
LIST=$1
err=0
rpmlist=""
ok=0

 [ $DECODE -eq 0 ] && ok=0 &&\
  [ -f dependencies.tgz ] &&\
  echo "expanding dependencies locally" &&\
  tar -xzf dependencies.tgz -C /tmp && ok=1

  [ $ok -ge 1 ] || ((err++))

 ##install rpms
 for n in $LIST ;do
  p=$(echo $n|sed -e 's/\(^[a-zA-Z2-9+-]*\)\-[0-9].*/\1/')
  printf "\rChecking for $p                      " && rpm --quiet -q $p  || rpmlist="$rpmlist ${n}.rpm" 
  sleep .3
 done
 printf "\r                                     \n"
 
  haverpmlist=""
  for n in $rpmlist; do
      [ -f /tmp/rpms/$major/$n ] && haverpmlist="$haverpmlist /tmp/rpms/$major/$n"
  done 
  if [ -n "$haverpmlist" ] ;then
     echo "installing rpms: $haverpmlist" 
     echo -n "Do you wish to install these now? [Y|n]"; read ans
     [ "$ans" == "n" ] && ECHO=echo
     for n in $haverpmlist ;do
         $ECHO rpm --nodeps -Uvh -p $n  || ((err++)) 
	 echo $n|grep 'selinux-policy-[1-9]' 2>&1 >/dev/null && update_selinux
     done
  fi
  echo "rpmlist INSTALL error code: $err"
  echo "... done"
  return #$err
}

update_selinux(){
  cp -p  /etc/selinux/config /tmp
  sed -e 's/\(SELINUX=\)enforcing/\1disabled/' /tmp/config > /etc/selinux/config
  setenforce 0
}


depclean() {
ALL=$1
	rm -f /tmp/a.lst  /tmp/f.lst  /tmp/r3.lst /tmp/r2.lst  /tmp/r.lst  /tmp/u.lst /tmp/fe.lst
	[ "$ALL" == "all" ] && rm -fr /tmp/rpms
exit
}

dephelp() {
cat -<< EOM
   USAGE:$(basename $0) [help|list|show|showall|fetch|install] [rhel|centos|prod|devel] [7|8]
                        clean [all]

        		  	help = this file
                        	list = list the required dependencies 
                        	show = check install requirements and dependencies required
                        	devel = dependencies required for developemnt
                        	fetch = fetch dependencies required 
                        	install = CAUTION!!! installs dependencies from tarball or rpm tree

                        	rhel|centos - requirements for rhel or centos OS
				aldm|dce - requirements for aldm or dce ecosystem     (defaults to current OS)
                        	prod    - requirements for a production environment (defaults to current OS)
                        	devel    - requirements for a development environment (defaults to current OS)

                        	7|8      - major OS level			      (defaults to current O level)

				clean - removes temporary lst files and rpm directory with [all] 

EOM
exit
}

if [ $(basename $0) == "rpm_dependencies.sh" ] ; then
   >/tmp/r.lst; >/tmp/r2.lst; >/tmp/r3.lst
   DEBUG=0
   LOCAL=0
   [ "$1" == "version" ] && echo "v$(grep '^# $Id:' $0 |awk -F, '{split($2,a," ");print a[2]}')" && exit
   [ "$1" == "help" ] && dephelp
   [ "$1" == "clean" ] && depclean $2
   if [ "$(echo $1|cut -c1-4)" == "show" ]; then
         echo " ------ OS release check ------ " |tee -a /tmp/ir.log
	 ( rpm -q redhat-release 2>/dev/null || rpm -q centos-release 2>/dev/null ) | tee -a /tmp/ir.log
         if [ "$1" == "showall" ];then
		install_requirements $2 || echo "Error: System does not meet minimum requirements, check /tmp/ir.log for details"
         fi
         echo " ------ Applications check ------ " |tee -a /tmp/ir.log
         installed_applications  |tee -a /tmp/ir.log
         echo " ------ Dependencies check ------ " |tee -a /tmp/ir.log
	 #gen_rpm_dependencies(ostype|app|devel,devel|7|8)
         installed_dependencies "$(gen_rpm_dependencies $2 $3 )" |tee -a /tmp/ir.log
   else
      gen_rpm_dependencies $2 $3 $4
   fi
   FETCH=$1; [ -n "$3" ] && MAJOR=$3 && MINOR=$4
   fetch=$FETCH; #FETCH=$(echo $FETCH|cut -c1-5)
   if [ "$FETCH" = "fetch" ] || [ "$FETCH" = "bundle" ] || [ "$FETCH" = "install" ] ;then
	[ "$2" == "devel" ] && Devel=devel
	[ "$fetch" == "fetchlocal" ] && LOCAL=1
   	if [ "$FETCH" = "fetch" ] ;then
	  #gen_rpm_dependencies ${Devel:-'rhel'} 
	  #echo VERSION_ID=$VERSION_ID MINOR=$MINOR MAJOR=$MAJOR 1=$1 2=$2 3=$3 4=$4 LOCAL=$LOCAL Devel=$Devel ; read junk #debug
	  if [ ${VERSION_ID%.*} -eq 7 ] || [ ${MAJOR:-0} -eq 7 ]  ;then
		fetch_dependencies /tmp/r.lst /tmp/rpms/7
	  elif [ ${VERSION_ID%.*} -eq 8 ] || [ ${MAJOR:-0} -eq 8 ] ;then
		if [ $LOCAL -gt 0 ]; then
			fetch_dependencies_local /tmp/r.lst /tmp/rpms/8
	  		fetch_dependencies_local /tmp/r2.lst /tmp/rpms/8
		else
			fetch_dependencies /tmp/r.lst /tmp/rpms/8
	  		fetch_dependencies_local /tmp/r2.lst /tmp/rpms/8
		fi
	  fi
	  echo -n "Bundle dependencies? [Y|n]:"; read ans ; [ -z "$ans" ] && exec $0 bundle $2 $3 
   	elif [ "$FETCH" = "bundle" ] ;then
	  BUNDLENO=$MAJOR
	  if [ "$MAJOR" == "78" ];then
              MAJOR=7; gen_rpm_dependencies $2 7 
	      if [ "$MINOR" == "46" ];then
                MAJOR=8; gen_rpm_dependencies $2 8 4 
                         gen_rpm_dependencies $2 8 6 
	      elif [ "$MINOR" == "47" ];then
                MAJOR=8; gen_rpm_dependencies $2 8 4 
                         gen_rpm_dependencies $2 8 7 
	      elif [ "$MINOR" == "467" ];then
                MAJOR=8; gen_rpm_dependencies $2 8 4 
                         gen_rpm_dependencies $2 8 6 
                         gen_rpm_dependencies $2 8 7 
	      elif [ "$MINOR" == "4679" ];then
                MAJOR=8; gen_rpm_dependencies $2 8 4 
                         gen_rpm_dependencies $2 8 6 
                         gen_rpm_dependencies $2 8 7 
                         gen_rpm_dependencies $2 8 9 
              else
                MAJOR=8; gen_rpm_dependencies $2 8 ${MINOR:-$minor}
	      fi
          fi 
	  echo "Bundling rpms from /tmp/rpms"
	  sort -u /tmp/r3.lst >/tmp/r4.lst
	  >/tmp/T3.lst
	  while read n; do
            if [ -f /tmp/$n ] ;then
	      echo $n >>/tmp/T3.lst
	      printf "." #; sleep .1
	    else
	      printf "[/tmp/$n]"
            fi
          done </tmp/r4.lst
	  printf "\n"
	  [ -d /tmp/RPMS ] || mkdir -p /tmp/RPMS
	  $ECHO  tar -cvzf RPMS/dependencies-${2}-${BUNDLENO:-$major}-${MINOR:-$minor}.tgz -C /tmp -T /tmp/T3.lst
   	elif [ "$FETCH" = "install" ] ;then
	  DECODE=0
	  install_rpm_dependencies_now "$(gen_rpm_dependencies ${Devel:-'rhel'} ${VERSION_ID%.*}) "
	fi
   fi
fi

## rpm_dependencies.sh END ##
