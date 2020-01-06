---
title: "Administrator's Guide"
date: 2019-04-21
lastmod: 2019-12-30
layout: subpage
---

# General Information

This page gives a brief overview of the underlying system and capabilities. It is meant to be read by people who would like to install the system. If you are provided such an instance please refer to the [Instructor's Guide](/guides/instructor)

The Infomark System can serve multiple courses within a single server instance. The linked background workers will then be shared amongst these courses.

## Configuration

The configuration is done within a YAML config file.
For an example configuration please refer to the [example](https://github.com/infomark-org/infomark/blob/master/configuration/example.yml).

In general, the defaults might do the job. For all secrets like passwords, tokens or keys you should use `openssl rand -base64 32` to generate random high-quality secrets or generate the configuration using the InfoMark console.

We discuss some important settings:

### Auth_JWT

Infomark supports two authentications systems:

- JSON-Web-Token (JWT) and
- sessions.

If you use JWT ensure they stay valid. There is an access token which confirms the identity of the request identity and has to be attached to the header in each request. The refresh token serves the purpose to create a new short-life access token.

The sessions are handled on the server-side using cookies. Any session will stay 24h valid in total but will expire within 20 minutes if no action is taken. Please note, the frontend frequently does send requests to the backend even without explicit user interaction, e.g. polling for new test-logs from the auto-testing feature. Hence, these sessions will be kept alive.

### Email

For technical reasons, our infrastructure only supports the binary `sendmail` to deliver emails. If you remove the `sendmail_binary` key from the config, all emails from the system will be displayed in the terminal. Additionally, each outgoing email will have a footnote

```
Sent by: FirstName LastName
sent via Infomark
```

when these are composed by any user.

### Directories

We use several directories to store uploads, generated files or common files like a privacy statement. The default values will work if the paths exist. We made these paths configurable as these files require different backup strategies. We suggest estimating beforehand the required space. From our experience 1000 submissions are equal to 20MB. You can limit the size of each submission file in the server settings in `server.http.limits`.

### Server-Settings

To balance the tradeoff between too many request and responsiveness, we added several strategies to avoid blocking actions. We limit the number of bytes which are read from the client during a request. The default of 1MB is enough for common JSON requests. You can configure these limits for each kind of request using the following keys:

- `server.http.limits.max_request_json` to limit any JSON request
- `server.http.limits.max_avatar` to limit the image size for the avatar in the profil
- `server.http.limits.max_submission` to limit the size for homework solutions

There is no limit when uploading slides or extra course material.

### Background-Worker

Background-Workers can be turned off when using the config `distribute_jobs: false`.

## Roles and Permissions

InfoMark has a relatively simple permission system. The permissions are linked to a request identity (the user). Each user can be either a normal user or `global admin`. Any global admin will bypass all permission checks and gives the user all permissions across all hosted courses.

To upgrade/downgrade a user to `global admin` use the console like

```bash
# upgrade account
./infomark console admin add [the-user-id]
# downgrade account
./infomark console admin remove [the-user-id]
```

Only, a global admin can create new courses.

To get granularity in the permission system each user enrolled into a course will be assigned to one the following roles:

- *admin*: Admin for a course -- not a global admin
- *tutor*: Teaching assistants who will grade homework and lead exercise groups
- *students*: This is the default role.

These permissions control which resources a user has access to, e.g. students cannot see other students personal information. Slides and material can be targeted to a specific role, e.g., distribute sample solution to TAs. These roles are subsets, i.e., an admin has all permissions, which a tutor and a student has. Tutors have additional permissions compared to students.

To upgrade a user to a course-tutor or course-admin use the console

```bash
# set permission to student
./infomark console course enroll [course-id] [the-user-id] student
# set permission to tutor
./infomark console course enroll [course-id] [the-user-id] tutor
# set permission to admin
./infomark console course enroll [course-id] [the-user-id] admin
```

Note, this enrolls the user to a course if the user is not enrolled. Otherwise, it simply updates the role in a course.

## Auto-Tests

Please refer to the [Tutor's Guide](/guides/tutor) for more details about writing and using auto-tests.

Each task of a programming assignment can be linked to a docker-image and a zip file containing the test code.
Technically, the server process acting as a Restful JSON web server will communicate using AMQP with separate processes, which are called `workers`. These workers can be started at different machines.

>Please note, in the current version these workers have global admin privileges. This will change in the future. Hence, only start these workers on machines you trust (which is anyway a good idea).

### Conventions

A worker communicates directory to the local docker API and runs a command like:

```bash
docker run --rm -it --net="none" \
  -v <STUDENT_UPLOAD.ZIP>:/data/submission.zip:ro \
  -v <TASK_SEPCIFIC_TEST.ZIP>:/data/unittest.zip:ro  \
  <YOUR_DOCKER_IMAGE>
```

Note, each test is isolated from the internet and the uploaded solution of students `<STUDENT_UPLOAD.ZIP>` and test-framework `<TASK_SEPCIFIC_TEST.ZIP>` are mounted read-only.
The worker captures all outputs from stdout which is between two markers. The docker output

```stdout
this output here before the marker will be ignored

--- BEGIN --- INFOMARK -- WORKER

[ ok ]     done
[ failed ] done

--- END --- INFOMARK -- WORKER

some other output which will be ignored
```

will be captured as

```stdout
[ ok ]     done
[ failed ] done
```

If the docker child returns an exit code != 0 a default message will be sent instead. We highly encourage to locally test any new test-framework using the "docker run" command above.

The workers, will download the student submission over HTTP and run these tests locally. Make sure, the used docker file exists or is already pulled from e.g. docker-hub.

We provide [examples](/guides/tutor) for testing Java, Python and C++ programming assignment solutions.

## Exercise Groups

InfoMark supports multiple exercise groups per course. These are usually weekly meetings where exercises are discussed. The owner of an exercise group can be any user in the system independently from the role. However, to be allowed to grade student submissions the user needs the course-specific role "tutor".

The system collects *bids* from students. Each bid indicates a preference to different dates of the exercise groups (10 means best choice, 1 means the student would like to take another exercise group). By definition each student is enrolled into one unique group only. But, tutors can advise several exercise groups.

To guarantee the best possible assignment between student and exercise groups -- maximizing the overall happiness -- we solve an Integer-Programm using [Symphony](https://projects.coin-or.org/SYMPHONY). Symphony can solve this problem instance with several exercise groups and thousands of students reliably.

The folder `assignment_solver` contains the docker image. Alternatively you can pull the docker image `patwie/symphony` from docker-hub.

To export the bids of students run

```bash
./infomark console group dump-bids [courseID] [file] [min_per_group] [max_per_group]
```

Hereby, `min_per_group` and `max_per_group` constraint the number of allowed participants in each exercise group. If you use the wrong bounds the problem might be infeasible to solve. Then change these constraints. An example is

```bash
./infomark console group dump-bids 1 mycourse 15 30
```

InfoMark will then display the command to create a solution, e.g.

```bash
sudo docker run -v "$PWD":/data -it patwie/symphony  /var/symphony/bin/symphony -F /data/mycourse.mod -D /data/mycourse.dat -f /data/mycourse.par > solution.txt

cat solution.txt
...
assign[u276,g2]    1.0000000000
assign[u277,g9]    1.0000000000
assign[u278,g10]   1.0000000000
assign[u279,g10]   1.0000000000
assign[u280,g6]    1.0000000000
assign[u281,g1]    1.0000000000
assign[u282,g8]    1.0000000000
assign[u283,g5]    1.0000000000
assign[u284,g9]    1.0000000000
assign[u285,g5]    1.0000000000
assign[u286,g3]    1.0000000000
assign[u287,g6]    1.0000000000
assign[u288,g4]    1.0000000000
assign[u289,g9]    1.0000000000
assign[u290,g4]    1.0000000000

...
```

The solution `solution.txt` can be directly fed into infomark using

```bash
./infomark console group import-assignments [courseID] solution.txt
```

Executing this command will assign each student to a group. Once they are assigned to an exercise group they cannot change their preference anymore. However, any course-admin can manually change the assignment.

## Backup / Restore

The console features commands which can create and restore snapshots from the database.
We use Postgres version 11, and the backup/restore routine requires the binaries
`pg_dump`, `dropdb`, `createdb`, `psql`, `gunzip` as it merely wraps these commands and creates pipes

Installing the correct binaries make sure you run these commands **once**:

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-11
which gunzip
```

To create a snapshot run

```bash
./infomark console database backup path/to/file.sql.gz
```

To load data from a snapshot run

```bash
./infomark console database restore path/to/file.sql.gz
```

## Generated Files

The InfoMark-backend generates files in an internal cron-job. The cron-jobs have
a setting `cronjob_intervall_*` which specifies the interval these jobs should run.
One cronjob is `submission_zip`, which will zip all submissions together (per group and task) such that tutors/TAs can download the entire bundle of submissions.

The job will create a lock file to avoid creating the same zip again and to avoid race conditions.
Setting the interval is done via the setting `cronjob_intervall_submission_zip`.

These files reside in the directory `generated_files_dir` with the name

```
collection-course%d-sheet%d-task%d-group%d.lock
```

where each '%d' is replaced by the *id*. To regenerate a specific file (e.g. you extended the due date for an exercise) simply remove both files

```bash
rm collection-course%d-sheet%d-task%d-group%d.lock
rm collection-course%d-sheet%d-task%d-group%d.zip
```

# API

The definition of all available routes to the RESTful backend is described in our Swagger [definition file](/swagger/).

# Metrics

The metrics for [Prometheus](https://prometheus.io/) are served under `localhost:<port>/metrics`. We highly suggest not to expose these metrics when using a reverse proxy like NGINX.

To visualize these metrics we have assembled a [custom Grafana-Board](https://github.com/infomark-org/infomark-docs/tree/master/metrics).