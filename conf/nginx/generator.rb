#!/usr/bin/env ruby
# Generate the nginx configuration for a vhost

if ARGV.empty?
  $stderr.puts "Usage: ./path/to/generator.rb env > sites-available/vhost"
  $stderr.puts "       where env is alpha or web"
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

    proxy_set_header X_FORWARDED_PROTO http;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_intercept_errors on;
    proxy_redirect off;
    proxy_max_temp_file_size 0;

    client_max_body_size 2M;

    location ~* \.(css|js|ico|gif|jpe?g|png) {
        if ($args ~* [0-9]+$) {
            expires max;
            break;
        }
    }
    location ~* \.(gif|jpe?g|png|svg|xcf|ttf|otf|dtd) {
        expires 10d;
        break;
    }

    location ^~ /b/ {
        proxy_pass http://board-frontend;
    }

    location / {
        if (-f $request_filename) { 
            break; 
        }

        if (-f $document_root/system/maintenance.html ) {
            error_page 503 /system/maintenance.html;
            return 503;
        }

        if (!-f $request_filename) { 
            proxy_pass http://linuxfr-frontend;
            break;
        }
    }

    error_page  404              /errors/400.html;
    error_page  500 502 503 504  /errors/500.html;
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

    proxy_set_header X_FORWARDED_PROTO https;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_intercept_errors on;
    proxy_redirect off;
    proxy_max_temp_file_size 0;

    client_max_body_size 2M;

    location ~* \.(css|js|ico|gif|jpe?g|png) {
        if ($args ~* [0-9]+$) {
            expires max;
            break;
        }
    }
    location ~* \.(gif|jpe?g|png|svg|xcf|ttf|otf|dtd) {
        expires 10d;
        break;
    }

    location ^~ /b/ {
        proxy_pass http://board-frontend;
    }

    location / {
        if (-f $request_filename) { 
            break; 
        }

        if (-f $document_root/system/maintenance.html ) {
            error_page 503 /system/maintenance.html;
            return 503;
        }

        if (!-f $request_filename) { 
            proxy_pass http://linuxfr-frontend;
            break; 
        }
    }

    error_page  404              /errors/400.html;
    error_page  500 502 503 504  /errors/500.html;
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
