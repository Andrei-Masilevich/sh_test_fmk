# Simple Testing Framework

Onepage-script Unit Testing Framework. It untended to test console applications/scripts inside bash scripts.

Object model supposes:

* Modules initiated by **INIT_SH_TEST_FMK**
* Test suites enclosed by **START_TEST_SUITE/END_TEST_SUITE** inside each module
* Checks inside each test suite: **TEST/TEST_APP/TEST_APP_OUTPUT**

|||
|-|-|
|TEST|it tests for expression|
|TEST_APP|it tests application for exit code|
|TEST_APP_OUTPUT|it tests application for exit code and result string|

> There are **TEST_APP_/TEST_APP_OUTPUT_/TEST_APP_OUTPUT_FD_** and other few functions for fine tuning

Look at **examples/test_all.sh** to get usage examples.
It can be run together or separately.

I believe that is one of the simplest framework and will be helpful anyway




