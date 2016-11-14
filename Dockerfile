# Nagios Distrib
FROM protheus/centos-nagios:latest
MAINTAINER Protheus <sauvage.jeff@gmail.com>

ENV NAGIOS_HOME			/opt/nagios
ENV NAGIOS_GRAPH		/opt/nagiosgraph
ENV NAGIOS_USER			nagios
ENV NAGIOS_GROUP		nagios
ENV NAGIOS_CMDUSER		nagios
ENV NAGIOS_CMDGROUP		nagios
ENV NAGIOSADMIN_USER	nagiosadmin
ENV NAGIOSADMIN_PASS	nagiosadmin
ENV APACHE_RUN_USER		nagios
ENV APACHE_RUN_GROUP	nagios
ENV NAGIOS_TIMEZONE		UTC
ENV NAGIOS_CONFIG_FILE	${NAGIOS_HOME}/etc/nagios.cfg
ENV NAGIOS_CGI_DIR			${NAGIOS_HOME}/sbin
ENV NG_WWW_DIR			${NAGIOS_HOME}/share/nagiosgraph
ENV NG_CGI_URL			/nagiosgraph/cgi-bin


# make temporary Installation directory
RUN mkdir /tmp/install

# Create Users and Groups
RUN	( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )				&&	\
	( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN	( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )	&&	\
	( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

# Install Perl modules
RUN cpanm Module::Build
RUN cpanm Nagios::Config
	
# install Nagios Core	
RUN	cd /tmp/install						&&	\
	git clone https://github.com/NagiosEnterprises/nagioscore.git		&&	\
	cd nagioscore						&&	\
	git checkout master				&&	\
	./configure							\
		--prefix=${NAGIOS_HOME}					\
		--exec-prefix=${NAGIOS_HOME}				\
		--enable-event-broker					\
		--with-nagios-command-user=${NAGIOS_CMDUSER}		\
		--with-command-group=${NAGIOS_CMDGROUP}			\
		--with-nagios-user=${NAGIOS_USER}			\
		--with-nagios-group=${NAGIOS_GROUP}		&&	\
	make all						&&	\
	make install-init 	&& \
	make install						&&	\
	make install-config					&&	\
	make install-commandmode				&&	\
	make install-webconf			&& \
	make clean

# Install Nagios Plugins
RUN	cd /tmp/install						&&	\
	git clone https://github.com/nagios-plugins/nagios-plugins.git		&&	\
	cd nagios-plugins					&&	\
	git checkout master				&&	\
	./tools/setup						&&	\
	./configure							\
		--prefix=${NAGIOS_HOME}				&&	\
	make							&&	\
	make install						&&	\
	make clean	&&	\
	mkdir -p /usr/lib/nagios/plugins	&&	\
	ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins	
	
	
# Install Nagios NRPE
RUN	cd /tmp/install						&&	\
	git clone https://github.com/NagiosEnterprises/nrpe.git	&&	\
	cd nrpe							&&	\
	git checkout master					&&	\
	./configure							\
		--with-ssl=/usr/bin/openssl				\
		--with-ssl-lib=/usr/lib64	&&	\
	make check_nrpe						&&	\
	cp src/check_nrpe ${NAGIOS_HOME}/libexec/		&&	\
	make clean


# Install Nagios Graph
RUN	cd /tmp/install										&&	\
	git clone git://git.code.sf.net/p/nagiosgraph/git nagiosgraph				&&	\
	cd nagiosgraph										&&	\
	./install.pl --install										\
		--prefix ${NAGIOS_GRAPH}								\
		--nagios-user ${NAGIOS_USER}								\
		--www-user ${NAGIOS_USER}								\
		--nagios-perfdata-file ${NAGIOS_HOME}/var/perfdata.log					\
		--nagios-cgi-url ${NG_CGI_URL}							&&	\
	cp share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi

RUN	cat ${NAGIOS_GRAPH}/etc/nagiosgraph-nagios.cfg >> ${NAGIOS_HOME}/etc/nagios.cfg && \
	cat ${NAGIOS_GRAPH}/etc/nagiosgraph-commands.cfg >> ${NAGIOS_HOME}/etc/objects/commands.cfg && \
	cp  ${NAGIOS_GRAPH}/etc/nagiosgraph-apache.conf /etc/httpd/conf.d/nagiosgraph.conf && \
	echo define service \{ >> ${NAGIOS_HOME}/etc/objects/templates.cfg &&\
	echo name nagiosgraph >> ${NAGIOS_HOME}/etc/objects/templates.cfg &&\
	echo action_url  ${NG_CGI_URL}/show.cgi?host=\$HOSTNAME\$\&service=\$SERVICEDESC\$ >> ${NAGIOS_HOME}/etc/objects/templates.cfg &&\
	echo register 0 >> ${NAGIOS_HOME}/etc/objects/templates.cfg &&\
	echo } >> ${NAGIOS_HOME}/etc/objects/templates.cfg &&\
	sed -i "s,local-service,local-service\,nagiosgraph," ${NAGIOS_HOME}/etc/objects/localhost.cfg


## Configure nagiosgraph in apache
RUN echo  $'\n\
# enable nagiosgraph CGI scripts \n\
ScriptAlias '${NG_CGI_URL}$' "'${NAGIOS_GRAPH}$'/cgi" \n\
<Directory "'${NAGIOS_GRAPH}$'/cgi"> \n\
   Options ExecCGI \n\
   AllowOverride None \n\
   Order allow,deny \n\
   Allow from all \n\
   AuthName "Nagios Access" \n\
   AuthType Basic \n\
   AuthUserFile '${NAGIOS_HOME}$'/etc/htpasswd.users \n\
   Require valid-user \n\
</Directory> \n\
# enable nagiosgraph CSS and JavaScript \n\
Alias /nagiosgraph "'${NAGIOS_HOME}$'/share/nagiosgraph" \n\
<Directory "'${NAGIOS_HOME}$'/share/nagiosgraph"> \n\
   Options None \n\
   AllowOverride None \n\
   Order allow,deny \n\
   Allow from all \n\
</Directory> \n\
 '> /etc/httpd/conf.d/nagiosgraph.conf








	
	
# Install other Nagios Plugins
RUN cd /tmp/install && \
	git clone http://github.com/willixix/naglio-plugins.git WL-Nagios-Plugins && \
	git clone https://github.com/JasonRivers/nagios-plugins.git JR-Nagios-Plugins && \
	git clone https://github.com/justintime/nagios-plugins.git JE-Nagios-Plugins && \
	cp ./WL-Nagios-Plugins/*.pl ${NAGIOS_HOME}/libexec/ && \
	cp ./WL-Nagios-Plugins/*.pm ${NAGIOS_HOME}/libexec/ && \
	cp ./JR-Nagios-Plugins/check_* ${NAGIOS_HOME}/libexec/ && \
	cp ./JE-Nagios-Plugins/check_mem/check_mem.pl ${NAGIOS_HOME}/libexec/


	
# Add Mibs Files
#RUN	mkdir -p /usr/share/snmp/mibs								&&	\
#	mkdir -p ${NAGIOS_HOME}/etc/conf.d							&&	\
#	mkdir -p ${NAGIOS_HOME}/etc/monitor							&&	\
#	mkdir -p ${NAGIOS_HOME}/.ssh								&&	\
#	chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/.ssh				&&	\
#	chmod 700 ${NAGIOS_HOME}/.ssh								&&	\
#	chmod 0755 /usr/share/snmp/mibs								&&	\
#	touch /usr/share/snmp/mibs/.foo								&&	\
#	ln -s /usr/share/snmp/mibs ${NAGIOS_HOME}/libexec/mibs					&&	\
#	ln -s ${NAGIOS_HOME}/bin/nagios /usr/local/bin/nagios					&&	\
#ADD http://archive.ubuntu.com/ubuntu/pool/multiverse/s/snmp-mibs-downloader/snmp-mibs-downloader_1.1.tar.gz /tmp/install/
	
	
#RUN	cd /tmp/install  &&\
#	tar -zxf ./snmp-mibs-downloader_1.1.tar.gz &&\
#	cd snmp-mibs-downloader-1.1  &&\
#	mkdir /etc/snmp-mibs-downloader &&\
#	mkdir /usr/share/doc/mibrfcs  && \
#	mkdir /usr/share/doc/mibiana && \
#	mkdir /usr/share/mibs &&\
#	make install &&\
	


 
# Set Passwd
RUN htpasswd -bc ${NAGIOS_HOME}/etc/htpasswd.users ${NAGIOSADMIN_USER} ${NAGIOSADMIN_PASS}	
	

RUN  systemctl enable httpd
RUN  systemctl enable nagios



EXPOSE 80

CMD ["/usr/sbin/init"]

