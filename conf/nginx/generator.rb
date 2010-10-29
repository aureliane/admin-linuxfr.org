#!/usr/bin/env ruby
# Generate the nginx configuration for a vhost

if ARGV.empty?
  $stderr.puts "Usage: ./path/to/generator.rb env > sites-available/vhost"
  $stderr.puts "       where env is alpha or production"
  exit -1
end

case env = ARGV.first
when "alpha"
  vserver = "alpha"
  user    = "alpha"
  fqdn    = "alpha.linuxfr.org"

when "production"
  vserver = "web"
  user    = "linuxfr"
  fqdn    = "linuxfr.org"
end

# Gruikkkkk
puts DATA.read.gsub(/@@(\w+)@@/) { |var| eval $1 }

__END__
# Please do not edit: this file was generated by conf/nginx/generator.rb

upstream linuxfr-frontend {
    server unix:/var/www/@@user@@/@@env@@/shared/tmp/sockets/@@env@@.sock fail_timeout=0;
}

upstream board-frontend {
    server unix:/var/www/@@user@@/board/board.sock;
}


# HTTP
server {
    listen 80;
    server_name @@fqdn@@;
    access_log /var/log/nginx/@@user@@.access.log;
    root /var/www/@@user@@/@@env@@/current/public;

    if ($cookie_https = '1') {
        rewrite ^(.*)$ https://@@fqdn@@$1 break;
    }

    include /etc/nginx/partials/legacy;
    include /etc/nginx/partials/rails;
}

# HTTPS
server {
    listen 443;
    server_name @@fqdn@@;
    access_log /var/log/nginx/@@user@@.access.log;
    root /var/www/@@user@@/@@env@@/current/public;

    # SSL
    ssl on;
    ssl_certificate server.crt;
    ssl_certificate_key server.key;

    include /etc/nginx/partials/legacy;
    include /etc/nginx/partials/rails;
}

# No-www
server {
    listen 80;
    server_name www.@@fqdn@@;
    rewrite ^/(.*) http://@@fqdn@@/$1 permanent;
}
server {
    listen 443;
    server_name www.@@fqdn@@;
    ssl on;
    ssl_certificate server.crt;
    ssl_certificate_key server.key;
    rewrite ^/(.*) https://@@fqdn@@/$1 permanent;
}
