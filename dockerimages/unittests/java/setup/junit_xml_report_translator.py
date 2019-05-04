#!/usr/bin/python3
# -*- coding: utf-8 -*-
import xml.etree.ElementTree as ET
import os


class Failure:
  def __init__(self, xml_failure):
    self.failure_tag = xml_failure.tag
    self.failure_type = xml_failure.attrib["type"] if 'type' in xml_failure.attrib.keys() else 'no type from JUnit'
    self.message = xml_failure.attrib["message"] if 'message' in xml_failure.attrib.keys() else 'no message from JUnit'

  def GetMarkdown(self) -> str:
    markdown = "          - Tag: {FailTag}\n"
    markdown += "          - Typ: {FailType}\n"
    markdown += "          - Msg: {FailMessage}\n\n"
    markdown = markdown.format(FailTag=self.failure_tag,
                               FailType=self.failure_type,
                               FailMessage=self.message)
    return markdown


class TestCase:
  def __init__(self, xml_case_tree):
    self.xml = xml_case_tree
    self.name = self.xml.attrib["name"]
    self.passed = len(self.xml) == 0
    self.failures = []
    if not self.passed:
      self.failures = [Failure(f) for f in self.xml]

  def GetMarkdown(self) -> str:
    markdown = "[{Failed}] {TestName}: \n"
    if self.passed:
      markdown = markdown.format(TestName=self.name,
                                 Failed="   OK   ")
    else:
      markdown = markdown.format(TestName=self.name,
                                 Failed=" FAILED ")
      for i in range(len(self.failures)):
        failure = self.failures[i]
        markdown += "        Error {FailureNumber}/{FailureCount}\n"
        markdown += failure.GetMarkdown()
        markdown = markdown.format(FailureNumber=i + 1,
                                   FailureCount=len(self.failures))
    return markdown


class ErrorReport:
  def __init__(self, xml_path):
    self.tree = ET.parse(xml_path)
    self.root = self.tree.getroot()

  def GetMarkdown(self) -> str:
    test_cases = self.getTestcases()
    markdown = ""
    for case in test_cases:
      markdown += case.GetMarkdown()
    return markdown

  def getTestcases(self) -> list:
    cases = [TestCase(c) for c in self.root.iter("testcase")]
    return cases


def main():
  # report_path = "/home/simple_ci_runner/java/build/junitreport/"
  report_path = "./build/junitreport/"
  if not os.path.isdir(report_path):
    return

  reports = [os.path.join(report_path, f) for f in os.listdir(report_path)
             if f.endswith(".xml")]

  markdown = ""
  for r in reports:
    report = ErrorReport(r)
    markdown += report.GetMarkdown()

  # TODO PREAMBLE
  #print("--- BEGIN --- INFOMARK -- WORKER")
  print(markdown)
  #print("--- END --- INFOMARK -- WORKER")
  # TODO POSTAMBLE


if __name__ == "__main__":
  # Tell python that unicode character are allowed in parent terminal
  main()

