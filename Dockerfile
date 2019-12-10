FROM node:12-alpine

RUN mkdir -p /opt && mkdir -p /opt/chaman

ADD . /opt/chaman

WORKDIR /opt/chaman

RUN npm install && npm run client:build

CMD ["npm", "run", "server:start"]
