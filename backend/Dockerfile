FROM php:8.3-cli

# Extensions : PostgreSQL (base Neon), zip, bcmath
RUN apt-get update \
 && apt-get install -y --no-install-recommends git unzip libpq-dev libzip-dev \
 && docker-php-ext-install pdo_pgsql zip bcmath \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Dépendances PHP (couche mise en cache tant que composer.lock ne change pas)
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --optimize-autoloader

COPY . .
RUN composer dump-autoload --optimize --no-dev --no-scripts \
 && php artisan package:discover --ansi \
 && mkdir -p storage/logs storage/framework/cache/data storage/framework/sessions storage/framework/views bootstrap/cache \
 && chmod -R 777 storage bootstrap/cache

ENV PORT=10000 \
    PHP_CLI_SERVER_WORKERS=4

# Au démarrage : met la base à jour, crée le menu / les comptes s'ils n'existent pas, puis lance le serveur
CMD ["sh", "-c", "php artisan migrate --force && php artisan db:seed --class=ShawarmaSeeder --force && php artisan serve --host=0.0.0.0 --port=${PORT}"]
