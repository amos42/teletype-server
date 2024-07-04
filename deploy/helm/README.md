# Teletype server Helm Chart

## Prerequisites

* node 12 이상
* postgresql 
* github.com 인증
* wslio 인증
* puhser 인증 코드 획득

## DB

postgresql 

```
createdb teletype-server
createuser teletype-server
 
psql
alter user "teletype-server" with encrypted password 'teletype1!';
grant all privileges on database "teletype-server" to "teletype-server";
```

DB 마이그레이션 : teletype-server pod에서 npm run migrate up 수행 (최초 1회 만)
먼저 쉘에서 .env 파일 중에 DATABASE_URL을 수정한다.

```
DATABASE_URL=postgres://teletype-server:teletype1!@postgres:5432/teletype-server
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

다음의 명령 실행

```
$ npm run migrate up
```

### Soketi

* node 13 이상
* puhser 인증 코드 획득
* config.json 작성


## coturn

```
turnadmin -O -r teletype -o teletype
turnadmin -a -u teletype -p teletype1! -r teletype
```


## theia

devfile
```
apiVersion: 1.0.0
metadata:
  name: theia-teletype
projects:
  - name: official-testcase-spring1
    source:
      location: 'https://code.sdsdev.co.kr/cloud-ide/official-testcase-spring1.git'
      startPoint: master
      type: git
components:
  - id: eclipse/che-theia/7.45-teletype
    type: cheEditor
    alias: theia-editor
  - id: redhat/java8/latest
    preferences:
      java.configuration.maven.userSettings: /usr/share/maven/conf/settings.xml
      java.server.launchMode: Standard
    type: chePlugin
  - id: sds/vscode-coverage-gutters/2.9.1
    type: chePlugin
  - id: sds/teletype/0.0.1
    type: chePlugin
  - mountSources: true
    endpoints:
      - attributes:
          public: 'true'
        name: run
        port: 8080
      - attributes:
          public: 'false'
        name: debug
        port: 5005
    memoryLimit: 512Mi
    type: dockerimage
    volumes:
      - name: m2
        containerPath: /home/user/.m2
    alias: maven
    image: 'sds.redii.net/ide/che-java11-maven:7.28.2'
commands:
  - name: maven build
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: mvn package
        component: maven
  - name: maven clean build
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: mvn clean package
        component: maven
  - name: test dependency
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: 'mvn dependency:get -Dartifact=com.mycompany.app:my-app:1.0'
        component: maven
  - name: test deploy
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: |
          VER=1.0.0-$(date '+%Y%m%d%H%M%S')
          sed -i -e "13s#1.0.0-.*<#$VER<#g" pom.xml
          mvn clean deploy
        component: maven
  - name: maven run
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: 'mvn spring-boot:run'
        component: maven
  - name: debug run
    actions:
      - workdir: '${CHE_PROJECTS_ROOT}/official-testcase-spring1'
        type: exec
        command: |
          java -jar -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005 target/*.jar
        component: maven
  - name: Debug remote java application
    actions:
      - referenceContent: |
          {
          "version": "0.2.0",
          "configurations": [
            {
              "type": "java",
              "name": "Debug (Attach) - Remote",
              "request": "attach",
              "hostName": "localhost",
              "port": 5005
            }]
          }
        type: vscode-launch
```

```
apiVersion: 1.0.0
metadata:
  name: teletype-7.45.0
projects:
  - name: official-testcase-spring1
    source:
      location: 'https://code.sdsdev.co.kr/cloud-ide/official-testcase-spring1.git'
      type: github
components:
  - id: sds/teletype/0.0.1
    preferences:
      teletype.settings.apiHostUrl: 'http://teletype-server.ide-prd:4279'
      teletype.settings.pusher.wsPort: '6001'
      teletype.settings.pusher.cluster: ap3
      teletype.settings.pusher.wsHost: soketi.ide-prd
      teletype.settings.pusher.key: cc8fb96b89e84d763d6b
    type: chePlugin
  - id: eclipse/che-theia/7.45-teletype
    type: cheEditor
```