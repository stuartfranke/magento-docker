FROM php:7.4.16-fpm-alpine3.13

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="${PATH}" \
    WEB_GROUP=www-data \
    WEB_ROOT=/www \
    WEB_USER=www-data \
    USER_DIRECTORY=/root

RUN apk update --purge \
    # Install required packages
    # @todo version lock packages
    && apk add --latest --purge \
        autoconf \
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
        openssl-dev \
        sed \
        tar \
        unzip \
        vim \
        wget \
    # Install PHP extensions @todo version lock extensions
    && docker-php-ext-install \
        bcmath \
        intl \
        opcache \
        pcntl \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && pecl install \
        xdebug-2.9.8 \
        apcu \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install gd \
    && docker-php-ext-enable apcu

# Copy PHP config files
COPY ./docker/app/conf.d/* /usr/local/etc/php/conf.d/

COPY ./docker/app/php-fpm.d/* /usr/local/etc/php-fpm.d/

COPY ./docker/app/php.ini /usr/local/etc/php

# Install Composer
COPY ./docker/app/composer-installer.sh ${USER_DIRECTORY}/composer-installer

RUN chmod +x ${USER_DIRECTORY}/composer-installer \
    && dos2unix ${USER_DIRECTORY}/composer-installer \
    && ${USER_DIRECTORY}/composer-installer \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && echo "{}" > ${USER_DIRECTORY}/.composer/composer.json \
    && rm ${USER_DIRECTORY}/composer-installer

# Copy project files
COPY --chown=${WEB_USER}:${WEB_GROUP} . ${WEB_ROOT}/

WORKDIR ${WEB_ROOT}

# Copy entrypoint
COPY ./docker/app/docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && dos2unix /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["php-fpm"]
