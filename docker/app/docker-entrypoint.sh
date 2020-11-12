#!/bin/sh

set -e

# From the official PHP entrypoint script
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Enable Xdebug
[ "${ENABLE_XDEBUG}" -eq "1" ] &&
    docker-php-ext-enable xdebug &&
    export PHP_IDE_CONFIG="serverName=${WEB_HOST}" &&
    touch /var/log/xdebug.log &&
    chown "${WEB_USER}":"${WEB_GROUP}" /var/log/xdebug.log &&
    chmod 644 /var/log/xdebug.log &&
    echo "Xdebug is enabled"

# Enable sSMTP
if [ "${ENABLE_SSMTP}" -eq "1" ]; then
    apk upgrade && apk add ssmtp
    cp ./docker/app/smtp/ssmtp.conf /etc/ssmtp && cp ./docker/app/smtp/revaliases /etc/ssmtp

    [ -n "${EMAIL_ADDRESS}" ] && sed -i "s/!!!email_address!!!/${EMAIL_ADDRESS}/" /etc/ssmtp/ssmtp.conf
    [ -n "${SMTP_HOST}" ] && sed -i "s/!!!smtp_host!!!/${SMTP_HOST}/" /etc/ssmtp/ssmtp.conf
    [ -n "${SMTP_PORT}" ] && sed -i "s/!!!smtp_port!!!/${SMTP_PORT}/" /etc/ssmtp/ssmtp.conf
    [ -n "${EMAIL_USERNAME}" ] && sed -i "s/!!!email_username!!!/${EMAIL_USERNAME}/" /etc/ssmtp/ssmtp.conf
    [ -n "${EMAIL_PASSWORD}" ] && sed -i "s/!!!email_password!!!/${EMAIL_PASSWORD}/" /etc/ssmtp/ssmtp.conf

    [ -n "${EMAIL_ADDRESS}" ] && sed -i "s/!!!email_address!!!/${EMAIL_ADDRESS}/" /etc/ssmtp/revaliases
    [ -n "${SMTP_HOST}" ] && sed -i "s/!!!smtp_host!!!/${SMTP_HOST}/" /etc/ssmtp/revaliases
    [ -n "${SMTP_PORT}" ] && sed -i "s/!!!smtp_port!!!/${SMTP_PORT}/" /etc/ssmtp/revaliases

    echo "sSMTP is enabled"
fi

# Configure Composer
[ -n "${COMPOSER_GITHUB_TOKEN}" ] &&
    composer config --global github-oauth.github.com "${COMPOSER_GITHUB_TOKEN}"

[ -n "${COMPOSER_BITBUCKET_KEY}" ] &&
    [ -n "${COMPOSER_BITBUCKET_SECRET}" ] &&
    composer config --global bitbucket-oauth.bitbucket.org "${COMPOSER_BITBUCKET_KEY}" "${COMPOSER_BITBUCKET_SECRET}"

[ -n "${COMPOSER_MAGENTO_USERNAME}" ] &&
    [ -n "${COMPOSER_MAGENTO_PASSWORD}" ] &&
    composer config --global http-basic.repo.magento.com "${COMPOSER_MAGENTO_USERNAME}" "${COMPOSER_MAGENTO_PASSWORD}"

composer self-update "${COMPOSER_VERSION}"

# From the official PHP entrypoint script
exec "$@"
