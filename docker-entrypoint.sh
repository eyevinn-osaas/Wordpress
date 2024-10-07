#!/usr/bin/env bash
set -Eeuo pipefail
if [ ! -e index.php ] && [ ! -e wp-includes/version.php ]; then
  chown "www-data:www-data" .
  sourceTarArgs=(
    --create
    --file -
    --exclude docker-entrypoint.sh
    --directory /usr/src/wordpress
    --owner "www-data" --group "www-data"
  )
  targetTarArgs=(
    --extract
    --file -
  )
  for contentPath in \
    /usr/src/wordpress/.htaccess \
    /usr/src/wordpress/wp-content/*/*/ \
  ; do
    contentPath="${contentPath%/}"
    [ -e "$contentPath" ] || continue
    contentPath="${contentPath#/usr/src/wordpress/}"
    if [ -e "$PWD/$contentPath" ]; then
      echo >&2 "WARNING: '$PWD/$contentPath' exists! (not copying the WordPress version)"
      sourceTarArgs+=( --exclude "./$contentPath" )
    fi
  done
  tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"
  echo >&2 "Complete! WordPress has been successfully copied to $PWD"
fi

awk '
  /put your unique phrase here/ {
		cmd = "head -c1m /dev/urandom | sha1sum | cut -d\\  -f1"
		cmd | getline str
		close(cmd)
		gsub("put your unique phrase here", str)
	}
	{ print }
' "wp-config-docker.php" > wp-config.php
chown "www-data:www-data" wp-config.php
sed -e 's/Listen 80/Listen 8080/' < /etc/apache2/ports.conf > /etc/apache2/ports.conf.new
mv /etc/apache2/ports.conf.new /etc/apache2/ports.conf
sed -e 's/VirtualHost \*:80/VirtualHost \*:8080/' < /etc/apache2/sites-available/000-default.conf > /etc/apache2/sites-available/000-default.conf.new
mv /etc/apache2/sites-available/000-default.conf.new /etc/apache2/sites-available/000-default.conf
exec "$@"
