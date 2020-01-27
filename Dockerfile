# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ekindomb <marvin@42.fr>                    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2019/11/19 13:34:09 by ekindomb          #+#    #+#              #
#    Updated: 2019/12/03 14:32:57 by ekindomb         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#create base image
FROM debian:buster

# update system
RUN apt-get -y update
RUN	apt-get -y upgrade

# Install MariaDb replace mysql
RUN echo ' \e[36m\e[1m=== Installing MariaDB ===\e[0m' && \
	apt-get install -y mariadb-server mariadb-client

# Install PHP
RUN echo ' \e[36m\e[1m=== Installing PHP ===\e[0m'
RUN	DEBIAN_FRONTEND=noninteractive apt-get install -y \ 
	php7.3 php-fpm php-cgi php-mysqli php-pear php-mbstring php-gettext php-common php-phpseclib php-mysql

# Install NGINX
RUN echo ' \e[36m\e[1m=== Installing NGINX ===\e[0m'
RUN apt-get install -y nginx

# Install tools
RUN echo ' \e[36m\e[1m=== Installing tools ===\e[0m'
RUN apt-get -y install wget unzip vim curl ca-certificates libssl1.1 

# Install SSL
RUN echo ' \e[36m\e[1m=== Installing SSL ===\e[0m'
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048\
	-subj '/C=FR/ST=75/L=Paris/O=42/CN=ekindomb'\
	-keyout /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt

RUN echo ' \e[36m\e[1m===copying wordpress content ===\e[0m'
RUN mkdir /home/root && mkdir /home/root/wordpress
COPY srcs/wordpress ./home/root/wordpress
RUN chown -R www-data:www-data /home/root/wordpress/*
RUN chmod -R 755 /home/root/wordpress/*
COPY srcs/nginx.conf /home/root/default
RUN service nginx reload
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
RUN mv /home/root/default /etc/nginx/sites-available/default
COPY srcs/sqlconf.sql /home/root/

# Install PhpMyAdmin
RUN echo ' \e[36m\e[1m===Install PHPMyAdmin ===\e[0m'
RUN mkdir /home/root/phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.zip
RUN unzip phpMyAdmin-4.9.0.1-all-languages.zip 
RUN cp -r phpMyAdmin-4.9.0.1-all-languages/* /home/root/phpmyadmin/
RUN chmod -R 755 /home/root/phpmyadmin
RUN chown -R www-data:www-data /home/root/phpmyadmin /home/root/
RUN cd /home/root/ && echo "<?php phpinfo(); ?>" > index.php

# Starting Web Service
RUN echo ' \e[36m\e[1m===Starting Service ===\e[0m'
RUN service mysql start && mysql -uroot -proot mysql < "/home/root/sqlconf.sql" 
COPY srcs/start.sh /start.sh
RUN chmod 777 /start.sh
# Ports
EXPOSE 80 443 

ENTRYPOINT "./start.sh"
