FROM nginx:alpine
LABEL org.opencontainers.image.title="my-custom-nginx"
ENV APP_ENV=dev
COPY app/ /usr/share/nginx/html/
RUN echo "charset utf-8;" >> /etc/nginx/conf.d/charset.conf
