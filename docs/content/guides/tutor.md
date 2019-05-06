---
title: "Tutor's Guide"
date: 2019-04-21
lastmod: 2019-04-24
layout: subpage
---

# Unit - Tests

There are some ways to ease the task of writing unit-tests.
A clear directory structure and a Makefile to automatically pack all necessary archives or/and run the unit-test locally can dramatically speed up the entire process and avoid debugging steps on the server.
The *makefile* should be able to clean temporary files, zip files and simulate the test result locally using the correct docker-image.
Further, specifying the docker-image in the *makefile* helps to set up the task in InfoMark as you will need to specify it there while creating a new exercise task.

InfoMark is language-agnostic. The system only records the docker-output. All post-processing of runs (processing JUNIT outputs) must be done *within* the docker container.

## Java

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

## Python

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