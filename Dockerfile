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
        php7.0 \
        php7.0-bcmath \
        php7.0-curl \
        php7.0-dom \
        php7.0-mbstring \
        php7.0-sqlite \
        php7.0-zip \
        sqlite3 \
        wget

# Configure additional repositories
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install additional packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        yarn \
    && rm -rf /var/lib/apt/lists/*

# Clone and configure application code
RUN git clone https://github.com/sporchia/alttp_vt_randomizer.git /root/vt \
    && cd /root/vt \
    && git checkout 2102701007794594a4508ee13958fa47b98d5edc \
    && mv .env.example .env \
    && sed -i 's/DB_DATABASE=.*$/DB_DATABASE=\/root\/vt\/database\/randomizer.sqlite/g' .env

# Install application
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet \
    && php composer.phar install \
    && php artisan key:generate \
    && php artisan config:cache \
    && sqlite3 database/randomizer.sqlite ".databases" \
    && php artisan migrate \
    && sqlite3 database/randomizer.sqlite "ALTER TABLE seeds ADD patch_id INTEGER default 0" \
    && yarn \
    && ./node_modules/gulp/bin/gulp.js --production

# Expose default port
EXPOSE 8000
