---
title: "Overview"
date: 2019-04-21
lastmod: 2019-12-30
layout: subpage
---


InfoMark is a free, scalable, modern and open-source online
course management system supporting auto-testing of programming assignments scaling to thousands of students and several courses.

Uploaded solutions to programming assignments are tested automatically.
For more information about writing such tests see our [Tutor's Guide](/guides/tutor/). On how to use the system please refer to the [Administrator's Guide](/guides/administrator/). And for development please refer to our [Developer's Guide](/guides/developer/).

Teaching assistants (tutors) can grade these homework solutions online. The platform supports multiple courses each with multiple exercise groups, slides and course material. The backend server talks RESTful JSON such that you can write your own scripts using eg. Python.

# Quick-Start

These commands are the *same* for deployment on your local machine or deployment in production on a server.
Please download the latest release from the [release page](https://github.com/infomark-org/infomark/releases/).
These releases ship a single binary containing all required files. The only dependency is docker and docker-compose.

We will explain necessary steps to spin up a fully production-ready system on your machine. Infomark is implemented as modern CLI with POSIX-compliant flags.


## Requirements

InfoMark has the following minimal requirements:

* one CPU core for server `infomark serve`  (1GB RAM)
* one CPU core for each backgound worker `infomark work` (memory requirement depends on your docker-image size for the programming assignments)

We assume an Ubuntu system. But InfoMark will also happily do its business on other systems that provide docker (>= v1.13) and docker-compose. There are no other dependencies you need to juggle with.

## Setup

First create a configuration using InfoMark and write it to `infomark-config.yml`.

```bash
./infomark console configuration create > infomark-config.yml
```

This config file is populated with values to provide a minimal working ([example](https://github.com/infomark-org/infomark/blob/master/configuration/example.yml)). Strong passwords are generated (each time you call this command). The configuration file might seem a bit complex at a first glance, but for now you just need to adapt the following values:

```yaml
  http:
    domain: sub.domain.com
  paths:
    uploads: /path/to/uploads
    common: /path/to/common
    generated_files: /path/to/generated_files
```

The domain should be `localhost` for deployment on your local machine and the paths should be absolute paths, that exists and are writeable. We use docker-compose for handling dependencies

```bash
./infomark console configuration create-compose infomark-config.yml > docker-compose.yml
```

It will create a ready-to-use docker-compose file. For all following commands the configuration file `infomark-config.yml` is required. These commands expect this configuration file to be specified in the environment variable `INFOMARK_CONFIG_FILE`. You might want to specify this information by

```bash
export INFOMARK_CONFIG_FILE=/absolute/path/to/infomark-config.yml
```

If you do forget to set this environment variable, the following commands will remind you to do so.

## Run
To start all dependencies just run the newly generated docker-compose file via

```bash
docker-compose up
```

Before starting the server, you might want to check your configuration

```bash
./infomark console configuration test infomark-config.yml
```

This will make InfoMark try to speak to the database, rabbitMQ and redis from the docker-compose setup. It will also test if it can save uploads.
You will probably get the feedback, that a privacy statement file does not exists. We ship one example of a privacy statement in german.

If everything is green, start the server by

```bash
./infomark serve
```

That's all!
The `serve` command will take care of initializing the database when starting the first time.
Point your browser to http://localhost:3000. This will display the login page of InfoMark.
To further enable 2 background workers, just run

```bash
sudo ./infomark work -n 2
```

Sudo is required to start docker containers on behalf of the system.

Upgrading InfoMark is also easy: Simply stop the infomark server and worker, replace the binary and start the server and worker again.

## First User
To add a user, please register your user in the web interface.
After registration the email address needs to be confirmed. If sendmail is configured you will receive an instruction email containing a link to activate this account.

Let us do this procedure manually using the console. Further, we will upgrade the permission of this user to have root privileges :

```bash
# confirm email
./infomark console user confirm your@email.com

# find the id of a user
./infomark console user find your@email.com

    42 YourFirstname YourLastname your@email.com

# add the user with id "1" to admins.
./infomark console admin add 42
```

When running InfoMark on a server in production, we recommend to use [NGINX](https://www.nginx.org/) or [Caddy](https://caddyserver.com/) as a reverse-proxy in front of InfoMark.

# Design Choices

InfoMark is designed to run within IT-controlled private environments in public clouds
on your own servers to be compliant with any data privacy issues providing data sovereignty.

It is based on several design choices:

**Be open, Never lock-in to expand**<br>
Every part must be open-source, scalable, reliable and robust. It must be easy to extract and use the information outside of InfoMark.
Development must be open and adapting the implementation has to be possible. Writing scripts (eg in Python) for common jobs must be easy. We provide an [API description](/swagger/).

**Be user-friendly to grow**<br>
The entire system must be easy to deploy, to maintain and to update
even for non-technical users with basic IT skills. We want to provide decisions and not options. It should have near-zero administration. You probably have better things to do than playing a server administration.

**Be robust and reliable to earn trust**<br>
Auto-Testing of programming assignments must be language-agnostic, isolated and safe.
All intense operations must be asynchronously scheduled.
The frontend must be light-weight, fast and responsive. Creating and restoring a database backup is not supposed to be a nervous breakdown.

**Be modern and simple to stay**<br>
We deliberately chose GO for the backend and ELM for for the frontend. We had a hard time to re-deploy our [old system](https://github.com/infomark-org/InfoMark-deprecated) written in Ruby-On-Rails. There should be no magic behind the scene which breaks when updating the dependencies.



# System Overview

This section provides a brief overview of the InfoMark system including a description of its parts.
We use continuous-integration tests to ensure the implementation can be built and passes all tests at any point.

At its core, InfoMark is a single-compiled Go binary that is exposed as a Restful JSON web server with Javascript clients. See the Restful API docs (created using [Swagger](https://swagger.io/)) [here](https://infomark.org/swagger/).

<div class="center"><img src="/images/illustrations/overview.png" /></div>

## Backend
[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark/status.svg)](https://ci.patwie.com/infomark-org/infomark)
[![Source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark)

The backend acts as a Restful JSON web server and is written in [Go](https://golang.org/). All dependencies are encapsulated in a docker-compose configuration file. The dependencies are:

- We use a [PostgreSQL](https://www.postgresql.org/) database to store all dynamic data.
- Computationally intensive operations are scheduled and balanced across several background workers asynchronous via [RabbitMQ](https://www.rabbitmq.com/).
- It uses [Redis](https://redis.io/) as a light-weight key-value memory store.
- [Docker](https://www.docker.com/) is used as a light-weight sandbox to run auto-tests of  solutions to programming assignments in an isolated environment.

Each exercise task can be linked to a docker-image and a zip file containing the test code to support testing. See the Administrator Guide for more details.

### Server
Part of the backend is the **server**.
The server talks RESTful JSON to remote CLI, the Web-interface and workers.

### Workers

Part of the backend are **workers**, which are separate processes that handle the auto-testing of uploads. These worker *can* be distributed across multiple machines.
We recommend using one worker process for 100 students. The workers can be added or removed at any time. Infomark uses AMPQ as a message broker. Each submission will be held in a queue and each worker will execute one job concurrently to avoid too much system load. Our recommendation is one worker per available CPU core.

The used amount of memory per submission can be configured. Memory-swapping is deactivated.

### Console

To avoid manual interaction with the database InfoMark provides a console to run several commands like enrolling a student into a course/group, set the role of a user.

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

## Frontend
[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark-ui/status.svg)](https://ci.patwie.com/infomark-org/infomark-ui)
[![Source](https://img.shields.io/badge/source-download-blue.svg)](https://github.com/infomark-org/infomark-ui)

The frontend is written in [Elm](https://elm-lang.org/), a functional frontend language which compiles to JavaScript. The application is just a single page application (SPA) which uses fragments for
routing. So the server only needs to distribute the static HTML page and the REST API which is used to
interact with the server. The API is defined [here](https://infomark.org/swagger/)
using [Swagger](https://swagger.io/).


# Development

The initial system was developed in the [computer graphics groups](https://uni-tuebingen.de/en/faculties/faculty-of-science/departments/computer-science/lehrstuehle/computergrafik/computer-graphics/) of the University of Tübingen because there are no comparable systems that meet our requirements.
