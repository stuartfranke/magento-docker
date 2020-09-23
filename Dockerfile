FROM php:7.3.22-fpm-alpine3.12

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV USER_DIRECTORY "/root"
ENV NGINX_GROUP "www-data"
ENV NGINX_USER "www-data"
ENV WEB_ROOT "/www"

RUN apk update --progress --purge \
    # Install required packages
    # @todo version lock packages
    && apk add --latest --progress --purge \
        autoconf \
        bash \
        curl \
        dos2unix \
        freetype-dev \
        g++ \
        gcc \
        git \
        gnupg \
        gzip \
        icu-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libxslt-dev \
        libzip-dev \
        lsof \
        make \
        sed \
        tar \
        unzip \
        vim \
        wget \
    # Install PHP extensions @todo 1. version lock extensions 2. move dev specific extensions to dev environment
    && docker-php-ext-install \
        bcmath \
        intl \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && pecl install \
        apcu \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install gd \
    && docker-php-ext-enable \
        apcu

# Copy PHP config file
COPY ./docker/app/etc/php.ini /usr/local/etc/php

# Install Composer
COPY ./docker/app/scripts/composer-installer.sh ${USER_DIRECTORY}/composer-installer

RUN chmod +x ${USER_DIRECTORY}/composer-installer \
    && dos2unix ${USER_DIRECTORY}/composer-installer \
    && ${USER_DIRECTORY}/composer-installer \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && echo "{}" > ${USER_DIRECTORY}/.composer/composer.json \
    && rm ${USER_DIRECTORY}/composer-installer

# Copy project files
COPY --chown=${NGINX_USER}:${NGINX_GROUP} . ${WEB_ROOT}/

WORKDIR ${WEB_ROOT}
