# Set the base image
FROM debian:stretch-slim

# Dockerfile author / maintainer 
MAINTAINER qwertymodo <qwertymodo@gmail.com>

WORKDIR /root/vt

CMD php artisan serve --host 0.0.0.0

# Update application repository list and install apt-utils
RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils

# Install required packages 
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        libzip4 \
        sqlite3 \
        wget

# Configure additional repositories
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && curl -sS https://packages.sury.org/php/apt.gpg | apt-key add - \
    && echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list

# Install additional packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        g++ \
        libpng-dev \
        make \
        nodejs \
        php7.2 \
        php7.2-bcmath \
        php7.2-curl \
        php7.2-dom \
        php7.2-mbstring \
        php7.2-sqlite \
        php7.2-zip \
    && rm -rf /var/lib/apt/lists/*

# Clone and configure application code
RUN git clone https://github.com/sporchia/alttp_vt_randomizer.git -b v30.3 --single-branch /root/vt \
    && mv .env.example .env \
    && sed -i 's/DB_DATABASE=.*$/DB_DATABASE=\/root\/vt\/database\/randomizer.sqlite/g' .env

# Install application
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet \
    && php composer.phar install \
    && php artisan key:generate \
    && php artisan config:cache \
    && sqlite3 database/randomizer.sqlite ".databases" \
    && php artisan migrate \
    && php artisan alttp:updatebuildrecord \
    && php artisan vue-i18n:generate \
    && npm install --unsafe-perm \
    && npm run production

# Expose default port
EXPOSE 8000
