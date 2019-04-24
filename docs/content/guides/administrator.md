---
title: "Administrator's Guide"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

# General Information

The Infomark System can serve multiple courses within a single instance. The linked background workers will then be shared amongst these courses.

The configuration is done within a YAML config file and has the following content

```yaml
# shared configuration for both
# ------------------------------------------------------------------------------

rabbitmq_connection: amqp://user:password@localhost:5672/
rabbitmq_exchange: test-exchange
...

# backend
# ------------------------------------------------------------------------------
url: http://your.domain.com
log_level: debug
...
# ...

# worker
# ------------------------------------------------------------------------------
worker_workdir: /tmp
...
```

Now, only the keys `rabbitmq_*` need to be shared and the same for worker and server (backend). In general, the defaults might do the job. For all secrets like passwords, tokens or keys we suggest to use `openssl rand -base64 32` to generate random high-quality secrets.


We discuss some important settings:

#### Auth_JWT

Infomark supports two authentications systems: JSON-Web-Token (JWT) and sessions. If you use JWT ensure they stay valid. There is an access token which confirms the identity of the request identity and a refresh token. The refresh token serves the purpose to create a new short-life access token.

The sessions are handled in the server over cookies. Any session will stay 24h valid but expires within 20 minutes if no action is taken. Please note, the frontend usually starts frequently request to the backend even without user interaction, e.g. polling for new logs of the testing features. Hence, these sessions will be kept alive.

#### Email

For technical reasons in our infrastructure we only support sendmail yet. If you remove the `sendmail_binary` key, outgoing emails will be instead displayed in the terminal. Additionally, each outgoing email will have a footnote:

```
Sent by: FirstName LastName
sent via Infomark
```

We hard-coded the domain `uni-tuebingen.de` such that any registration attempt outside this domain will get a warning. You might want to see the Developer setting to hard-code your own domain there or see the developer guide on how to build the frontend.

#### Directories

We use directories to store uploads, generated files or common files like a privacy statement. The default values will work if the paths exist. We made these paths configurable as these files require different backup strategies.

#### Server-Settings

To balance the tradeoff between too many request and responsiveness, we added several strategies to avoid blocking actions. While each request is handled in a light-weight Go-routine we cannot stop these routines Go only has a fork-join thread-model. Instead we limit the number of bytes which are read from the client. The default of 1MB is enough for common JSON requests.

#### Worker

Workers will ignore any queued submissions when `worker_void` is set to `true`. These workers can be turned off by `use_backend_worker: false`.

## Roles and Permissions

InfoMark has a relatively simple permission system. The permissions are linked to a request identity (the user). Each user can be either a normal user or `global admin`, which gives the user all permissions across all hosted courses.

To upgrade/downgrade a user to `global admin` just use the console like

```bash
# upgrade account
./infomark console admin add [the-user-id]
# downgrade account
./infomark console admin remove [the-user-id]
```

Only, a global admin can create new courses.


Further, every time a user enrolls into a course, there are three roles:
- admin: Admin for a course -- not a global admin
- tutor: Teaching assistants who will grade homework and lead exercise groups
- students: This is the default role.

These permissions control which resources a user has access to, e.g. students cannot see other students personal information. Slides and material can be targeted to a specific group, e.g., distribute sample solution to TAs. These roles are subsets, i.e., an admin has all permissions a tutor and a student has. Tutors have additional permissions compared to students.

To upgrade a user to a course-tutor or course-admin use the console

```bash
# set permission to student
./infomark console course enroll [course-id] [the-user-id] 0
# set permission to tutor
./infomark console course enroll [course-id] [the-user-id] 1
# set permission to admin
./infomark console course enroll [course-id] [the-user-id] 2
```

Note, this enrolls the user to a course if the user is not enrolled. Otherwise, it simply updates the role in a course.

## Auto-Tests Programming Assignments

Each task can be linked to a docker-image and a zip file containing the test code.
Technically, the server process handling acting as a Restful JSON web server will communicate with separate processes, which are called `workers`. These workers can be started at different machines.

><i class="fa fa-exclamation-triangle"></i> Please note, in the current version these workers have global admin privileges. This will change in the future. Hence, only start these workers on machines you trust!

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

## Exercise Groups

InfoMark supports multiple exercise groups per course. These are usually weekly meetings where exercises are discussed. The owner of an exercise group can be any user in the system independently from the role. However, to be allowed to grade student submissions the user needs the course-specific role "tutor".

The system collects *bids* from students. Each bid indicates a preference to different dates of the exercise groups (10 means best choice, 1 means the student would like to take another exercise group). By definition each student is enrolled into one unique group only. But, tutors can advise several exercise groups.

To guarantee the best possible assignment between student and exercise groups -- maximizing the overall happiness -- we solve an Integer-Programm using [Symphony](https://projects.coin-or.org/SYMPHONY). Symphony can solve this problem instance with several exercise groups and thousand of students reliably.

The folder `assignment_solver` contains the docker image. Alternatively you can pull the docker image `patwie/symphony` from docker-hub.

To export the bids of students run

```bash
./infomark console assignments dump-bids [courseID] [file] [min_per_group] [max_per_group]
```

Hereby, `min_per_group` and `max_per_group` constraint the number of allowed participants in each exercise group. If you use the wrong bounds the problem might be infeasible to solve. Then change these constraints. An example is

```bash
./infomark console  assignments  dump-bids 1 mycourse 15 30
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
./infomark console assignments import-solution [courseID] solution.txt
```

Executing this command will assign each student to a group. Once they are assigned to an exercise group they cannot change their preference anymore. However, any course-admin can manually change the assignment.