
db
```
createdb teletype-server-dev
createdb teletype-server-test
createdb teletype-server-devnpm
 
createuser teletype-server
 
psql
alter user "teletype-server" with encrypted password 'teletype1!';
grant all privileges on database "teletype-server-dev" to "teletype-server";
grant all privileges on database "teletype-server-devnpm" to "teletype-server";
grant all privileges on database "teletype-server-test" to "teletype-server";
```


coturn
```
turnadmin -O -r teletype -o teletype
turnadmin -a -u teletype -p teletype1! -r teletype
```

