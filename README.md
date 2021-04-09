# try_adb_test plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-try_adb_test)

## About try_adb_test

The easiest way to retry your Android Instrumented Tests 🚀

Under the hood `try_adb_test` uses the stable version of the marvelous [`gojuno composer`](https://github.com/gojuno/composer) and allows you to customize your retry strategy.

| Option | Description | Default |
| ------- |------------ | ------- |
| apk | Either relative or absolute path to application apk that needs to be tested | |
| test_apk | Either relative or absolute path to apk with tests | |
| test_runner | Fully qualified name of test runner class you're using | Automatically parsed from test_apk's AndroidManifest |
| try_count | Number of times to try to get your tests green | 1 |
| shard | Either true or false to enable/disable [test sharding](https://developer.android.com/training/testing/junit-runner.html#sharding-tests) which statically shards tests between available devices/emulators | true |
| output_directory | Either relative or absolute path to directory for output: reports, files from devices and so on | fastlane/output |
| instrumentation_arguments | Key-value pairs to pass to Instrumentation Runner | Empty |
| verbose | Either true or false to enable/disable verbose output for Composer | false |
| devices | Connected devices/emulators that will be used to run tests against. Example: "emulator-5554 emulator-5556" | Empty, tests will run on all connected devices/emulators |
| device_pattern | Connected devices/emulators that will be used to run tests against. Example: "emulator.+" | Empty, tests will run on all connected devices/emulators |
| fail_if_no_tests | Either true or false to enable/disable error on empty test suite | true |
| install_timeout | Apk installation timeout in seconds. Applicable to both test Apk and Apk under test | 120 |
| extra_apks | Apks to be installed for utilities. What you would typically declare in gradle as androidTestUtil. Example: "path/to/apk/first.apk path/to/apk/second.apk" | Empty |

## Requirements

* JVM 1.8+

## Getting Started

To get started with `try_adb_test`, add it to your project by running:

```bash
$ fastlane add_plugin try_adb_test
```

## Usage

```ruby
try_adb_test(
  try_count: 2,
  test_runner: 'com.example.test.ExampleTestRunner',
  test_apk: "app/build/outputs/apk/example-debug.apk",
  apk: "app/build/outputs/apk/example-debug-androidTest.apk",
  instrumentation_arguments: "package com.example",
  device_pattern: 'emulator.+'
)
```
