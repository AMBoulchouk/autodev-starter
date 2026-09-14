#!/usr/bin/env bash
# test_engine.sh - Automated Verification Suite for AutoDev Engine on POSIX
set -e

echo "================================================="
echo " Running AutoDev Engine Verification Suite (POSIX)"
echo "================================================="

PASSED=0
FAILED=0

assert_condition() {
    local condition="$1"
    local message="$2"
    if [ "$condition" -eq 1 ]; then
        echo -e "\033[32m[PASS]\033[0m $message"
        PASSED=$((PASSED + 1))
    else
        echo -e "\033[31m[FAIL]\033[0m $message"
        FAILED=$((FAILED + 1))
    fi
}

assert_success() {
    local exit_code="$1"
    local message="$2"
    if [ "$exit_code" -eq 0 ]; then
        echo -e "\033[32m[PASS]\033[0m $message"
        PASSED=$((PASSED + 1))
    else
        echo -e "\033[31m[FAIL]\033[0m $message"
        FAILED=$((FAILED + 1))
    fi
}

SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'autodev_test')
echo "Sandbox: $SANDBOX"

cleanup() {
    rm -rf "$SANDBOX"
    echo "Cleaned up sandbox."
}
trap cleanup EXIT

# Copy files
cp -r .autodev "$SANDBOX/.autodev"
cp AGENTS.md "$SANDBOX/AGENTS.md"
cp PRODUCT_BRIEF.md "$SANDBOX/PRODUCT_BRIEF.md"

cd "$SANDBOX"

# Clean up initial state for cold start
rm -f .autodev/state/progress.json .autodev/runtime.yaml .autodev/evidence/* 2>/dev/null || true
rm -rf .git 2>/dev/null || true

# Test 1: Cold start & bootstrap
echo "--- Test 1: Cold Start & Bootstrap ---"
chmod +x .autodev/commands/*
./.autodev/commands/bootstrap
[ -d ".git" ] && GIT_OK=1 || GIT_OK=0
assert_condition $GIT_OK "Git initialized by bootstrap"
[ -f ".autodev/state/progress.json" ] && PROG_OK=1 || PROG_OK=0
assert_condition $PROG_OK "progress.json created"
[ -f ".autodev/runtime.yaml" ] && RUNTIME_OK=1 || RUNTIME_OK=0
assert_condition $RUNTIME_OK "runtime.yaml created"

# Test 2: Inspect
echo ""
echo "--- Test 2: Inspect Diagnostic ---"
./.autodev/commands/inspect
assert_success $? "Inspect exited with code 0"

# Test 3: Validate
echo ""
echo "--- Test 3: Validate Governance ---"
./.autodev/commands/validate
assert_success $? "Validate exited with code 0"

# Test 4: Plan with Feature Dependencies
echo ""
echo "--- Test 4: Plan & Dependency Graph ---"
cat << 'EOF' > .autodev/features/F001-walking-skeleton.md
# Feature F001: Walking Skeleton
id: F001
depends_on: []
## Scenario
Given app boots
EOF

cat << 'EOF' > .autodev/features/F002-customer-auth.md
# Feature F002: Customer Auth
id: F002
depends_on: [F001]
## Scenario
Given customer logs in
EOF

./.autodev/commands/plan
assert_success $? "Plan exited with code 0"

# Test 5: Missing Runtime in Development
echo ""
echo "--- Test 5: Missing runtime.yaml in Development ---"
mv .autodev/runtime.yaml .autodev/runtime.yaml.bak
set +e
./.autodev/commands/test
TEST_EXIT=$?
set -e
[ $TEST_EXIT -ne 0 ] && MISS_OK=1 || MISS_OK=0
assert_condition $MISS_OK "test failed with code 1 when runtime.yaml is missing"
mv .autodev/runtime.yaml.bak .autodev/runtime.yaml

# Test 6: Contract Failure
echo ""
echo "--- Test 6: Failing Contract Transition ---"
cat << 'EOF' > .autodev/runtime.yaml
version: 1
commands:
  validate: ""
  test: "exit 42"
  build: ""
  run: ""
  verify: ""
EOF

set +e
./.autodev/commands/auto-cycle
FAIL_EXIT=$?
set -e
[ $FAIL_EXIT -ne 0 ] && CYCLE_FAIL_OK=1 || CYCLE_FAIL_OK=0
assert_condition $CYCLE_FAIL_OK "auto-cycle exited with non-zero on test failure"

# Test 7: Passing Cycle & Evidence Generation
echo ""
echo "--- Test 7: Passing Cycle & Evidence Generation ---"
cat << 'EOF' > .autodev/runtime.yaml
version: 1
commands:
  validate: "echo 'Validation OK'; exit 0"
  test: "echo 'Tests OK'; exit 0"
  build: "echo 'Build OK'; exit 0"
  run: ""
  verify: "echo 'Verify OK'; exit 0"
EOF

git config user.name "Test Agent" 2>/dev/null || true
git config user.email "test@autodev.local" 2>/dev/null || true
git add -A
git commit -m "initial test base" 2>/dev/null || true

./.autodev/commands/auto-cycle
assert_success $? "auto-cycle passed successfully"
[ -f ".autodev/evidence/F001.json" ] && EVI_OK=1 || EVI_OK=0
assert_condition $EVI_OK "Evidence file F001.json generated"

# Test 8: Git Safety - Forbidden Secret
echo ""
echo "--- Test 8: Git Safety - Forbidden Secret Detection ---"
echo "SECRET_KEY=123" > .env.production
set +e
./.autodev/commands/auto-cycle
SEC_EXIT=$?
set -e
[ $SEC_EXIT -ne 0 ] && SEC_OK=1 || SEC_OK=0
assert_condition $SEC_OK "auto-cycle blocked when forbidden .env exists"
rm -f .env.production

# Reset F002 to ready
python3 -c '
import json
with open(".autodev/state/progress.json", "r") as f: p = json.load(f)
p["features"]["F002"]["status"] = "ready"
p["current_feature"] = None
with open(".autodev/state/progress.json", "w") as f: json.dump(p, f, indent=2)
'

# Test 9: Git Safety - Protected Policy Modification
echo ""
echo "--- Test 9: Git Safety - Protected Policy Modification ---"
echo "# modified" >> .autodev/manifest.yaml
set +e
./.autodev/commands/auto-cycle
PROT_EXIT=$?
set -e
[ $PROT_EXIT -ne 0 ] && PROT_OK=1 || PROT_OK=0
assert_condition $PROT_OK "auto-cycle halted when protected file modified"
git checkout -- .autodev/manifest.yaml

# Reset F002 to ready
python3 -c '
import json
with open(".autodev/state/progress.json", "r") as f: p = json.load(f)
p["features"]["F002"]["status"] = "ready"
p["current_feature"] = None
with open(".autodev/state/progress.json", "w") as f: json.dump(p, f, indent=2)
'

# Test 10: Final Feature Completion & Backlog Completion
echo ""
echo "--- Test 10: Complete Backlog & Milestone ---"
./.autodev/commands/auto-cycle
assert_success $? "F002 completed successfully"
[ -f ".autodev/evidence/F002.json" ] && EVI2_OK=1 || EVI2_OK=0
assert_condition $EVI2_OK "Evidence file F002.json generated"

echo ""
echo "================================================="
echo " Test Suite Summary: $PASSED Passed, $FAILED Failed"
echo "================================================="

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
