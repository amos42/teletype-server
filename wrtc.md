#WRTC Server Setting#

teletype-server
소스 위치
https://code.sdsdev.co.kr/cloud-ide/teletype-server

.env 파일
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
빌드 방법
npm install
npm run migrate up
서버 실행
```
$ export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/new_S-Core.Proxy.crt
$ export NODE_TLS_REJECT_UNAUTHORIZED=0
$ npm run start
```

teletype 서버 동작을 위해  추가로 필요한 서비스들
db 서버
dbms : postgresql

계정 : 현재 postgres

postgres shell
```
$ createdb teletype-server-dev
$ createdb teletype-server-test
$ createdb teletype-server-devnpm
$ createuser teletype-server
```
psql
```
alter user "teletype-server" with encrypted password 'teletype1!';
grant all privileges on database "teletype-server-devnpm" to "teletype-server";
grant all privileges on database "teletype-server-test" to "teletype-server";
```

인증 서비스
현재 github.com 계정 (teletype 추가)

토큰 링크 : https://teletype.atom.io/login

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
```json
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

실행
```
$ soketi start --config=config.json
```

webrtc를 위한 ice 서버 (stun/turn 서버 포함)
coturn 이용 (https://github.com/coturn/coturn)

설치 방법
```
sudo apt install coturn
```

cotrun docker
```
docker run -d -p 3478:3478 -p 3478:3478/udp -p 5349:5349 -p 5349:5349/udp -p 49160-49200:49160-49200/udp \
       coturn/coturn -n --log-file=stdout \
                        --min-port=49160 --max-port=49200\
```

도커 shell 접속 후
```
turnadmin -O -r teletype -o teletype
turnadmin -a -u teletype -p teletype1! -r teletype
```
테스트
```
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
```
URI : turn:localhost:3478
username : teletype
password : teletype1!
twilo  json  respose
https://AC6cf7c3f97850bec93ca950e15d934ffa:6f8f87acce08c034f93bf3963c8f56ab@api.twilio.com/2010-04-01/Accounts/AC6cf7c3f97850bec93ca950e15d934ffa/Tokens.json

server.js
```js
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
