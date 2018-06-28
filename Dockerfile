FROM python:3.6.2-jessie

RUN apt-get update && apt-get install -y wget zsh

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    apt-key add -

RUN apt-get update && apt-get install -y postgresql-client-9.5

COPY docker-entrypoint.sh /docker-entrypoint.sh
WORKDIR /code-or-die/code-or-die
COPY . .

RUN pip install -r requirements.txt
CMD make
