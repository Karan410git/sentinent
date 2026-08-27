const fs = require('fs');
const path = require('path');

const MEMORY_DIR = path.join(__dirname, '..', 'data');

function ensureDir() {
  if (!fs.existsSync(MEMORY_DIR)) {
    fs.mkdirSync(MEMORY_DIR, { recursive: true });
  }
}

function memoryPath() {
  return path.join(MEMORY_DIR, 'sacheta_memory.json');
}

/**
 * Load Sacheta's long-term memory.
 * @returns {Promise<Object>}
 */
async function loadMemory() {
  ensureDir();
  const p = memoryPath();
  if (!fs.existsSync(p)) {
    return { facts: [], themes: [], style: { tone: 'neutral', length: 'medium' } };
  }
  const raw = fs.readFileSync(p, 'utf-8');
  return JSON.parse(raw);
}

/**
 * Save Sacheta's long-term memory.
 * @param {Object} memory
 */
async function saveMemory(memory) {
  ensureDir();
  memory.lastUpdated = new Date().toISOString();
  fs.writeFileSync(memoryPath(), JSON.stringify(memory, null, 2));
}

/**
 * Merge newly extracted facts into existing memory.
 * @param {Object} extracted - { facts: [], themes: [], style: {} }
 */
async function mergeMemory(extracted) {
  const existing = await loadMemory();

  // Merge facts — deduplicate.
  const oldFacts = new Set(existing.facts || []);
  const newFacts = extracted.facts || [];
  newFacts.forEach(f => oldFacts.add(f));

  // Merge themes — deduplicate.
  const oldThemes = new Set(existing.themes || []);
  const newThemes = extracted.themes || [];
  newThemes.forEach(t => oldThemes.add(t));

  // Update style (latest wins).
  const oldStyle = existing.style || {};
  const newStyle = extracted.style || {};

  const merged = {
    facts: [...oldFacts],
    themes: [...oldThemes],
    style: {
      tone: newStyle.tone || oldStyle.tone || 'neutral',
      length: newStyle.length || oldStyle.length || 'medium',
    },
    lastUpdated: new Date().toISOString(),
  };

  await saveMemory(merged);
  return merged;
}

module.exports = { loadMemory, saveMemory, mergeMemory };
