# Delete flow tests
# Spec: tui_spec.md (Delete functionality)

section "delete"

# Create a directory to delete
DELETE_DIR="$TEST_TRIES/2025-01-01-delete-test"
mkdir -p "$DELETE_DIR"

# Test: Ctrl-D enters delete mode (shows confirmation)
output=$(try_run --path="$TEST_TRIES" --and-keys="delete-test"$'\x04\x1b' exec 2>&1)
clean=$(echo "$output" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
if echo "$clean" | grep -qi "delete"; then
    pass
else
    fail "Ctrl-D should show delete confirmation" "delete text visible" "$clean" "tui_spec.md#delete"
fi

# Recreate for next test
mkdir -p "$DELETE_DIR"

# Test: Ctrl-J navigates down (vim-style)
output=$(try_run --path="$TEST_TRIES" --and-keys=$'\x0a\r' exec 2>/dev/null)
if echo "$output" | grep -q "cd '"; then
    pass
else
    fail "Ctrl-J should navigate down" "cd command" "$output" "tui_spec.md#keyboard-input"
fi

# Test: Ctrl-K navigates up (vim-style)
output=$(try_run --path="$TEST_TRIES" --and-keys=$'\x0a\x0b\r' exec 2>/dev/null)
if echo "$output" | grep -q "cd '"; then
    pass
else
    fail "Ctrl-K should navigate up" "cd command" "$output" "tui_spec.md#keyboard-input"
fi

# Cleanup
rm -rf "$DELETE_DIR" 2>/dev/null
