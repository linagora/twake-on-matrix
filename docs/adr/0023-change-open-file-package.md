# 23. Change open file package

Date: 2024-05-13

## Status

Accepted

## Context

The package `open_file` has been used to open files on mobile versions of the app. The problem is that this package is not compatible with desktop platforms. Especially on Linux where it caused some errors and does not work. That said we could use the method `Process.run()` for each desktop platform but that might complexify a lot the process.

## Decision

A fork of `open_file` has been made, named `open_file_app` (https://pub.dev/packages/open_app_file). A fix has been made for Linux https://github.com/yendoplan/open_app_file/pull/5 which is the branch we will use until it will be merged by the maintainers.
Since it's a fork, the methods are the same than `open_file` and works the same way.
