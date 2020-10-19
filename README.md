# Rubick 

### Background

Simple SQL automation tool, built on Shiny framework, written in R. 

1. it allows analyst to transform database query with variables into web form;
2. it prevents database injection; 

### Getting Started 

For Rubick to work, it requires 2 files, *database.yml* and *config.yml*. 

Form registration takes 2 steps, first you must declare a key contains the string 'form', (form1, form2, etc.) under **default**. Then under each form (key), provide the sub-keys required. 

```yaml
default:
    title: "Rubick"
    subtitle: "拉比克"
    database: database.yml # database configuration
    source: Scripts # which folder SQL scripts will be stored
    form1: apple # declare form here
    
apple:
    file: a.sql # which file
    origin: dev1  # which database config
    token: abcde # secret (optional)
    description: "Minimal example." # description (optional)
```

*database.yml* is meant for database configuration. It is merely a connection setup for R. For more information, please refer to https://db.rstudio.com/databases.

```yaml
default:
    master: NULL

dev1:
    type: hive
    driver: /opt/mapr/hiveodbc/lib/universal/libmaprhiveodbc.dylib
    host: 127.0.0.1
    port: 10000
    username: some-user
    password: some-password
    dbname: some-database
```

You can also make use of R database packages by including `!!expr`. It translates string into R code.

```yaml
dev2:
    type: mysql
    driver: !!expr RMySQL::MySQL()
    host: 127.0.0.1
    port: 3306
    username: some-user
    password: some-password
    dbname: some-database
```







