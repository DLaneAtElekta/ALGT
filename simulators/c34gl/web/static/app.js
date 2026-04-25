// =============================================================================
// c34gl — See-Through 4GL Frontend
// =============================================================================

const API = '/api/c34gl';
const SEAGULL_IMG = '/static/seagull.png';

let state = { sessionId: null, data: null };

// =============================================================================
// API Layer
// =============================================================================

async function api(path, opts = {}) {
  const url = API + path;
  const headers = { 'Content-Type': 'application/json' };
  const res = await fetch(url, { ...opts, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error || res.statusText);
  }
  return res.json();
}

async function createSession() {
  const data = await api('/sessions', { method: 'POST', body: '{}' });
  state.sessionId = data.sessionId;
  state.data = data;
  render();
}

async function stepForm(formId, event) {
  try {
    const data = await api(
      `/sessions/${state.sessionId}/step/${formId}`,
      { method: 'POST', body: JSON.stringify({ event }) }
    );
    state.data = data;
    render();
    // Auto-scroll tape to end
    const tape = document.querySelector('.tape');
    if (tape) tape.scrollLeft = tape.scrollWidth;
  } catch (e) {
    console.error('Step failed:', e);
  }
}

async function resetSession() {
  const data = await api(`/sessions/${state.sessionId}/reset`, { method: 'POST' });
  state.data = data;
  render();
}

// =============================================================================
// Render
// =============================================================================

function render() {
  const app = document.getElementById('app');
  if (!state.data) {
    app.innerHTML = '<div class="loading">Initializing c34gl...</div>';
    return;
  }
  const d = state.data;
  app.innerHTML = `
    ${renderHeader(d)}
    <div class="forms-row">
      ${renderFormPanel('incrementer', d)}
      ${renderFormPanel('doubler', d)}
    </div>
    ${renderTape(d)}
    ${renderTable(d)}
    ${renderLLMPanel(d)}
  `;
  attachHandlers();
}

// =============================================================================
// Header + Controls
// =============================================================================

function renderHeader(d) {
  return `
    <div class="header">
      <img src="${SEAGULL_IMG}" alt="c34gl" class="header-avatar">
      <div class="header-title"><h1>C34GL</h1><span class="header-subtitle">See-Through 4GL</span></div>
      <span class="step-count">step ${d.stepCount}</span>
      <div class="controls">
        <button onclick="resetSession()">Reset &#x27F2;</button>
      </div>
    </div>`;
}

// =============================================================================
// Form Panels with DCG State Diagram
// =============================================================================

function renderFormPanel(formId, d) {
  const f = d.forms[formId];
  if (!f) return '';
  const localsStr = Object.entries(f.locals)
    .map(([k,v]) => `${v}`)
    .join(', ');
  const localLabel = formId === 'incrementer' ? 'count' : 'value';

  return `
    <div class="form-panel ${formId}">
      <div class="form-title">
        ${formId === 'incrementer' ? 'Incrementer' : 'Doubler'}
        <span class="spid-badge">${f.spid}</span>
      </div>
      <div class="form-body">
        ${renderDCGDiagram(formId, f.win)}
        <div class="locals">${localLabel} = ${localsStr}</div>
        <div class="events">
          ${f.availableEvents.map(e =>
            `<button data-form="${formId}" data-event="${e}">${e}</button>`
          ).join('')}
        </div>
        <div class="history">
          ${f.history.length > 0
            ? f.history.slice(-6).join(' &rarr; ')
            : '<em>no events yet</em>'}
        </div>
      </div>
    </div>`;
}

function renderDCGDiagram(formId, currentWin) {
  // Minimal DCG state diagram: idle → running → closed
  const states = ['idle', 'running', 'closed'];
  const events = formId === 'incrementer'
    ? { 'idle': 'start', 'running': 'inc/stop' }
    : { 'idle': 'start', 'running': 'dbl/stop' };

  const nodes = states.map(s => {
    const active = s === currentWin;
    const cls = active ? 'dcg-node active' : 'dcg-node';
    return `<span class="${cls}">${s}</span>`;
  }).join('<span class="dcg-arrow">&rarr;</span>');

  return `<div class="dcg-diagram">${nodes}</div>`;
}

// =============================================================================
// Tape (Transaction Log Minimap with Syntax Highlighting)
// =============================================================================

function renderTape(d) {
  const tape = d.tape || [];

  // Build fn_dblog-style text lines for minimap canvas rendering
  const minimapLines = tape.map(e => {
    const seq = String(e.txId).padStart(3, ' ');
    const op = fnDblogOp(e.op);
    const tran = (e.spid || 'NULL').padEnd(8);
    const tbl = (e.table || '').padEnd(12);
    const note = e.op === 'compensation' ? '(UNDO)' : '';
    return {
      text: `${seq}|${op}|${tran}|${tbl}|${note}`,
      spid: e.spid || 'seed',
      // Token boundaries for syntax highlighting
      regions: [
        { start: 0, end: 3, type: 'seq' },
        { start: 4, end: 4 + op.length, type: 'op' },
        { start: 4 + op.length + 1, end: 4 + op.length + 1 + tran.length, type: 'tran' },
        { start: 4 + op.length + 1 + tran.length + 1, end: 4 + op.length + 1 + tran.length + 1 + tbl.length, type: 'tbl' },
        { start: 4 + op.length + 1 + tran.length + 1 + tbl.length + 1, end: 999, type: 'note' }
      ]
    };
  });

  // Head position indicators on minimap (shown as labels)
  const headLabels = [];
  if (d.forms.incrementer && d.forms.incrementer.lastTx !== 'none')
    headLabels.push(`<span class="head-indicator head-a">▲ A @ #${d.forms.incrementer.lastTx}</span>`);
  if (d.forms.doubler && d.forms.doubler.lastTx !== 'none')
    headLabels.push(`<span class="head-indicator head-b">▲ B @ #${d.forms.doubler.lastTx}</span>`);
  const headsHtml = headLabels.length > 0
    ? `<div class="tape-heads-inline">${headLabels.join(' ')}</div>` : '';

  // Store minimap data for canvas drawing after render
  window._minimapData = minimapLines;

  return `
    <div class="tape-section">
      <div class="tape-label">fn_dblog ${headsHtml}</div>
      <div class="tape-minimap"><canvas id="minimap-canvas"></canvas></div>
    </div>`;
}

// =============================================================================
// Materialized Table
// =============================================================================

function renderTable(d) {
  const rows = (d.tables && d.tables.counter) || [];
  if (rows.length === 0) return '';
  const cols = Object.keys(rows[0]);
  return `
    <div class="table-section">
      <div class="tape-label">Materialized: counter</div>
      <table class="materialized-table">
        <thead><tr>${cols.map(c => `<th>${c}</th>`).join('')}</tr></thead>
        <tbody>
          ${rows.map(r =>
            `<tr>${cols.map(c => `<td>${r[c]}</td>`).join('')}</tr>`
          ).join('')}
        </tbody>
      </table>
    </div>`;
}

// =============================================================================
// LLM Observer Panel
// =============================================================================

function renderLLMPanel(d) {
  const commentary = generateCommentary(d);
  return `
    <div class="llm-panel">
      <img src="${SEAGULL_IMG}" alt="c34gl" class="llm-avatar">
      <div class="llm-text">${commentary}</div>
    </div>`;
}

function generateCommentary(d) {
  const tape = d.tape || [];
  const counter = (d.tables && d.tables.counter && d.tables.counter[0]) || {};
  const inc = d.forms.incrementer;
  const dbl = d.forms.doubler;

  if (d.stepCount === 0) {
    return 'Counter initialized to 0. Both forms are idle. Start one to begin.';
  }

  const parts = [];
  parts.push(`Counter is <strong>${counter.value}</strong> after ${d.stepCount} step${d.stepCount !== 1 ? 's' : ''}.`);

  // Detect stale read potential
  if (inc && inc.win === 'running' && dbl && dbl.win === 'running') {
    if (inc.locals.count !== counter.value) {
      parts.push(`Incrementer's local count (${inc.locals.count}) is stale — tape shows ${counter.value}.`);
    }
    if (dbl.locals.value !== counter.value) {
      parts.push(`Doubler's local value (${dbl.locals.value}) is stale — tape shows ${counter.value}.`);
    }
  }

  // Last event
  if (tape.length > 1) {
    const last = tape[tape.length - 1];
    if (last.op === 'update') {
      const who = last.spid === 'spid_a' ? 'Incrementer' : 'Doubler';
      parts.push(`Last write by ${who}: ${last.summary}`);
    }
  }

  return parts.join(' ');
}

// =============================================================================
// Event Handlers
// =============================================================================

function attachHandlers() {
  document.querySelectorAll('.events button').forEach(btn => {
    btn.addEventListener('click', () => {
      const formId = btn.dataset.form;
      const event = btn.dataset.event;
      stepForm(formId, event);
    });
  });
  drawMinimap();
}

// =============================================================================
// Minimap Canvas — 2px per character, syntax colored
// =============================================================================

const MINIMAP_COLORS = {
  // Per-token colors (fn_dblog syntax highlighting)
  seq: '#6b7688', // dim gray for sequence number
  op: '#ff7b72', // red-orange for LOP_ operation keywords
  tran: '#79c0ff', // light blue for transaction/spid name
  tbl: '#c084fc', // purple for table name
  note: '#ffa657', // orange for (UNDO) annotations
  pipe: '#3a4250', // dim for pipe delimiters
  // Per-SPID gutter colors
  spid_a: '#3b82f6',
  spid_b: '#10b981',
  seed: '#6b7688',
  unknown: '#4a5568'
};

function drawMinimap() {
  const canvas = document.getElementById('minimap-canvas');
  const lines = window._minimapData;
  if (!canvas || !lines || lines.length === 0) return;

  const PX = 2; // pixels per character
  const LINE_H = 3; // pixels per line
  const GUTTER = 4; // gutter width for SPID color bar
  const maxCols = 80;
  const w = GUTTER + maxCols * PX;
  const h = Math.max(lines.length * LINE_H, 6);

  canvas.width = w;
  canvas.height = h;
  canvas.style.height = h + 'px';

  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#1a1e2e';
  ctx.fillRect(0, 0, w, h);

  lines.forEach((line, row) => {
    const y = row * LINE_H;
    const text = line.text;
    const spid = line.spid;
    const regions = line.regions;

    // Gutter: SPID color bar
    ctx.fillStyle = MINIMAP_COLORS[spid] || MINIMAP_COLORS.unknown;
    ctx.fillRect(0, y, GUTTER - 1, LINE_H - 1);

    // Characters: color by fn_dblog token region
    for (let i = 0; i < text.length && i < maxCols; i++) {
      const ch = text[i];
      if (ch === '|') {
        ctx.fillStyle = MINIMAP_COLORS.pipe;
        ctx.fillRect(GUTTER + i * PX, y, PX, LINE_H - 1);
        continue;
      }
      if (ch === ' ') continue;

      // Find which region this char belongs to
      let color = MINIMAP_COLORS.seq;
      for (const r of regions) {
        if (i >= r.start && i < r.end) {
          color = MINIMAP_COLORS[r.type] || color;
          break;
        }
      }

      ctx.fillStyle = color;
      ctx.fillRect(GUTTER + i * PX, y, PX, LINE_H - 1);
    }
  });
}

// =============================================================================
// Utilities
// =============================================================================

function fnDblogOp(op) {
  const map = {
    insert: 'LOP_INSERT_ROWS',
    update: 'LOP_MODIFY_ROW',
    delete: 'LOP_DELETE_ROWS',
    compensation: 'LOP_MODIFY_ROW',
    begin_tran: 'LOP_BEGIN_XACT',
    commit: 'LOP_COMMIT_XACT',
    abort: 'LOP_ABORT_XACT',
    savepoint: 'LOP_SAVE_XACT',
    unknown: 'LOP_UNKNOWN'
  };
  return (map[op] || 'LOP_' + op.toUpperCase()).padEnd(18);
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function truncate(s, n) {
  s = String(s);
  return s.length > n ? s.slice(0, n) + '…' : s;
}

// =============================================================================
// Init
// =============================================================================

createSession();
