FROM php:8.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends ghostscript
RUN apt-get install -y --no-install-recommends \
  libavif-dev \
  libfreetype6-dev \
  libicu-dev \
  libjpeg-dev \
  libmagickwand-dev \
  libpng-dev \
  libwebp-dev \
  libzip-dev
RUN docker-php-ext-configure gd \
  --with-avif \
  --with-freetype \
  --with-jpeg \
  --with-webp
RUN docker-php-ext-install -j "$(nproc)" \
  bcmath \
  exif \
  gd \
  intl \
  mysqli \
  zip
RUN curl -fL -o imagick.tgz 'https://pecl.php.net/get/imagick-3.7.0.tgz' && \
  tar --extract --directory /tmp --file imagick.tgz imagick-3.7.0 && \
  rm imagick.tgz && \
  docker-php-ext-install /tmp/imagick-3.7.0 && \
  rm -rf imagick.tgz /tmp/imagick-3.7.0
RUN set -eux; docker-php-ext-enable opcache; \
  { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN a2enmod rewrite expires
RUN a2enmod remoteip

COPY . /usr/src/wordpress/
RUN set -eux; \
  { \
    echo '# BEGIN WordPress'; \
		echo ''; \
		echo 'RewriteEngine On'; \
		echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
		echo 'RewriteBase /'; \
		echo 'RewriteRule ^index\.php$ - [L]'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
		echo 'RewriteRule . /index.php [L]'; \
		echo ''; \
		echo '# END WordPress'; \
  } > /usr/src/wordpress/.htaccess
RUN chown -R www-data:www-data /usr/src/wordpress

VOLUME /var/www/html
COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
