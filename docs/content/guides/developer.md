---
title: "Developer's Guide"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

The System is managed via two git-repositories.
Both parts are tested separately using continuous integration tests. It is a good idea to read the `.drone.yml` configuration on how to build these parts from source.

Whenever a combination is stable, we will create a new release, which can be downloaded here:
<a class="btn btn-primary" href="https://github.com/infomark-org/infomark/releases" target="_blank"><i class="fas fa-cloud-download-alt"></i> Download Now</a>


# Frontend

[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark-ui/status.svg)](http://ci.patwie.com/infomark-org/infomark-ui)
[![source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark-ui)
[![download](https://img.shields.io/badge/release-download-blueviolet.svg)](https://github.com/infomark-org/infomark-ui/releases/latest)

We use the [Elm]((https://elm-lang.org/)) language to create a robust and fast implementation. Elm compiles to JavaScript.

Some values need to be adjusted if you want to use InfoMark:
- the domain
- the email validator

Both values can be changed by replacing the content directly in Javascript. Therefore just donwload the Release from the git repository and run `sed` e.g.,

```bash
sed -i 's/localhost:3000/your.domain.com/g' /var/www/path/to/static/js/*.js
```



# Backend

[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark/status.svg)](http://ci.patwie.com/infomark-org/infomark)
[![source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark)
[![download](https://img.shields.io/badge/release-download-blueviolet.svg)](https://github.com/infomark-org/infomark-ui/releases/latest)|

For use in production, we highly recommend using our pre-built releases as they are tested. If you want to compile the backend from source

```bash
git clone https://github.com/infomark-org/infomark
cd infomark
go build infomark.go
```

Building InfoMark requires Go version at least 1.12. We use our custom GO-mod proxy to guarantee the availability of go-packages if the package authors remove or silently change some behaviours. To use the exact same dependencies run

```bash
export GOPROXY=https://gomods.patwie.com/
```

before building InfoMark.

## Unit-Test

To guarantee a stable version each commit is tested against some unit-tests.

> While most projects just test a mock we really test the behaviour with a Postgres database.

To run the tests you will need to set up the database.

```bash
# in an extra terminal run the dependencies or start them on your own
sudo docker-compose up


# mock database content
cd database
python3 mock.py

PGPASSWORD=pass psql -h 127.0.0.1 -U user -p 5433 -d db -f mmock.sql
```

Then

```bash
cd API/app
go test --cover
```

will start the unit tests. Each test is handled in a transaction and will not change the database (using commit and rollback). However, some test cases depend on the actual `mock.sql` data.