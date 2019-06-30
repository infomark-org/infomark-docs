
# InfoMark

|Frontend|Backend|
|----|----|
|[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark-ui/status.svg)](http://ci.patwie.com/infomark-org/infomark-ui)|[![Build Status](https://ci.patwie.com/api/badges/infomark-org/infomark-backend/status.svg)](http://ci.patwie.com/infomark-org/infomark-backend)|
| [git+source](https://github.com/infomark-org/infomark-ui), [download](https://github.com/infomark-org/infomark-ui/releases/latest) | [git+source](https://github.com/infomark-org/infomark-backend), [download](https://github.com/infomark-org/infomark-ui/releases/latest)|


InfoMark is an is a scalable, modern and open-source [rewrite of our](https://github.com/infomark-org/InfoMark-deprecated) online course management system with auto testing of students submissions [(video)](https://www.youtube.com/watch?v=ifyUssK6PJ4) to ease the task of TAs.


See [https://infomark.org](https://infomark.org) for more details.

Features:
- flexible client/server implementation featuring unit-tests
- distribute exercise sheets with due-dates, and course slides/material with publish-dates
- students can upload their solutions
- assignments of students to exercise groups according to their bids is optimized via MILP solver
- automatic asynchronous testing of students homework solutions by scalable background workers using docker as a sandbox and providing feedback for students
- easy to install using docker-compose for dependencies and single binary for the server
- CLI for administrative work without touching the database

