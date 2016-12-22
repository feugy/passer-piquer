FROM prestashop/prestashop:latest
MAINTAINER Feugas <damien.feugas@gmail.com>

# Force values to avoid install folder renaming
ENV PS_FOLDER_INSTALL install
ENV PS_LANGUAGE fr
ENV PS_COUNTRY FR

# Copy configuration and translations files
COPY config/app /tmp/existing/app
COPY config/config /tmp/existing/config
COPY config/translations /tmp/existing/translations

# Copy install & run script
COPY config/docker_run.sh /tmp/
COPY config/.htaccess /tmp/existing/.htaccess

RUN chmod +x /tmp/docker_run.sh

CMD ["/tmp/docker_run.sh"]