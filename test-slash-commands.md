# Manual Test Plan for Slash Commands Fix

## Test Setup
1. Make sure the daemon is running: `cd hld && go run .`
2. Make sure the UI is running: `cd humanlayer-wui && bun run dev`
3. Ensure you have slash commands in `.claude/commands/` directory

## Test Cases

### Test 1: Existing Draft with ID
1. Navigate to an existing draft: `/sessions/draft?id=XXX`
2. Click in the editor
3. Type `/`
4. **Expected**: Slash commands dropdown should appear with available commands
5. **Verify**: Console shows no errors about missing session context

### Test 2: New Draft Creation
1. Press 'c' to create new draft (or navigate to `/sessions/draft`)
2. Start typing in the editor to trigger draft creation
3. Type `/`
4. **Expected**: Slash commands dropdown should appear immediately after draft creation
5. **Verify**: Commands are fetched and displayed

### Test 3: File Mentions
1. In a draft session, type `@`
2. **Expected**: File search dropdown should appear
3. **Verify**: Files from the working directory are searchable

### Test 4: Navigation Between Drafts
1. Create draft A, verify slash commands work
2. Navigate to draft B
3. **Expected**: Slash commands work in draft B
4. Go back to draft A
5. **Expected**: Slash commands still work in draft A

### Test 5: Active Sessions Still Work
1. Launch a draft to make it active
2. Navigate to the active session
3. Type `/`
4. **Expected**: Slash commands still work in active sessions
5. **Verify**: No regression in existing functionality

## Console Checks
- No errors about `activeSessionDetail` being null
- No errors about missing session ID
- Network tab shows GET requests to `/slash-commands` endpoint when typing `/`

## Success Criteria
- [ ] All 5 test cases pass
- [ ] No console errors
- [ ] Slash commands work identically in draft and active sessions


curl -s -X POST http://localhost:17650/invoke -H 'Content-Type: application/json' -d '{"cmd":"get_daemon_info"}'
curl -s -X POST http://localhost:17650/invoke -H 'Content-Type: application/json' -d '{"cmd":"start_daemon","args":{"port":7777}}'

VITE_REMOTE_TAURI_SHIM=1 VITE_TAURI_BRIDGE_URL=http://localhost:17650 VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777 bun run tauri dev
VITE_REMOTE_TAURI_SHIM=1 VITE_TAURI_BRIDGE_URL=http://localhost:17650 VITE_HUMANLAYER_DAEMON_URL=http://localhost:7777 bun run dev


<tool_use_error>Error calling tool (Write): MCP error -32603: MCP error -32603: Failed to process approval: Failed to connect to daemon: connect ENOENT /home/flori/.humanlayer/daemon-remote.sock</tool_use_error>


Der Daemon wurde über die remote-bridge gestartet, per invoke befehl.



cd humanlayer-wui && bun run remote-bridge



-> curl -s -X POST http://localhost:17650/invoke -H 'Content-Type: application/json' -d '{"cmd":"start_daemon","args":{"port":7777}}'



Wenn claude code files schreiben will und ein approval braucht, kam dieser Fehler hier:



<tool_use_error>Error calling tool (Write): MCP error -32603: MCP error -32603: Failed to process approval: Failed to connect to daemon: connect ENOENT /home/flori/.humanlayer/daemon-remote.sock</tool_use_error>



Wird der MCP Server richtig mit gestaret oder ist da was noch nciht ganz zusammen?