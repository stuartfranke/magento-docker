#!/bin/sh

set -e

# From the official PHP entrypoint script
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Setup shell profile and aliases
touch "${USER_DIRECTORY}"/.profile &&
    echo \ '. /etc/profile;' \  >"${USER_DIRECTORY}"/.profile &&
    echo '# Alias' >>"${USER_DIRECTORY}"/.profile &&
    echo 'if [ -f '"${USER_DIRECTORY}"'/.ash_aliases ]; then . '"${USER_DIRECTORY}"'/.ash_aliases; fi' >>"${USER_DIRECTORY}"/.profile &&
    touch "${USER_DIRECTORY}"/.ash_aliases &&
    echo "Profile and Alias files created"

if [ "${UPDATE_UID_GID}" -eq "1" ]; then
    echo "Updating www-data uid and gid"

    DOCKER_UID=$(stat -c "%u" "${WEB_ROOT}")
    DOCKER_GID=$(stat -c "%g" "${WEB_ROOT}")

    INCUMBENT_USER=$(getent passwd "${DOCKER_UID}" | cut -d: -f1)
    INCUMBENT_GROUP=$(getent group "${DOCKER_GID}" | cut -d: -f1)

    echo "Docker: uid = ${DOCKER_UID}, gid = ${DOCKER_GID}"
    echo "Incumbent: user = ${INCUMBENT_USER}, group = ${INCUMBENT_GROUP}"

    # Once we've established the ids and incumbent ids then we need to free them
    # up (if necessary) and then make the change to www-data.
    apk update &&
        apk --no-cache add shadow

    [ -n "${INCUMBENT_USER}" ] && usermod -u 99"${DOCKER_UID}" "${INCUMBENT_USER}"
    usermod -u "${DOCKER_UID}" www-data

    [ -n "${INCUMBENT_GROUP}" ] && groupmod -g 99"${DOCKER_GID}" "${INCUMBENT_GROUP}"
    groupmod -g "${DOCKER_GID}" www-data
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

# Enable OpenSSH Client
[ "${ENABLE_OPENSSH_CLIENT}" -eq "1" ] &&
    apk update &&
    apk add openssh-client &&
    echo "OpenSSH Client enabled"

# Enable sSMTP
if [ "${ENABLE_SSMTP}" -eq "1" ]; then
    apk update &&
        apk add ssmtp

    cp ./docker/app/smtp/ssmtp.conf /etc/ssmtp &&
        cp ./docker/app/smtp/revaliases /etc/ssmtp

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

# Enable Xdebug
[ "${ENABLE_XDEBUG}" -eq "1" ] &&
    docker-php-ext-enable xdebug &&
    export PHP_IDE_CONFIG="serverName=${WEB_HOST}" &&
    touch /var/log/xdebug.log &&
    chown "${WEB_USER}":"${WEB_GROUP}" /var/log/xdebug.log &&
    chmod 644 /var/log/xdebug.log &&
    echo 'alias exd="mv /usr/local/etc/php/conf.d/xdebug.ini.dis /usr/local/etc/php/conf.d/xdebug.ini && echo '"'Xdebug enabled'"'"' >>"${USER_DIRECTORY}"/.ash_aliases &&
    echo 'alias dxd="mv /usr/local/etc/php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini.dis && echo '"'Xdebug disabled'"'"' >>"${USER_DIRECTORY}"/.ash_aliases &&
    echo "Xdebug is enabled"

# From the official PHP entrypoint script
exec "$@"
