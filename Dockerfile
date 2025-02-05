FROM nginx:latest

# Install dependencies
RUN apt update && apt install -y \
    gcc \
    g++ \
    make \
    automake \
    autoconf \
    libtool \
    git \
    wget \
    curl \
    zlib1g-dev \
    libpcre3-dev \
    libssl-dev \
    libxml2-dev \
    libyajl-dev \
    doxygen \
    liblua5.3-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build ModSecurity
WORKDIR /usr/local/src
RUN git clone --depth 1 -b v3/master https://github.com/SpiderLabs/ModSecurity.git \
    && cd ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install

# Clone and build ModSecurity-Nginx Connector
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

# Download and extract Nginx source for module compilation
RUN wget http://nginx.org/download/nginx-$(nginx -v 2>&1 | awk -F'/' '{print $2}').tar.gz \
    && tar -xzf nginx-*.tar.gz

WORKDIR /usr/local/src/nginx-*/
RUN ./configure \
    --with-compat \
    --add-dynamic-module=../ModSecurity-nginx \
    && make modules \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# Cleanup source files
RUN rm -rf /usr/local/src/*

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/nginx/modsecurity.conf
COPY owasp-crs /etc/nginx/owasp-crs
COPY sites-available/ /etc/nginx/sites-available/
COPY sites-enabled/ /etc/nginx/sites-enabled/
COPY fail2ban/jail.local /etc/fail2ban/jail.local
COPY fail2ban/nginx-ddos.conf /etc/fail2ban/filter.d/nginx-ddos.conf

# Enable ModSecurity module
RUN echo 'load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' \
    > /etc/nginx/modules/modsecurity.conf

CMD ["nginx", "-g", "daemon off;"]
