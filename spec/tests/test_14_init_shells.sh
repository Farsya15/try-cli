# Init command shell function tests
# Spec: command_line.md (init command)

section "init-shells"

# Test: init with bash shell emits bash function
output=$(SHELL=/bin/bash try_run init "$TEST_TRIES" 2>&1)
if echo "$output" | grep -q "try() {"; then
    pass
else
    fail "init should emit bash function" "try() {" "$output" "command_line.md#init"
fi

# Test: bash function has case statement for eval
if echo "$output" | grep -q 'case "$cmd" in'; then
    pass
else
    fail "bash function should have case statement" "case \"\$cmd\" in" "$output" "command_line.md#init"
fi

# Test: bash function includes path argument
if echo "$output" | grep -q "cd --path"; then
    pass
else
    fail "bash function should include --path" "--path in function" "$output" "command_line.md#init"
fi

# Test: init with fish shell emits fish function
output=$(SHELL=/usr/bin/fish try_run init "$TEST_TRIES" 2>&1)
if echo "$output" | grep -q "function try"; then
    pass
else
    fail "init with fish should emit fish function" "function try" "$output" "command_line.md#init"
fi

# Test: fish function uses string match for eval detection
if echo "$output" | grep -q "string match"; then
    pass
else
    fail "fish function should use string match" "string match" "$output" "command_line.md#init"
fi
