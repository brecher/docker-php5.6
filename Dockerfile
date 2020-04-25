FROM php:5.6-apache

LABEL author="Willian Brecher"
LABEL email="willian.brecher@gmail.com"

RUN apt-get update && apt-get install -y apt-utils && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/ 

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# APACHE
RUN a2enmod rewrite

# ORACLE oci 
RUN mkdir /opt/oracle \
    && cd /opt/oracle     
    
ADD files/instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle
ADD files/instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle

# Install Oracle Instantclient
RUN  unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
    && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
    && rm -rf /opt/oracle/*.zip
    
ENV LD_LIBRARY_PATH  /opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH}
    
# Install Oracle extensions
RUN echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8-2.0.8 \ 
      && docker-php-ext-enable \
               oci8 \ 
       && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
       && docker-php-ext-install \
               pdo_oci 

# LDAP
RUN apt-get update && \
        apt-get install -y libldap2-dev && \
        rm -rf /var/lib/apt/lists/* && \
        docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
        docker-php-ext-install ldap

# PGSQL
RUN apt-get update && \
        apt-get install -y libpq-dev \
        && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
        && docker-php-ext-install pdo pdo_pgsql pgsql      

# MBSTRING
RUN docker-php-ext-install mbstring

# SOAP 
RUN apt-get install -y libxml2-dev && docker-php-ext-install soap

# CURL
RUN apt-get install -y libcurl4-gnutls-dev && docker-php-ext-install curl

# MEMCACHED
RUN apt-get update \
        && apt-get install -y libmemcached11 libmemcachedutil2 build-essential libmemcached-dev libz-dev \
        && apt-get install -y memcached \
        && pecl install memcached-2.2.0 \
        && echo extension=memcached.so >> /usr/local/etc/php/conf.d/memcached.ini     
  
# MEMCACHE
RUN yes|CFLAGS="-fgnu89-inline" pecl install memcache-3.0.8 \
        && docker-php-ext-enable memcache \
        && echo extension=memcache.so >> /usr/local/etc/php/conf.d/memcache.ini \
        && apt-get remove -y build-essential libmemcached-dev libz-dev && apt-get autoremove -y \
        && apt-get clean && rm -rf /tmp/pear 

# TIMESTAMP
RUN printf '[PHP]\ndate.timezone = "America/Sao_Paulo"\n' > /usr/local/etc/php/conf.d/tzone.ini

ENTRYPOINT /etc/init.d/memcached start && /bin/bash