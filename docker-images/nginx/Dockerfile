FROM nginx:stable

RUN rm -rf /etc/nginx/conf.d/*

ENV SSL_CERTIFICATE_PATH /etc/nginx/ssl/cert.pem
ENV SSL_CERTIFICATE_KEY_PATH /etc/nginx/ssl/cert.key


COPY bin/ /usr/sbin/
COPY sites-templates /etc/nginx/sites-templates
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl/cert.pem /etc/nginx/ssl/cert.pem
COPY ssl/cert.key /etc/nginx/ssl/cert.key
COPY sites-enabled/default.conf /etc/nginx/conf.d/default.conf
COPY includes /etc/nginx/includes
COPY custom-locations /etc/nginx/custom-locations


WORKDIR /etc/nginx

EXPOSE 80 443

ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx"]
