# Bug Report: Parallel Approvals Race Condition

## Summary

When Claude Code sends multiple tool calls in parallel that require approval, only the first approval can be resolved (approved or denied). All subsequent approvals fail with `MCP error -32603: Failed to get approval status`.

## Status

**Confirmed & Reproducible** - Bug occurs consistently when testing parallel tool calls.

## Environment

- WSL2 running remote-bridge (`scripts/dev-bridge.sh`)
- Windows running WUI (Tauri/React)
- Connection via HTTP to daemon at `http://<WSL-IP>:7777`

## Symptoms

1. **Parallel approvals**: When 2+ tool calls are sent simultaneously:
   - 2 approval buttons appear in WUI
   - User can approve/deny only the **first** one
   - The **second** immediately fails with MCP error

2. **Sequential approvals**: Work correctly - each approval can be approved/denied in order

3. **Interrupt doesn't work**: During pending approvals, the "Interrupt" button fails with:
   ```
   Failed to continue session: cannot continue session with status waiting_input
   ```

## Error Messages

```
MCP error -32603: MCP error -32603: Failed to process approval: MCP error -32603: Failed to get approval status
```

## Root Cause Analysis

The bug is in `hlyr/src/mcp.ts` - a **shared DaemonClient connection** that gets closed prematurely.

### Code Flow

1. MCP server creates ONE `DaemonClient` instance (line 44):
   ```typescript
   const daemonClient = new DaemonClient(socketPath)
   ```

2. Each tool call handler:
   ```typescript
   try {
     await daemonClient.connect()       // Line 93
     // ... creates approval, polls for status ...
   } finally {
     daemonClient.close()               // Line 176 - PROBLEM!
   }
   ```

3. When parallel requests come in:
   - Request A: connects, creates approval A, starts polling
   - Request B: connects (replaces socket in `this.conn`), creates approval B, starts polling
   - Request A: approval resolved → **`close()` kills the shared connection**
   - Request B: tries to poll → **connection is dead** → ERROR

### Relevant Code Locations

| File | Lines | Description |
|------|-------|-------------|
| `hlyr/src/mcp.ts` | 44 | Single DaemonClient instance created |
| `hlyr/src/mcp.ts` | 93-94 | Connect called per request |
| `hlyr/src/mcp.ts` | 107-139 | Polling loop for approval status |
| `hlyr/src/mcp.ts` | 174-177 | Finally block closes shared connection |
| `hlyr/src/daemonClient.ts` | 120-136 | `connect()` overwrites existing `this.conn` |
| `hlyr/src/daemonClient.ts` | 387-392 | `close()` destroys the socket |

### Secondary Issue: Session Status Race

In `hld/approval/manager.go`:

When an approval is resolved, the session status changes:
- **Pending approval** → Session status = `waiting_input` (line 101)
- **Approval resolved** → Session status = `running` (lines 173-177, 210-214)

If two approvals are pending and one is resolved:
1. First approval resolved → session becomes `running`
2. Second approval still pending, but session is no longer `waiting_input`

This may cause inconsistent state, but the primary issue is the connection closure.

## Test Cases

### Working (Sequential)
```bash
# First approval
echo "Test 1: $(date)"  # Approved by user

# Second approval (after first completes)
echo "Test 2: $(date)"  # Can be approved/denied
```

### Failing (Parallel)
```bash
# Both sent simultaneously
echo "Parallel 1" &
echo "Parallel 2" &  # One of these fails with MCP error
```

### Specific Trigger Commands
These grep commands consistently reproduce the bug:
```bash
# Parallel call 1
echo "=== new_approval events ===" && grep 'publishing event.*type=new_approval' ~/.humanlayer/logs/remote-bridge/daemon-remote-*.log | head -10

# Parallel call 2
echo "=== Approval creation ===" && grep -E "(created approval|approved tool call)" ~/.humanlayer/logs/remote-bridge/daemon-remote-*.log | tail -20
```

## Proposed Fixes

### Option 1: Connection Per Request (Recommended)

Create a new DaemonClient for each tool call instead of sharing:

```typescript
// In mcp.ts, inside CallToolRequestSchema handler:
const daemonClient = new DaemonClient(socketPath)  // Create new per request
try {
  await daemonClient.connect()
  // ... handle approval ...
} finally {
  daemonClient.close()  // Only closes this request's connection
}
```

### Option 2: Reference Counting

Add connection reference counting to DaemonClient:
- Track active requests
- Only close socket when all requests complete

### Option 3: Connection Pool

Implement a connection pool that:
- Maintains multiple connections
- Assigns one per concurrent request
- Reuses connections when available

## Testing Reproduction Steps

1. Start remote-bridge in WSL: `./scripts/dev-bridge.sh`
2. Start WUI in Windows: `dev-wui-remote.ps1`
3. Disable auto-accept and bypass permissions
4. In Claude Code, send two parallel bash commands
5. Observe: 2 buttons appear in WUI
6. Approve the first one
7. Second one fails with MCP error

## Log Files for Analysis

```
~/.humanlayer/logs/remote-bridge/daemon-remote-*-debug.log
~/.humanlayer/logs/remote-bridge/daemon-remote-*-info.log
~/.humanlayer/logs/mcp-claude-approvals-*.log
```

## Related Issues

- Interrupt button fails during `waiting_input` status
- Session status race when multiple approvals pending

## Priority

**High** - Blocks normal usage when Claude Code sends parallel tool calls (which is common behavior for independent operations).

---

*Report created: 2025-11-25*
*Session: WSL2 + Windows Remote Bridge Testing*
