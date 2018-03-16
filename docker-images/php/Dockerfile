FROM andreaskoch/dockerized-magento-php

MAINTAINER christopher.queen@gmail.com

# Configure
COPY php.ini /usr/local/etc/php/php.ini
COPY ext-zend.ini /usr/local/etc/php/conf.d/docker-php-ext-zend.ini

#COPY sendmail_config.sh /bin/sendmail_config.sh

# Add crontab file in the cron directory
#COPY magento-cron.txt /etc/cron.d/magento-cron.txt

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Install vim , Cron and update crontab for root
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install vim \
 && apt-get -y install cron
 #&& cat /etc/cron.d/magento-cron.txt | crontab -


# Add IonCube Loader Functions
RUN cd /tmp \
    && curl -o ioncube.tar.gz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvvzf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_5.6.so /usr/local/lib/php/extensions/* \
    && rm -Rf ioncube.tar.gz ioncube \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/ioncube_loader_lin_5.6.so" > /usr/local/etc/php/conf.d/00_docker-php-ext-ioncube_loader_lin_5.6.ini

#RUN sed -i -e "s#;sendmail_path =#sendmail_path = /usr/sbin/sendmail -t -i#g"  \
#     /usr/local/etc/php/php.ini

# Run the sendmail_config.sh file
#RUN chmod +x /bin/sendmail_config.sh \
# && sh /bin/sendmail_config.sh

# Run the cron command on container startup
#RUN /etc/init.d/cron restart
#&& tail -f /var/log/cron.log
