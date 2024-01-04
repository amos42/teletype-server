
.env
```
DATABASE_URL=postgres://teletype-server:teletype1!@postgres:5432/teletype-server-devnpm
TEST_DATABASE_URL=postgres://teletype-server:teletype1!@postgres:5432/teletype-server-test PORT=4279
PUSHER_HOST=127.0.0.1
PUSHER_PORT=6001
PUSHER_APP_ID=1355308
PUSHER_KEY=cc8fb96b89e84d763d6b
PUSHER_SECRET=1882b79e0d1e521226d7
PUSHER_CLUSTER=ap3
TWILIO_ACCOUNT=AC6cf7c3f97850bec93ca950e15d934ffa
TWILIO_AUTH_TOKEN=6f8f87acce08c034f93bf3963c8f56ab
NEW_RELIC_ENABLED=false
NEW_RELIC_APP_NAME=atom-teletype-development
NEW_RELIC_LICENSE_KEY=redacted
GITHUB_API_URL=https://api.github.com
GITHUB_CLIENT_ID=redacted
GITHUB_CLIENT_SECRET=redacted
GITHUB_OAUTH_TOKEN=redacted
HASH_SECRET=redacted
```

postgresql
dbms : postgresql
계정 : 현재 postgres

```bash
$ createdb teletype-server-dev
$ createdb teletype-server-test
$ createdb teletype-server-devnpm
$ createuser teletype-server
$ psql
psql> alter user "teletype-server" with encrypted password 'teletype1!';
psql> grant all privileges on database "teletype-server-devnpm" to "teletype-server";
psql> grant all privileges on database "teletype-server-test" to "teletype-server";
```


webrtc  signaling 서버
pusher 서비스 이용

공용 서비스는 현재 pusher.com 이용.

pusher.com에 가입하여 key와 token과 secret를 받아놔야 함.



seketi : pusher 프로토콜을 구현 한 오픈소스. 시그널 서버를 private화 하기 위해 필요

https://soketi.app/

설치
node js 버전 16 이상 필요
npm install @soketi/soketi -g


config.json
```
{
    "appManager": {
        "driver": "array",
        "array": {
            "apps": [
                {
                 "id": "1355308",
                 "key": "cc8fb96b89e84d763d6b",
                 "secret": "1882b79e0d1e521226d7",
                 "cluster": "ap3"
                }
             ]
        },
        "cache": {
            "enabled": false
        }
    },
    "port": 6001,
    "debug": true
}
```

```bash
$ soketi start --config=config.json
```

webrtc를 위한 ice 서버 (stun/turn 서버 포함)
coturn 이용 (https://github.com/coturn/coturn)

```
docker run -d -p 3478:3478 -p 3478:3478/udp -p 5349:5349 -p 5349:5349/udp -p 49160-49200:49160-49200/udp \
       coturn/coturn -n --log-file=stdout \
                        --min-port=49160 --max-port=49200\
```

```
도커 shell 접속 후
turnadmin -O -r teletype -o teletype
turnadmin -a -u teletype -p teletype1! -r teletype
테스트
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
URI : turn:localhost:3478
username : teletype
password : teletype1!
twilo  json  respose
https://AC6cf7c3f97850bec93ca950e15d934ffa:6f8f87acce08c034f93bf3963c8f56ab@api.twilio.com/2010-04-01/Accounts/AC6cf7c3f97850bec93ca950e15d934ffa/Tokens.json
```


server.js

```
const ice = {
          "username": "teletype",
          "ice_servers": [
            {
              "url": "stun:127.0.0.1:3478?transport=udp",
              "urls": "stun:127.0.0.1:3478?transport=udp"
            },
            {
              "url": "turn:127.0.0.1:3478?transport=udp",
              "username": "teletype",
              "urls": "turn:127.0.0.1:3478?transport=udp",
              "credential": "teletype1!"
            },
            {
              "url": "turn:127.0.0.1:3478?transport=tcp",
              "username": "teletype",
              "urls": "turn:127.0.0.1:3478?transport=tcp",
              "credential": "teletype1!"
            },
            {
              "url": "turn:127.0.0.1:443?transport=tcp",
              "username": "teletype",
              "urls": "turn:127.0.0.1:443?transport=tcp",
              "credential": "teletype1!"
            }
          ],
          "date_updated": "Wed, 22 Jun 2022 12:12:54 +0000",
          "account_sid": "AC6cf7c3f97850bec93ca950e15d934ffa",
          "ttl": "86400",
          "date_created": "Wed, 22 Jun 2022 12:12:54 +0000",
          "password": "teletype1!"
        };
```







### K8S

teletype-server

deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: teletype-server
  labels:
    app.kubernetes.io/name: teletype-server
    app.kubernetes.io/instance: teletype-server
    app.kubernetes.io/version: 0.0.1
spec:
  selector:
    matchLabels:           
      app.kubernetes.io/name: teletype-server
      app.kubernetes.io/instance: teletype-server
      app.kubernetes.io/version: 0.0.1    
  replicas: 1
  template:
    metadata:
      labels:         
        app.kubernetes.io/name: teletype-server
        app.kubernetes.io/instance: teletype-server
        app.kubernetes.io/version: 0.0.1       
    spec:
      containers:
      - name: teletype-server
        image: sds.redii.net/ide/teletype-server:latest
        ports:
        - containerPort: 4279
        env:
        - name: DATABASE_URL
          value: "postgres://teletype-server:teletype1!@postgres.eclipse-che:5432/teletype-server"
```
service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: teletype-server
  labels:
    app.kubernetes.io/name: teletype-server
    app.kubernetes.io/instance: teletype-server
    app.kubernetes.io/version: 0.0.1
spec:
  type: ClusterIP
  ports:
    - port: 4279
      targetPort: 4279
      name: teletype-server
      protocol: TCP
  selector:
    app.kubernetes.io/name: teletype-server
    app.kubernetes.io/instance: teletype-server
    app.kubernetes.io/version: 0.0.1
```

DB 마이그레이션 : teletype-server pod에서 npm run migrate up 수행 (최초 1회 만)


Soketi

deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: soketi
  labels:
    app: soketi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: soketi
  template:
    metadata:
      labels:
        app: soketi
        ws.soketi.app/accepts-new-connections: "yes" # optional
    spec:
      containers:
        - name: soketi
          image: sds.redii.net/ide/soketi:sds-1.2.0-16-alpine
          ports:
            - containerPort: 6001
          env:
            - name: PORT
              value: "6001"
```

service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: soketi
spec:
  selector:
    app: soketi
    ws.soketi.app/accepts-new-connections: "yes" # required
  ports:
    - protocol: TCP
      port: 6001
      targetPort: 6001
      name: ws
```

Coturn

deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coturn
  labels:
    app.kubernetes.io/name: coturn
    app.kubernetes.io/instance: coturn
    app.kubernetes.io/version: 0.0.1
spec:
  selector:
    matchLabels:
          app.kubernetes.io/name: coturn
          app.kubernetes.io/instance: coturn
          app.kubernetes.io/version: 0.0.1
  template:
    metadata:
      labels:
            app.kubernetes.io/name: coturn
            app.kubernetes.io/instance: coturn
            app.kubernetes.io/version: 0.0.1
    spec:
      hostNetwork: true
      containers:
        - name: coturn
          image: sds.redii.net/ide/coturn
          imagePullPolicy: Always
          ports:
            - name: turn-port1
              containerPort: 3478
              hostPort: 3478
              protocol: UDP
            - name: turn-port2
              containerPort: 3478
              hostPort: 3478
              protocol: TCP
            - name: turn-port3
              containerPort: 5349
              hostPort: 5349
              protocol: TCP
            - name: turn-port4
              containerPort: 5349
              hostPort: 5349
              protocol: UDP
          args: ["-n", "--min-port=49160", "--max-port=49200", "--log-file=stdout"]
```

service.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: coturn
  labels:
       app.kubernetes.io/name: coturn
       app.kubernetes.io/instance: coturn
       app.kubernetes.io/version: 0.0.1
spec:
  type: ClusterIP
  ports:
    - port: 3478
      targetPort: 3478
      protocol: UDP
      name: turn-port1
    - port: 3478
      targetPort: 3478
      protocol: TCP
      name: turn-port2
    - name: turn-port3
      port: 5349
      targetPort: 5349
      protocol: TCP
    - name: turn-port4
      port: 5349
      targetPort: 5349
      protocol: UDP
  selector:
       app.kubernetes.io/name: coturn
       app.kubernetes.io/instance: coturn
       app.kubernetes.io/version: 0.0.1
```

```bash
$ turnadmin -O -r teletype -o teletype
$ turnadmin -a -u teletype -p teletype1! -r teletype
```


teletype test config

```
      teletype.settings.apiHostUrl: 'http://teletype-server.ide-dev:4279'
      teletype.settings.pusher.wsPort: '6001'
      teletype.settings.pusher.cluster: ap3
      teletype.settings.pusher.wsHost: soketi.ide-dev
      teletype.settings.pusher.key: cc8fb96b89e84d763d6b
```
