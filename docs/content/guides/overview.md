---
title: "Overview"
date: 2019-04-21
lastmod: 2019-04-21
layout: subpage
---


InfoMark is a scalable, modern and open-source online
course management system supporting auto-testing of programming assignments scaling to thousand of students.

Uploaded solutions to programming assignments are tested automatically. TAs can grade these solutions online. The platform supports multiple courses each with multiple exercise groups, slides and course material.

### Quick-Start

To locally test the system we suggest to run the following commands:

```bash
cd /tmp
# get latest version
export VERSION=`curl -s https://api.github.com/repos/cgtuebingen/infomark/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'`
wget https://github.com/cgtuebingen/infomark/releases/download/${VERSION}/infomark.tar.gz
tar -xzvf infomark.tar.gz

cd infomark
# use default settings
cp .infomark.example.yml .infomark.yml
cp docker-compose.example.yml docker-compose.yml

# configure paths for backend
sed -i 's/\/var\/www\/infomark-staging\/app/\/tmp\/infomark/g' /tmp/infomark/.infomark.yml


# run these commands in separate terminals
# start dependencies
sudo docker-compose up -d

# create database
cd database
PGPASSWORD=pass psql -h 127.0.0.1 -U user -p 5433 -d db -f schema.sql
PGPASSWORD=pass psql -h 127.0.0.1 -U user -p 5433 -d db -f migrations/0.0.1alpha14.sql
PGPASSWORD=pass psql -h 127.0.0.1 -U user -p 5433 -d db -f migrations/0.0.1alpha21.sql
cd ..

# start a single background worker
# sudo is required for talking to docker
sudo ./infomark work
# start Restful JSON web server
./infomark serve
```

After registration in the web-interface the email address needs to be confirmed. This can be done manually over the console. Further, you might want to upgrade the permission to root:

```bash
# confirm email
./infomark console user confirm your@email.com

# find id of user
./infomark console user find your@email.com

    1 YourFirstname YourLastname your@email.com

# add user with id "1" to admins.
./infomark console admin add 1
```

In a production setup we recommend to use [NGINX](https://www.nginx.org/) as a proxy in front of InfoMark to increase security, performance and the ability to monitor and shape traffic connecting to InfoMark. See the Administartor Guide for different roles.

### Design Choices

InfoMark is designed to run within IT-controlled private environments in public clouds
on your own servers to be compliant with any data privacy issues providing data sovereignty.

It is based on several design choices:

- Every part must be open-source and robust.
- The backend must be easy to deploy, maintain and scalable.
- The frontend must be light-weight, fast and responsive.
- Auto-Testing of programming assigments must be language-agnostic, isolated and safe.
- All intense operations must be asynchronously scheduled.


### System Overview

This section provides a brief overview of the InfoMark system including a description of its parts.
We use continuous-integration tests to ensure the implementation can be built and passes all tests at any point.

At its core, InfoMark is a single-compiled Go binary that is exposed as a Restful JSON web server with Javascript clients. See the Restful API docs (created using [Swagger](https://swagger.io/)) [here](https://infomark.org/swagger/).

### Backend
[![Build Status](https://ci.patwie.com/api/badges/cgtuebingen/infomark-backend/status.svg)](https://ci.patwie.com/cgtuebingen/infomark-backend)
[![Source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/cgtuebingen/infomark-backend)

The backend acts as a Restful JSON web server and is written in [Go](https://golang.org/). All dependencies are encapsulated in a docker-compose configuration file. The dependencies are:

- We use a [PostgreSQL](https://www.postgresql.org/) database to store all dynamic data.
- Computationally intensive operations are scheduled and balanced across several background workers asynchronous via [RabbitMQ](https://www.rabbitmq.com/).
- It uses [Redis](https://redis.io/) as a light-weight key-value memory store.
- [Docker](https://www.docker.com/) is used a as light-weight sandbox to run auto-tests of  solutions to programming assignments in a isolated environment.

Part of the backend are **workers**, which are separate processes that handle the auto-testing of uploads. These worker *can* be distributed accross multiple machines. We recommmend to use one worker process for 100 students. The workers can be added or removed at any time.

Each exercise task can be linked to a docker-image and a zip file containing the test code to support testing. See the Administrator Guide for more details.

#### Console

To avoid manual interaction with the database InfoMark provides a console to run several commands like enroll a student into a course/group, set role of user.

```bash
./infomark console user find jane.doe

42 Jane Doe jane.doe@student.uni-tuebingen.de

./infomark console user confirm

    Usage:
      infomark console user confirm [email] [flags]

./infomark console user confirm jane.doe@student.uni-tuebingen.de

./infomark console course enroll

    Usage:
      infomark console course enroll [courseID] [userID] [role] [flags]

# roles: student (0), tutor/ta (1), admin (2)
./infomark console course enroll 1 42 2

```

### Frontend
[![Build Status](https://ci.patwie.com/api/badges/cgtuebingen/infomark-ui/status.svg)](https://ci.patwie.com/cgtuebingen/infomark-ui)
[![Source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/cgtuebingen/infomark-ui)

The frontend is written in [Elm](https://elm-lang.org/), a functional frontend language which compiles to JavaScript. The application is just a single page application (SPA) which uses fragments for
routing. So the server only needs to distribute the static HTML page and the REST Api which is used to
interact with the server. The API is defined in this [repository](https://github.com/cgtuebingen/infomark-swagger)
using [Swagger](https://swagger.io/).


## Development

This system was developed in the [computer graphics groups](https://uni-tuebingen.de/en/faculties/faculty-of-science/departments/computer-science/lehrstuehle/computergrafik/computer-graphics/) of the University of Tübingen because there are no comparable systems that meet our requirements.