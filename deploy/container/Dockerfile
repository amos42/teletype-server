FROM node:14.19.3-alpine

COPY . /teletype-server
WORKDIR /teletype-server
RUN npm config set strict-ssl false
RUN npm install

COPY --chown=0:0 entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "sh", "/entrypoint.sh" ]
