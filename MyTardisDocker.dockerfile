FROM ubuntu:18.04

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE DontWarn
ENV DEBIAN_FRONTEND noninteractive
ENV PYTHONUNBUFFERED 1

ENV LANG C.UTF-8

RUN apt-get update -y

RUN apt-get install -y \
    sudo git libldap2-dev libmagickwand-dev libsasl2-dev \
    libssl-dev libxml2-dev libxslt1-dev libmagic-dev curl gnupg \
    python3-dev python3-pip python3-venv zlib1g-dev libfreetype6-dev libjpeg-dev

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

RUN pip3 install virtualenvwrapper

RUN groupadd -g 1001 ubuntu
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1001 ubuntu
RUN apt-get install -y python3-pip python3-dev libpq-dev nginx curl rabbitmq-server
WORKDIR /home/ubuntu

RUN git clone -b master https://github.com/mytardis/mytardis.git

ENV VIRTUAL_ENV=/home/ubuntu/mytardis/mytardis
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install -U pip setuptools==57.5.0

WORKDIR /home/ubuntu/mytardis

RUN pip install -U -r requirements.txt
RUN pip install -U -r requirements-postgres.txt


RUN echo "from .default_settings import *\n\
    from pathlib import Path\n\
    import os\n\
    BASE_DIR = Path(__file__).resolve().parent.parent\n\
    ALLOWED_HOSTS = ['your_domain.com', 'www.your_domain.com', 'localhost', '127.0.0.1']\n\
    DEBUG = True\n\
    DATABASES['default']['ENGINE'] = 'django.db.backends.postgresql_psycopg2'\n\
    DATABASES['default']['NAME'] = 'tardis_db'\n\
    DATABASES['default']['USER'] = 'tardis'\n\
    DATABASES['default']['PASSWORD'] = 'SuperPassw0rd'\n\
    DATABASES['default']['HOST'] = 'mytardisdb'\n\
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')\n\
    STATIC_URL = '/static/'\n\
    STATIC_ROOT = os.path.join(BASE_DIR, 'static/')\n" >> tardis/settings.py

RUN npm install --production
RUN npm run-script build


RUN python -c "import os; from random import choice; key_line = '%sSECRET_KEY=\"%s\"' % ('from .default_settings import * \n\n'  if not os.path.isfile('tardis/settings.py') else '', ''.join([choice('abcdefghijklmnopqrstuvwxyz0123456789@#%^&*(-_=+)') for i in range(50)])); f=open('tardis/settings.py', 'a+'); f.write(key_line); f.close()"

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]