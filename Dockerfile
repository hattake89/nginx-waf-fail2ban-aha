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
    libmodsecurity-dev \
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
RUN NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '{print $2}') \
    && wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && tar -xzf nginx-$NGINX_VERSION.tar.gz \
    && mv nginx-$NGINX_VERSION nginx-src

WORKDIR /usr/local/src/nginx-src/
RUN ./configure \
    --with-compat \
    --add-dynamic-module=../ModSecurity-nginx \
    && make modules || (cat objs/autoconf.err && exit 1) \
    && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# Download and extract OWASP CRS
WORKDIR /etc/nginx
RUN git clone --depth 1 https://github.com/coreruleset/coreruleset.git owasp-crs \
    && mv owasp-crs/crs-setup.conf.example owasp-crs/crs-setup.conf

# Cleanup source files
RUN rm -rf /usr/local/src/*

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY modsecurity.conf /etc/nginx/modsecurity.conf

# Enable ModSecurity module and load OWASP CRS
RUN echo 'load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' \
    > /etc/nginx/modules/modsecurity.conf \
    && echo 'Include /etc/nginx/owasp-crs/crs-setup.conf' >> /etc/nginx/modsecurity.conf \
    && echo 'Include /etc/nginx/owasp-crs/rules/*.conf' >> /etc/nginx/modsecurity.conf

# Start Fail2Ban service and keep container running

CMD nginx -g "daemon off;"