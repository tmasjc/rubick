# Rubick 

## Background

A web interface that enables analyst to parameterize database query into web form. The main purpose is to allow end user access to database query without giving out database credential. Also prevents database injection.

## Requirements 

For Rubick to work, it requires 2 YAML files.

- `database.yml` tells Rubick about your database connections

- `config.yml` declares your SQL queries

## Setup Database Connections

Assume that we have a MySQL database called '**mart**' and Hive data warehouse called '**dbw**', this is how we setup the connections. 

Note that Rubick by default supports `MySQL`, thus we do not need to specify MySQL driver.

```yaml
default:
    master: NULL # not use

mart:
    type: mysql
    host: your-database
    port: some-port
    username: some-user
    password: some-password
    dbname: some-database

dbw:
    type: hive
    driver: /opt/mapr/hiveodbc/lib/universal/libmaprhiveodbc.dylib
    host: your-data-warehouse
    port: some-port
    username: some-user
    password: some-password
```

## Declare SQL Queries

For every query we declare, it needs to have 3 things: a name (the root node), a `file`, and an `origin`. 

Name must be unique so that we can identify them in web form selections. `file` links to the actual SQL query which we will execute. `origin` refers to some specific database connection which we declare in `database.yml`.

All SQL scripts must be put in a common folder. Specified under `source` key.

```yaml
default:
    title: "Rubick"
    subtitle: "拉比克"
    source: Scripts # where folder SQL scripts will be stored
    
queryA:
    file: a.sql 
    origin: mart
    token:  # secret (optional)
    description: "example" # also optional

queryB:
    file: b.sql 
    origin: dbw 
    token: 12345678 
    description: "another example"
```







