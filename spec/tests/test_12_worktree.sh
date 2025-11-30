# Worktree command tests
# Spec: command_line.md (worktree command)

section "worktree"

# Create a fake git repo for worktree tests
FAKE_REPO=$(mktemp -d)
mkdir -p "$FAKE_REPO/.git"

# Test: worktree dir with name emits git worktree add
output=$(cd "$FAKE_REPO" && try_run --path="$TEST_TRIES" exec worktree dir myfeature 2>&1)
if echo "$output" | grep -q "worktree add"; then
    pass
else
    fail "worktree dir should emit git worktree add" "worktree add command" "$output" "command_line.md#worktree"
fi

# Test: worktree uses date-prefixed name
if echo "$output" | grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}-myfeature"; then
    pass
else
    fail "worktree should use date-prefixed name" "YYYY-MM-DD-myfeature" "$output" "command_line.md#worktree"
fi

# Test: worktree dir without git repo skips worktree step
PLAIN_DIR=$(mktemp -d)
output=$(cd "$PLAIN_DIR" && try_run --path="$TEST_TRIES" exec worktree dir plaindir 2>&1)
if echo "$output" | grep -q "worktree add"; then
    fail "worktree without .git should skip worktree step" "no worktree add" "$output" "command_line.md#worktree"
else
    pass
fi

# Test: worktree without .git still creates directory
if echo "$output" | grep -q "mkdir"; then
    pass
else
    fail "worktree without .git should still mkdir" "mkdir command" "$output" "command_line.md#worktree"
fi

# Test: try . (dot) in git repo creates worktree from cwd name
output=$(cd "$FAKE_REPO" && try_run --path="$TEST_TRIES" --and-exit exec cd . 2>&1)
if echo "$output" | grep -q "worktree add"; then
    pass
else
    fail "try . in git repo should emit worktree add" "worktree add command" "$output" "command_line.md#worktree"
fi

# Test: try . with custom name overrides basename
output=$(cd "$FAKE_REPO" && try_run --path="$TEST_TRIES" --and-exit exec cd . custom-trial 2>&1)
if echo "$output" | grep -q "custom-trial"; then
    pass
else
    fail "try . with name should use custom name" "custom-trial in output" "$output" "command_line.md#worktree"
fi

# Cleanup
rm -rf "$FAKE_REPO" "$PLAIN_DIR"
