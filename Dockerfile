FROM php:5.6-apache

LABEL author="Willian Brecher"
LABEL email="willian.brecher@gmail.com"

RUN apt-get update && apt-get install -y apt-utils && apt-get install -qqy git unzip libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libaio1 libaio-dev wget && apt-get clean autoclean && apt-get autoremove --yes &&  rm -rf /var/lib/{apt,dpkg,cache,log}/ 

# COMPOSER
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# HABILITA MODO REQRITE NO APACHE
RUN a2enmod rewrite

# DRIVER ORACLE
RUN mkdir /opt/oracle
    
ADD files/oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb /opt/oracle
ADD files/oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb /opt/oracle

RUN dpkg -i /opt/oracle/oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb \
        && dpkg -i /opt/oracle/oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb

RUN export LD_LIBRARY_PATH=/usr/lib/oracle/12.1/client64/lib/
RUN export ORACLE_HOME=/usr/lib/oracle/12.1/client64/

ENV LD_LIBRARY_PATH /usr/lib/oracle/12.1/client64/lib/
ENV ORACLE_HOME /usr/lib/oracle/12.1/client64/

# OCI8
RUN echo "instantclient,/usr/lib/oracle/12.1/client64/lib" | pecl install oci8-1.4.10 \ 
      && sh -c "echo /usr/lib/oracle/12.1/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf" \
      && ldconfig \
      && docker-php-ext-configure oci8 \
      && docker-php-ext-enable oci8 \
      && rm -rf /opt/oracle

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
        && apt-get remove -y build-essential libmemcached-dev libz-dev && apt-get autoremove -y \
        && apt-get clean && rm -rf /tmp/pear 

# XDEBUG
RUN curl -fsSL 'https://xdebug.org/files/xdebug-2.4.0.tgz' -o xdebug.tar.gz \
    && mkdir -p xdebug \
    && tar -xf xdebug.tar.gz -C xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && ( \
    cd xdebug \
    && phpize \
    && ./configure --enable-xdebug \
    && make -j$(nproc) \
    && make install \
    ) \
    && rm -r xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.remote_enable=1" >> /usr/local/etc/php/php.ini

EXPOSE 9000    

# JDK
RUN mkdir /usr/share/man/man1/ && apt-get install -y default-jdk

# TIMESTAMP
RUN printf '[PHP]\ndate.timezone = "America/Sao_Paulo"\n' > /usr/local/etc/php/conf.d/tzone.ini

# INICIAR AUTOMATICAMENTE OS SERVIÇOS
CMD /etc/init.d/memcached start && /etc/init.d/apache2 start ; while true ; do sleep 100; done;