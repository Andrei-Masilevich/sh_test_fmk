# Simple Testing Framework

Intended to test console applications.
Use it in bash scripts.

Look at examples: test_*.sh

```bash
source sh_test_fmk.sh.lib # TEST*, (ASSERT, TRACE, MESSAGE)

INIT_SH_TEST_FMK
# SH_TEST_FMK_VERBOSE=1

app=bin_echo_ok.sh

TEST_RESULT "$app Test #1" $app 0
TEST_RESULT "$app Test #2" $app 0 "some command"
TEST "$app Test #3" $app
TEST "$app Test #4" $app "some command"
TEST "$app Test #5" $app "reflection"
TEST_COUT "$app Test #6" $app ">>" "reflection" "reflection"
TEST_OUTPUT "$app Test #7" $app ">>" "reflection" "reflection"
TEST_COUT_RESULT "$app Test #8" $app 0 ">>" "reflection" "reflection"
TEST_OUTPUT_RESULT "$app Test #9" $app 0 ">>" "reflection" "reflection"

app=bin_echo_err.sh

TEST_RESULT "$app Test #1" $app 1
TEST_RESULT "$app Test #2" $app 1 "some command"
TEST_CERR_RESULT "$app Test #3" $app 1 ">>" "reflection" "reflection"
TEST_OUTPUT_RESULT "$app Test #4" $app 1 ">>" "reflection" "reflection"
```




