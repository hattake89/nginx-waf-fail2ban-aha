### Dockerfile untuk Nginx dengan ModSecurity dan Fail2Ban ###
FROM nginx:latest

# Install ModSecurity, Fail2Ban, dan module terkait
RUN apt update && apt install -y \
    libmodsecurity3 \
    nginx-module-security \
    fail2ban \
    && rm -rf /var/lib/apt/lists/*

# Salin konfigurasi nginx, modsecurity, dan fail2ban
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/nginx/modsecurity.conf
COPY owasp-crs /etc/nginx/owasp-crs
COPY sites-available/ /etc/nginx/sites-available/
COPY sites-enabled/ /etc/nginx/sites-enabled/
COPY fail2ban/jail.local /etc/fail2ban/jail.local
COPY fail2ban/nginx-ddos.conf /etc/fail2ban/filter.d/nginx-ddos.conf

# Aktifkan ModSecurity
RUN echo 'load_module modules/ngx_http_modsecurity_module.so;' \
    > /etc/nginx/modules/modsecurity.conf

CMD ["nginx", "-g", "daemon off;"]