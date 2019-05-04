---
title: "Tutor's Guide"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

# Unit - Tests

There are some ways to ease the task of writing unit-tests. A clean directory structure and a Makefile to automatically pack all necessary archives or/and run the unit-test locally can dramatically speed-up the entire process and avoid debugging steps on the server. The *makefile* should be able to clean temporary files, zip files and simulate the test result locally using the correct docker-image. Further, specificy the docker-image in the *makefile* helps to setup the task in InfoMark as you will need to specify it there during creating a new exercise task.

## Java

We suggest to keep the following directory structure

```
exercises
  exercise01
    tasks
      sheet.tex
    solution
      main
        FileA.java
        FileB.java
    student_template[a.b]
      main
        FileA.java
        FileB.java
    unittest_public[a.b]
      src
        __unittest
          FileAtest.java
          FileBtest.java
    unittest_private[a.b]
      src
        __unittest
          FileAtest.java
          FileBtest.java
```

where `[a.b]` represents the exercise-task-number.

### Student-Template

The student-template is usually a zip-file with the exercise tasks as a PDF and a code-template. We suggest to make sure the code template can be uploaded itself to the system such that there are not compilation errors. A very basic example might be

```java
package main;

public class Hello {

  public static void main(String[] args) {
    System.out.println("6 / 2 = " + divide(6, 2));
  }

  public static int divide(int a, int b) {
    return a - b;
  }
}

```


### Tests

Public tests will convey their results back to the student in our system. These are tests which should help a student to make sure their solution for a programming assignment is roughly correct. They have to be:

- verbose
- deterministic and reproducible

Private tests logs are not visible to the student. They are only visible by tutors and these tests should ensure the submitted solution is completely correct by testing several corner cases. Tutors will see both test results (public and private test outputs).

We suggest to have two sub-types of tests:

- Structure-Tests
- Value-Tests

We have compose a `Helper.java` file to ease the work with reflections when checking the solutions of the exercise tasks.

The overall structure should be

```java
package __unittest;

import static org.junit.Assert.*;

import java.lang.reflect.Modifier;
import org.junit.Test;
import org.junit.rules.Timeout;
import __unittest.Helper;
import org.junit.Rule;



public class SomeNameTest {

  // We set this timeout for each single test-case.
  @Rule
  public Timeout globalTimeout = Timeout.seconds(5);

}

```

We will not stop the docker process from the worker. You need to make sure to add a timeout *inside* the docker-environment.

#### Structure-Tests

A Structure-Test uses reflections to query all expected methods, checks their signatures and naming. All code from uploaded by any user of our system should only be access via reflections as their is no guarantee these called methods exists. Rather than having a compilation error, we would like to check these during runtime to ensure we can give more verbose information of what we expect.


```java
//  unittest_public[a.b]/src/__unittest/FileAtest.java
 @Test
  public void HelloClassStructureTest() {
    // no guarantee here that the class `Hello` exists --> we use Reflections
    Helper.ClassWrapper clazz = new Helper.ClassWrapper("main.Hello");
    // no guarantee here that the method `divide` exists --> we tests existence here
    // this will fail if the method does not exists (run-time error with verbose message)
    //                   name       expect (public static)          return     param 1    param 2
    clazz.mustHasMethod("divide", Modifier.PUBLIC|Modifier.STATIC, int.class, int.class, int.class);
  }
```

Running Structure-Tests only make sense in the public tests, so that students get feedback if we cannot test it because of missing methods or wrong signatures.

#### Value-Tests

Assuming the structure is valid, we will check the solution itself. Again, any wrong method signature would be a compilation error. Hence, we use reflection here as well.

##### Public Test

A good candidate for a public test would be

```java
//  unittest_public[a.b]/src/__unittest/FileAtest.java
  @Test
  public void DivideValueTest() {
    Helper.InstanceWrapper actual_class = new Helper.ClassWrapper("main.Hello").create();

    assertEquals("divide(6, 2)", 3, (int) actual_class.execute("divide", 6, 2));
    assertEquals("divide(12, 3)", 4, (int) actual_class.execute("divide", 12, 3));
    // ...
  }
```

##### Private Test

Corner cases should be part of private tests, eg. division by zero. Further, as the output of the public tests are visible solutions can overfitt the tests. A solution which passes the public test is:

```java
public static int divide(int a, int b) {
    if((a == 6) && (b==2)){
      return 3;
    }

    if((a == 12) && (b==3)){
      return 4;
    }

    return 42;
  }
```

However, we want to avoid these kind of solutions. A possible solution would be to test random numbers. But in some cases this is not possible. Further, we want to have reproducible tests. Otherwise, learning from the test-output is hardly possible.
The better way of testing overfitting is to test several additional input-combinations.
A good candidate for a private Test would be

```java
//  unittest_private[a.b]/src/__unittest/FileAtest.java
  @Test
  public void DivideValueTest() {
    Helper.InstanceWrapper actual_class = new Helper.ClassWrapper("main.Hello").create();

    // to avoid "overfitting"
    // this test would fail when hard-coding a solution to the public test
    assertEquals("divide(99, 3)", 33, (int) actual_class.execute("divide", 99, 3));

    // we might write in the exercise task, that x/0 should be 0
    // we should test this corner-case here as well
    assertEquals("divide(6, 0)", 0, (int) actual_class.execute("divide", 6, 0));
    assertEquals("divide(-12, 3)", -4, (int) actual_class.execute("divide", -12, 3));
    // ...
  }
```