# Docker-Nagios

Pre installed and pre-configured Nagios Docker image

special thanks to Jason Rivers for the work on nagios ubuntu base image

    Installed :
        - NagiosCore v4
        - NagiosPlugins
        - Nagios NRPE
        - Nagios Graph
        - willixix Nagios Plugins
        - JasonRivers Nagios Plugins
        - justintime Nagios Plugins
        - Nuvola Front End
        - Lilac Configuration Front End

    Default Env:
      - NAGIOS_HOME : Nagios install directory (/opt/nagios)
      - NAGIOS_USER : Nagios User (nagios)
      - NAGIOS_GROUP : Nagios Group (nagios)
      - NAGIOSADMIN_USER : Nagios WebUI User (nagiosadmin)
      - NAGIOSADMIN_PASS : Nagios WebUI Password (nagiosadmin)
      - NAGIOS_CONFIG_FILE : Nagios Base Config File (/opt/nagios/etc/nagios.cfg)

    Volumes Access:
      - Nagios configuration : /opt/nagios/etc
      - Nagios Logs : /opt/nagios/var 
      - Nagios Plugins : /opt/nagios/libexec
      - Apache Logs : /var/log/httpd

Run Docker With this: docker run --privileged --name nagios -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 80:80 -d protheus/nagios:latest

After run docker container go to : 
          http://<IP/Hostname>/nagios/lilac/install.php
to init the configuration and MariaDB

    Setup with this: 
          - Host/Port:  localhost / 3306
          - Username:   lilac
          - Password:   lilac
          - Database:   lilac
      
    After this Create and Run Import Job with this:
          - Main Configuration File: /opt/nagios/etc/nagios.cfg
          - CGI Configuration File:  /opt/nagios/etc/cgi.cfg
          - Resource File: /opt/nagios/etc/resource.cfg


And Configure your devices, export to Nagios .

Go to:  http://<IP/Hostname>/nagios

... Enjoy ... :-)






