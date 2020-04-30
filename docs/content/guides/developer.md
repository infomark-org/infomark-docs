---
title: "Developer's Guide"
date: 2019-04-21
lastmod: 2020-04-30
layout: subpage
---

The System is managed via two git-repositories.
Both parts are tested separately using continuous integration tests. It is a good idea to read the `.drone.yml` configuration on how to build these parts from source.

Whenever a combination is stable, we will create a new release, which can be downloaded here:

<a class="btn btn-primary" href="https://github.com/infomark-org/infomark/releases" target="_blank"><i class="fas fa-cloud-download-alt"></i> Download InfoMark</a>


# Frontend

[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark-ui/status.svg)](http://ci.patwie.com/infomark-org/infomark-ui)
[![source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark-ui)

We use the [Elm]((https://elm-lang.org/)) language to create a robust and fast implementation. Elm compiles to JavaScript.


# Backend

[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark/status.svg)](http://ci.patwie.com/infomark-org/infomark)
[![source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark)
[![download](https://img.shields.io/badge/release-download-blueviolet.svg)](https://github.com/infomark-org/infomark-ui/releases/latest)

For usage in production, we highly recommend using our pre-built releases as they are tested. If you want to compile the backend from source

```bash
git clone https://github.com/infomark-org/infomark
cd infomark
go build infomark.go
```

Building InfoMark requires Go version at least 1.13.

## Unit-Test

To guarantee a stable version each commit is tested against some unit-tests.

> While most projects just test a mock we really test the behavior of the endpoints with a Postgres database.

To run the tests you will need to set up the dependencies as described in the [Overview Chapter](/guides/overview). Please make sure, the database is empty but migrated to latest version. This can be done by dropping all data

```bash
sudo docker-compose down -v
sudo docker-compose up
./infomark console database migrate
```

In addition, we add mock entries to the database.

```bash
# mock database content
cd database
python3 mock.py

PGPASSWORD=pass psql -h YOUR_HOST -U YOUR_USER -p YOUR_PORT -d YOUR_DBNAME -f mock.sql
```

Then

```bash
cd API/app
go test --cover
```

will start the unit tests. Each test is handled in a transaction and will not change the database (using commit and rollback). However, some test cases depend on the actual `mock.sql` data.


## Features and Scope

InfoMark just want to be as generic as necessary (not possible). These features are not implemented on purpose:

* in-browser pdf annotation
* discussion board
* email conversation and inbox