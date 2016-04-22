FROM ubuntu:wily
MAINTAINER Niels Maseberg <nielsmaseberg@hotmail.com>

# Load and Install updates
RUN apt-get update && apt-get upgrade -y

# Update index and install dependencies
RUN apt-get update && \
        apt-get install -y nginx php5-fpm php5-cli php5-intl php5-mysql php5-sqlite php5-curl \
        htop npm nodejs ruby curl supervisor git wget vim

# Update NPM
RUN npm update

# Set Node as executable
RUN ln -s `which nodejs` /usr/bin/node

# PHP conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
RUN sed -i "s/;daemonize = yes/daemonize = no/" /etc/php5/fpm/php-fpm.conf
ADD ./php-fpm.conf /etc/php5/fpm/php-fpm.conf

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer

# Install PHPUnit
RUN wget https://phar.phpunit.de/phpunit.phar \
        && chmod +x phpunit.phar \
        && mv phpunit.phar /usr/local/bin/phpunit

# nginx conf
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
ADD ./vhost.conf /etc/nginx/sites-available/default

# Supervisor conf
ADD ./supervisord.conf /etc/supervisor/supervisord.conf

# Create Application folder
RUN mkdir -p /var/www/application
RUN mkdir -p /var/log/application
RUN chown www-data:www-data /var/www/application
RUN chown www-data:www-data /var/log/application

# forward request and error logs to docker log collector
RUN ln -sf /tmp/supervisord.log /var/log/nginx/access.log \
    && ln -sf /tmp/supervisord.log /var/log/nginx/error.log

# Define Volumes
VOLUME /var/www/application /root/.ssh

# Set Workdir
WORKDIR /var/www/application

# EXPOSE PORTS
EXPOSE 80

# Start
CMD ["supervisord", "--nodaemon"]