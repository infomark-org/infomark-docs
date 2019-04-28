---
title: "Queries"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

To run queries for the purpose of doing some statistics we highly recommend to make a snapshot of the database as illustrated in the "Administrator's Guide". Above is a collection of usefule SQL snippets. The app [`pgweb`](http://sosedoff.github.io/pgweb/) is quite useful.

## Getting distribution of students to groups

To gest a list of how students are distributed to groups. This is useful when manually creating/changing assignments:

```sql
SELECT
  count(*), ug.group_id, g.description
FROM
  user_group ug
INNER JOIN groups g ON g.id = ug.group_id
WHERE
  g.course_id = <courseid>
GROUP BY
  ug.group_id, g.description
ORDER BY g.description

```

To change an assignment, simply update

```sql
UPDATE  user_group SET group_id = <newgroupid> WHERE user_id = <userid>
```


## Getting Preferences

When a discussion starts about the auto-assignments (which *is* optimal) must user simply forgot their preferences or made a mistake. To get an overview of these preferences run

```sql
SELECT
  bid, group_id, description
FROM
  group_bids gb
INNER JOIN groups g ON gb.group_id = g.id
WHERE
  gb.user_id = <userid>
```

## Get an overview of number of submissions

Just list the number of submissions per task

```sql
SELECT
  t.id task_id, sh.id sheet_id, count(s.*), sh.name, t.name
FROM
  submissions s
INNER JOIN user_course uc ON uc.user_id = s.user_id
INNER JOIN tasks t ON t.id = s.task_id
INNER JOIN task_sheet ts ON ts.task_id = s.task_id
INNER JOIN sheets sh ON sh.id = ts.sheet_id
WHERE uc.role = 0
GROUP BY t.id, t.name, sh.name, sh.id
ORDER BY sh.publish_at ASC
```