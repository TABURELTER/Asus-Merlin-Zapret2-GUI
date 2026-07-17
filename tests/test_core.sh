#!/bin/sh
# tests/test_core.sh - Unit tests for Asus-Merlin-Zapret2-GUI

TEST_DIR="$(pwd)/tmp-tests"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/opt/zapret2/init.d/sysv" "$TEST_DIR/proc" "$TEST_DIR/lib"
export PATH="${TEST_DIR}/bin:$PATH"

# Copy library and patch hardcoded paths
cp -r lib/* "$TEST_DIR/lib/"
for f in "$TEST_DIR"/lib/*.sh; do
    # Use perl instead of sed to avoid mac/linux syntax issues
    perl -pi -e "s|/opt/zapret2|$TEST_DIR/opt/zapret2|g" "$f"
    perl -pi -e "s|/tmp/\.zapret2gui\.lock|$TEST_DIR/.lock|g" "$f"
    perl -pi -e "s|/proc/|$TEST_DIR/proc/|g" "$f"
    perl -pi -e "s|/tmp/zapret2\.conf\.tmp|$TEST_DIR/zapret2.conf.tmp|g" "$f"
done

# Mock pidof
cat << EOF > "${TEST_DIR}/bin/pidof"
#!/bin/sh
if [ "\$1" = "nfqws2" ] && [ -f "${TEST_DIR}/mock_nfqws2_pid" ]; then
    cat "${TEST_DIR}/mock_nfqws2_pid"
fi
EOF
chmod +x "${TEST_DIR}/bin/pidof"

# Mock iptables
cat << EOF > "${TEST_DIR}/bin/iptables"
#!/bin/sh
if [ -f "${TEST_DIR}/mock_iptables_ok" ]; then
    echo "NFQUEUE num 300"
else
    echo "something else"
fi
EOF
chmod +x "${TEST_DIR}/bin/iptables"

# Mock init script
cat << EOF > "${TEST_DIR}/opt/zapret2/init.d/sysv/zapret2"
#!/bin/sh
if [ "\$1" = "restart" ]; then
    if [ -f "${TEST_DIR}/mock_restart_fail" ]; then
        exit 1
    fi
    echo "12345" > "${TEST_DIR}/mock_nfqws2_pid"
    mkdir -p "${TEST_DIR}/proc/12345"
    echo -n "--lua-desync=fake" > "${TEST_DIR}/proc/12345/cmdline"
    touch "${TEST_DIR}/mock_iptables_ok"
    exit 0
fi
EOF
chmod +x "${TEST_DIR}/opt/zapret2/init.d/sysv/zapret2"

# Source patched libs
. "$TEST_DIR/lib/lock.sh"
. "$TEST_DIR/lib/config.sh"
. "$TEST_DIR/lib/strategy.sh"
. "$TEST_DIR/lib/status.sh"
. "$TEST_DIR/lib/safe_apply.sh"

echo "=== Running Tests ==="
fails=0

# Test 1: Lock Acquire and Release
Lock_Release
if Lock_Acquire; then
    echo "PASS: Lock_Acquire"
else
    echo "FAIL: Lock_Acquire"; fails=$((fails+1))
fi

if Lock_Acquire; then
    echo "FAIL: Lock_Acquire (should fail when already locked)"; fails=$((fails+1))
else
    echo "PASS: Lock_Acquire (rejected concurrent lock)"
fi

Lock_Release
if Lock_Acquire; then
    echo "PASS: Lock_Acquire (after release)"
else
    echo "FAIL: Lock_Acquire (after release)"; fails=$((fails+1))
fi
Lock_Release

# Test 2: Config Block Apply
echo "OLD_VAR=1" > "$TEST_DIR/opt/zapret2/config"
printf "NFQWS2_ENABLE=1\nNFQWS2_OPT=\"test\"\n" | Config_Apply_Block
if grep -q "OLD_VAR=1" "$TEST_DIR/opt/zapret2/config" && grep -q "NFQWS2_OPT=\"test\"" "$TEST_DIR/opt/zapret2/config"; then
    echo "PASS: Config_Apply_Block"
else
    echo "FAIL: Config_Apply_Block"; fails=$((fails+1))
fi

# Test 3: Strategy Generator
opt=$(Strategy_Generate_Opt "fake" "80,443")
if echo "$opt" | grep -q -- "--filter-tcp=80,443" && echo "$opt" | grep -q -- "--lua-desync=fake"; then
    echo "PASS: Strategy_Generate_Opt"
else
    echo "FAIL: Strategy_Generate_Opt ($opt)"; fails=$((fails+1))
fi

# Test 4: Safe Apply (Success)
rm -f "${TEST_DIR}/mock_restart_fail"
if Safe_Apply "--lua-desync=fake"; then
    echo "PASS: Safe_Apply (Success)"
else
    echo "FAIL: Safe_Apply (Success)"; fails=$((fails+1))
fi

# Test 5: Safe Apply (Rollback)
touch "${TEST_DIR}/mock_restart_fail"
if ! Safe_Apply "--lua-desync=fake"; then
    echo "PASS: Safe_Apply (Rollback detected failure)"
else
    echo "FAIL: Safe_Apply (Rollback should have failed)"; fails=$((fails+1))
fi

if [ $fails -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "$fails tests failed."
    exit 1
fi
