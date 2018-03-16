FROM andreaskoch/dockerized-magento-php

MAINTAINER christopher.queen@gmail.com

# Configure
COPY php.ini /usr/local/etc/php/php.ini
COPY ext-zend.ini /usr/local/etc/php/conf.d/docker-php-ext-zend.ini

# Install vim
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install vim


# Add IonCube Loader Functions
RUN cd /tmp \
    && curl -o ioncube.tar.gz http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvvzf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_5.6.so /usr/local/lib/php/extensions/* \
    && rm -Rf ioncube.tar.gz ioncube \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/ioncube_loader_lin_5.6.so" > /usr/local/etc/php/conf.d/00_docker-php-ext-ioncube_loader_lin_5.6.ini
