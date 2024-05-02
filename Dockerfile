FROM python:3

RUN DEBIAN_FRONTEND=noninteractive apt update && apt upgrade -y \
    && apt install nginx supervisor composer -y

# create booktype group, booktype user and assign it to the group
RUN groupadd booktype && useradd booktype -g booktype -u 1000

ENV INSTANCENAME mybook
ENV BOOKTYPE_SERVER 127.0.0.1:8000
ENV BOOKTYPE_URL http://127.0.0.1:8000
ENV BOOKTYPE_REDIS_HOST redis
ENV BOOKTYPE_BROKER_URL amqp://guest:guest@rabbit:5672/
ENV BOOKTYPE_DATABASE_ENGINE django.db.backends.postgresql_psycopg2
ENV BOOKTYPE_DATABASE_HOST db
ENV BOOKTYPE_DATABASE_PORT 5432
ENV BOOKTYPE_DATABASE_NAME booktype
ENV BOOKTYPE_DATABASE_USER booktype
ENV BOOKTYPE_DATABASE_PASSWORD booktype
ENV BOOKTYPE_PANDOC_PATH /usr/bin/pandoc
ENV BOOKTYPE_MPDF_DIR /code/mpdf60

RUN mkdir -p /var/log/supervisor

# create dir for code
RUN mkdir -p /code/scripts

# create dir for configs
RUN mkdir -p /code/configs

# copy shell scripts
COPY ./scripts/ /code/scripts

# set working dir
WORKDIR /code

COPY . /code/Booktype/

COPY bt/scripts/ /code/scripts/

# RUN python3 -m venv venv && . venv/bin/activate \
#     && pip install pip setuptools wheel -U \
#     && pip install -r Booktype/requirements/req_prod.txt \
#     && ./Booktype/scripts/createbooktype --database postgresql ${INSTANCENAME}
RUN pip install pip setuptools wheel uwsgi -U \
    && pip install --no-cache-dir -r Booktype/requirements/req_prod.txt \
    && Booktype/scripts/createbooktype --database postgresql ${INSTANCENAME}

# make scripts executable
RUN chmod ug+x scripts/celery.sh scripts/web.sh scripts/manage_py.sh scripts/wait-for-it.sh ${INSTANCENAME}/manage_prod.py

RUN chown -R booktype:booktype /code/ \
    && chmod -R 775 /code/${INSTANCENAME}/logs \
    && chmod -R 775 /code/${INSTANCENAME}/data

# copy configs
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY configs/nginx_booktype.conf /etc/nginx/sites-enabled/
COPY configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY configs/uwsgi.ini /code/configs
COPY configs/uwsgi_params /code/mybook

EXPOSE 8000

# * wait for db container is ready to accept connection
#     https://docs.docker.com/compose/startup-order/
#     https://github.com/vishnubob/wait-for-it
#     https://github.com/vishnubob/wait-for-it/issues/15
# * run manage commands
#     - migrate
#     - update_permissions
#     - update_default_roles
#     - collectstatic
#     - compress
#     - create_superuser
# * run supervisor
#     - nginx
#     - uwsgi
#     - celery

RUN chown -R booktype:booktype /var/log/supervisor \
    && chown -R booktype:booktype /var/lib/nginx \
    && chown -R booktype:booktype /var/log/nginx \
    && chown -R booktype:booktype /run

USER booktype

CMD ./scripts/wait-for-it.sh -t 60 db:5432 -- ./scripts/manage_py.sh \
    && /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

# RUN ./scripts/manage_py.sh

# CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
