# FROM node:14.19.3-alpine
FROM postgres:15.6-bullseye

RUN apt update
RUN apt install -y curl gzip

RUN curl -sL https://nodejs.org/dist/v14.21.3/node-v14.21.3-linux-x64.tar.xz | tar Jxf - -C /usr/local --strip-components=1

COPY --chown=postgres:0 .. /teletype-server
WORKDIR /teletype-server

RUN npm install

ENV POSTGRES_DB="teletype"
ENV POSTGRES_USER="teletype"
ENV POSTGRES_PASSWORD="teletype1!"

COPY --chown=0:0 --chmod=755 start-service.sh /

RUN sed -i "s/-c\ listen_addresses=''/-c\ listen_addresses='*'/" /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/^[[:space:]]*docker_temp_server_stop[[:space:]]*$/#&/' /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/^[[:space:]]*exec[[:space:]]*\"\$@\"[[:space:]]*$/exec\ \/start-service.sh/' /usr/local/bin/docker-entrypoint.sh

CMD [ "postgres" ]

EXPOSE 4279
