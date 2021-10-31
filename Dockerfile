FROM httpd:latest
# Base setup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    apt-get install -q -y curl net-tools iputils-ping dnsutils less  && \
    apt-get -y update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./app/www/resume-website /usr/local/apache2/htdocs/
COPY ./app/httpd_config/httpd.conf /etc/httpd/conf/httpd.conf 
COPY ./app/httpd_config/vs_http.conf /etc/httpd/conf.d/vs_http.conf

EXPOSE 80 