---
title: "Tutor's Guide"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

# Unit - Tests

Unit-tests consists of
- a submission `<STUDENT_UPLOAD.ZIP>` made by a student
- a testing framework `<TASK_SEPCIFIC_TEST.ZIP>` written by one of the tutors/instructors
- a docker-image name `<YOUR_DOCKER_IMAGE>`

Each infomark-worker will fetch a submission from a queue and execute a command which is equal to

```bash
docker run --rm -it --net="none" \
  -v <STUDENT_UPLOAD.ZIP>:/data/submission.zip:ro \
  -v <TASK_SEPCIFIC_TEST.ZIP>:/data/unittest.zip:ro  \
  <YOUR_DOCKER_IMAGE>
```

and capture the output which is store in the database and displayed the student resp. the tutor who grades the solution.

## Overview

There are some ways to ease the task of writing unit-tests.
A clear directory structure and a Makefile to automatically pack all necessary archives or/and run the unit-test locally can dramatically speed up the entire process and avoid debugging steps on the server.
The *makefile* should be able to clean temporary files, zip files and simulate the test result locally using the correct docker-image.
Further, specifying the docker-image in the *makefile* helps to set up the task in InfoMark as you will need to specify it there while creating a new exercise task.

InfoMark is language-agnostic. The system only records the docker-output. All post-processing of runs (processing JUNIT outputs) must be done *within* the docker container.

We provide several testing-templates and examples

| language   |      dockerimage  (hub.docker.com)     |  test example | dockerfile |
|----------|:-------------|:-------:|:------:|
| Java 11 |  [patwie/test_java_submission:latest](https://cloud.docker.com/u/patwie/repository/docker/patwie/test_java_submission) | [yes](https://github.com/cgtuebingen/infomark/tree/master/unittests/java) | [yes](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests/java) |
| Python3 |  [patwie/test_python3_submission:latest](https://cloud.docker.com/u/patwie/repository/docker/patwie/test_python3_submission) | [yes](https://github.com/cgtuebingen/infomark/tree/master/unittests/java) | [yes](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests/java) | [yes](https://github.com/cgtuebingen/infomark/tree/master/unittests/python) | [yes](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests/python) |
| C++ |  [patwie/test_cpp_submission:latest](https://cloud.docker.com/u/patwie/repository/docker/patwie/test_cpp_submission) | [yes](https://github.com/cgtuebingen/infomark/tree/master/unittests/java) | [yes](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests/java) | [yes](https://github.com/cgtuebingen/infomark/tree/master/unittests/cpp) | [yes](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests/cpp) |


## Java 11

We suggest using our [docker-image](https://github.com/cgtuebingen/infomark/tree/master/dockerimages/unittests) to run follow the guide below.

We suggest keeping the following directory structure

```
exercises
  exercise<a>
    makefile
    tasks
      sheet.tex
    solution
      main
        FileA.java
        FileB.java
    student_template_[<a>.<b>]
      main
        FileA.java
        FileB.java
    unittest_public_[<a>.<b>]
      src
        __unittest
          FileAtest.java
          FileBtest.java
      build.xml
    unittest_private[<a>.<b>]
      src
        __unittest
          FileAtest.java
          FileBtest.java
      build.xml
```

where `[a.b]` represents the exercise-task-number. A working example can be found in the [InfoMark-repository](https://github.com/cgtuebingen/infomark/tree/master/unittests).

### Student-Template

The student-template is usually a zip-file with the exercise tasks as a PDF and a code-template.  A very basic example might be

```java
package main;

public class Hello {

  public static void main(String[] args) {
    System.out.println("6 / 2 = " + divide(6, 2));
  }

  public static int divide(int a, int b) {
    return 1;
  }
}

```

We suggest making sure the code template can be uploaded itself to the system such that there are no compilation errors.Testing the code-template above against the unit-tests gives

```
[javac] Compiling 3 source files to /build/classes
[   OK   ] HelloClassStructureTest:
[ FAILED ] DivideValueTest:
        Error 1/1
          - Tag: failure
          - Typ: junit.framework.AssertionFailedError
          - Msg: divide(6, 2) expected:<3> but was:<1>
```


### Tests

Public tests will convey their results back to the student in our system. These are tests which should help a student to make sure their solution for a programming assignment is roughly correct. They have to be:

- verbose
- deterministic and reproducible

Private test logs are not visible to the student. Only tutors can access these infomation which should test if the submitted solution is completely correct by checking several corner cases. Tutors will see both test results (public and private test outputs).

We suggest to have two sub-types of tests:

- Structure-Tests
- Value-Tests

We have composed a [Helper.java](https://github.com/cgtuebingen/infomark/blob/master/unittests/java/unittest_private_0.1/src/__unittest/Helper.java) file to ease the work with reflections when checking the solutions of the exercise tasks.

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

  @Test
  // ...

}

```

We will not stop the docker process from the worker. You need to make sure to add a timeout *inside* the docker-environment.

#### Structure-Tests

A Structure-Test uses reflections to query all expected methods, check their signatures and naming. All code uploaded by any user of our system should only be accessed via nreflections as there is no guarantee that the expected methods exist. Rather than having a compilation error, we would like to check these during runtime to ensure we can give more verbose information about what we expect.


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

If the return type of `divide` would be `double` in the uploaded solution (while we expect it to be an `int`) the output will

```
[ FAILED ] HelloClassStructureTest:
        Error 1/1
          - Tag: failure
          - Typ: junit.framework.AssertionFailedError
          - Msg: Method `public static double divide (int, int )` in `class Hello` found, but expected return type (`int`) is wrong. I just found `double`

```

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

Corner cases should be part of private tests, e.g. division by zero. Further, as the output of the public tests is visible solutions can overfit the tests. A solution which passes the public test is:

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

However, we want to avoid these kinds of solutions. A possible solution would be to test random numbers. But in some cases, this is not possible. Further, we want to have reproducible tests. Otherwise, learning from test-output is hardly possible.
The better way of testing overfitting is to test several additional input-combinations.
A good candidate for a private test would be

```java
//  unittest_private[a.b]/src/__unittest/FileAtest.java
  @Test
  public void DivideValueTest() {
    Helper.InstanceWrapper actual_class = new Helper.ClassWrapper("main.Hello").create();

    // to avoid "overfitting"
    // this test would fail when hard-coding a solution against the public test
    assertEquals("divide(99, 3)", 33, (int) actual_class.execute("divide", 99, 3));

    // we might write in the exercise task, that x/0 should be 0
    // we should test this corner-case here as well
    assertEquals("divide(6, 0)", 0, (int) actual_class.execute("divide", 6, 0));
    assertEquals("divide(-12, 3)", -4, (int) actual_class.execute("divide", -12, 3));
    // ...
  }
```

## Python 3

We provide the a very basic but working test set for checking python programming assignment solutions in our [git-repository](https://github.com/cgtuebingen/infomark/tree/master/unittests/python).

The basic idea is that any upload will be unzipped into a directory together with the unit-test:

```
/src
  <name>.py        # from student submission
  <name>_test.py   # from testing-framework
```

Hereby, again the submission upload will be extracted first and the test framework will be extracted after such that it cannot be overwritten. Tests are executed via

```bash
python3 -m unittest discover -s . --verbose -p '*_test.py'
```

As python-code can be be written without any datatypes you will need to test if the methods with the correct signatue exists.

For a given upload with content

```python
# hello.py
def divide(a, b):
  return a + b  # here is a mistake
```

A test might look like:

```python
# hello_test.py
import unittest


class Testdivide(unittest.TestCase):

  def test_divide(self):
    import hello
    self.assertTrue(hasattr(hello, 'divide'))

    if hasattr(hello, 'divide'):
      self.assertEqual(hello.divide(14, 7), 2, "Should be 2")
```

This would produce the output

```
Python 3.7.3
test_divide (divide_test.Testdivide) ... FAIL

======================================================================
FAIL: test_divide (divide_test.Testdivide)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "divide_test.py", line 11, in test_divide
    self.assertEqual(hello.divide(14, 7), 2, "Should be 2")
AssertionError: 21 != 2 : Should be 2

----------------------------------------------------------------------
Ran 1 test in 0.001s

FAILED (failures=1)
```

## C++

Testing in C++ is a bit tricky, doing reflections is difficult. A basic example is provided in out [git-repository](https://github.com/cgtuebingen/infomark/tree/master/unittests/cpp).
The final directory structure *inside* the docker container will be

```
/src
  lib/             # from the upload/student_template
    divide.cpp     # from the upload/student_template
    divide.hpp     # from the upload/student_template
  hello.cpp        # from the upload/student_template
  hello_test.cpp   # from the test
  catch.hpp        # from the test
  CMakeLists.txt   # from the test
  run.sh           # from the test
```

Any file from the testing-zip will override a file from the uploaded submission if such a file exists. Further, we automatically remove any "*.sh" from the submission file in our Docker-setup.

Any submission consists of a main file

```cpp
// hello.cpp
#include <stdio.h>
#include "lib/divide.h"

int main(int argc, char const *argv[]) {
  printf("%d / %d = %d\n", 6, 3, divide(6, 3));
  return 0;
}
```

and a implementation in `lib`

```cpp
// lib/divide.cpp
#include "divide.h"

int divide(int a, int b) { return a + b; }
```

with forward-declaration

```cpp
// lib/divide.h
#ifndef LIB_DIVIDE_H_
#define LIB_DIVIDE_H_

int divide(int a, int b);

#endif  // LIB_DIVIDE_H_
```

As the implementation of `divide` is not correct the output will be:

    Alpine clang version 5.0.1 (tags/RELEASE_501/final) (based on LLVM 5.0.1)
    Target: x86_64-alpine-linux-musl
    Thread model: posix
    InstalledDir: /usr/bin
    -- The C compiler identification is GNU 6.4.0
    -- The CXX compiler identification is GNU 6.4.0
    -- Check for working C compiler: /usr/bin/cc
    -- Check for working C compiler: /usr/bin/cc -- works
    -- Detecting C compiler ABI info
    -- Detecting C compiler ABI info - done
    -- Detecting C compile features
    -- Detecting C compile features - done
    -- Check for working CXX compiler: /usr/bin/c++
    -- Check for working CXX compiler: /usr/bin/c++ -- works
    -- Detecting CXX compiler ABI info
    -- Detecting CXX compiler ABI info - done
    -- Detecting CXX compile features
    -- Detecting CXX compile features - done
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /src/build
    Scanning dependencies of target hello
    [ 33%] Building CXX object CMakeFiles/hello.dir/hello_test.cpp.o
    [ 66%] Building CXX object CMakeFiles/hello.dir/lib/divide.cpp.o
    [100%] Linking CXX executable hello
    [100%] Built target hello
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    hello is a Catch v2.7.2 host application.
    Run with -? for options
    -------------------------------------------------------------------------------
    Divide should be correct
    -------------------------------------------------------------------------------
    /src/hello_test.cpp:7
    ...............................................................................
    /src/hello_test.cpp:8: FAILED:
      REQUIRE( divide(6, 3) == 2 )
    with expansion:
      9 == 2
    ===============================================================================
    test cases: 1 | 1 failed
    assertions: 1 | 1 failed

The output would also contain all linking issues (wrongly named function) like

    CMakeFiles/hello.dir/hello_test.cpp.o: In function `____C_A_T_C_H____T_E_S_T____0()':
    hello_test.cpp:(.text+0x2699e): undefined reference to `divide(double, double)'
    hello_test.cpp:(.text+0x26afd): undefined reference to `divide(double, double)'
    collect2: error: ld returned 1 exit status
    make[2]: *** [CMakeFiles/hello.dir/build.make:99: hello] Error 1
    make[1]: *** [CMakeFiles/Makefile2:68: CMakeFiles/hello.dir/all] Error 2
    make: *** [Makefile:84: all] Error 2
    /src/run.sh: line 8: ./hello: not found

> Currently, there is no way to skip non-existing methods. If a method does not exists or has the wrong signature
> the output will containg the linking error without any test-results from the run itself. This is caused by the nature
> of C++.