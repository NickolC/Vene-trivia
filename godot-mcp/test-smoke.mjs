// Smoke test: talk to the godot MCP server over stdio JSON-RPC.
// Run from repo root so cwd matches how Claude launches it.
import { spawn } from 'child_process';

const proc = spawn('node', ['godot-mcp/build/index.js'], {
  stdio: ['pipe', 'pipe', 'inherit'],
  env: { ...process.env, DEBUG: 'true' },
});

let buf = '';
const pending = new Map();
proc.stdout.on('data', (d) => {
  buf += d.toString();
  let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch { continue; }
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  }
});

let id = 0;
function rpc(method, params) {
  const myId = ++id;
  return new Promise((resolve) => {
    pending.set(myId, resolve);
    proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: myId, method, params }) + '\n');
  });
}

const projectPath = process.cwd();

(async () => {
  await rpc('initialize', {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'smoke', version: '1.0' },
  });
  proc.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');

  const tools = await rpc('tools/list', {});
  console.log('\n=== TOOLS ===');
  for (const t of tools.result.tools) console.log('-', t.name);

  console.log('\n=== get_godot_version ===');
  const ver = await rpc('tools/call', { name: 'get_godot_version', arguments: {} });
  console.log(JSON.stringify(ver.result?.content ?? ver.error, null, 2));

  console.log('\n=== get_project_info ===');
  const info = await rpc('tools/call', {
    name: 'get_project_info',
    arguments: { projectPath },
  });
  console.log(JSON.stringify(info.result?.content ?? info.error, null, 2));

  proc.kill();
  process.exit(0);
})();
