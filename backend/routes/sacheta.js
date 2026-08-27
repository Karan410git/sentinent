const express = require('express');
const router = express.Router();
const { getProvider } = require('../providers');
const memory = require('../lib/memory');
const { SYSTEM_PROMPT, MEMORY_EXTRACTION_PROMPT } = require('../prompts/system');

/**
 * POST /api/sacheta/respond
 *
 * Body:
 *   messages: Array<{role: 'user'|'sacheta', content: string}>
 *   conversationId: string (for logging/context)
 *
 * Returns:
 *   { content: string, model: string }
 */
router.post('/respond', async (req, res) => {
  try {
    const { messages, conversationId } = req.body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    // Load long-term memory context.
    const mem = await memory.loadMemory();
    const memoryContext = buildMemoryContext(mem);

    // Build context messages for the AI.
    const contextMessages = [
      { role: 'system', content: SYSTEM_PROMPT },
    ];

    if (memoryContext) {
      contextMessages.push({
        role: 'system',
        content: `Your long-term memory of this person:\n${memoryContext}\n\nWeave these memories naturally into your response. Reference them only when relevant — do not recite them.`,
      });
    }

    // Map conversation messages to API format.
    for (const msg of messages) {
      contextMessages.push({
        role: msg.role === 'sacheta' ? 'assistant' : 'user',
        content: msg.content,
      });
    }

    const provider = getProvider();
    const response = await provider.generate(contextMessages);

    res.json({
      content: response.content,
      model: response.model,
    });
  } catch (err) {
    console.error('[sacheta/respond] Error:', err.message);

    // Convert provider errors to safe application errors.
    if (err.message?.includes('API_KEY') || err.message?.includes('not configured')) {
      return res.status(503).json({
        error: 'sacheta_unavailable',
        message: 'The pages are quiet tonight. I cannot seem to reach beyond them.',
      });
    }

    if (err.status === 429 || err.message?.includes('rate')) {
      return res.status(429).json({
        error: 'rate_limited',
        message: 'The ink needs a moment to settle.',
      });
    }

    res.status(500).json({
      error: 'provider_error',
      message: 'The pages are quiet tonight. I cannot seem to reach beyond them.',
    });
  }
});

/**
 * POST /api/sacheta/extract-memory
 *
 * Body:
 *   messages: Array<{role: 'user'|'sacheta', content: string}>
 *
 * Runs memory extraction in the background.
 * Returns 204 immediately.
 */
router.post('/extract-memory', async (req, res) => {
  // Respond immediately — extraction runs in background.
  res.status(204).send();

  // Fire and forget.
  try {
    const { messages } = req.body;
    if (!messages || !Array.isArray(messages) || messages.length === 0) return;

    const extractionMessages = [
      { role: 'system', content: MEMORY_EXTRACTION_PROMPT },
    ];

    for (const msg of messages) {
      extractionMessages.push({
        role: msg.role === 'sacheta' ? 'assistant' : 'user',
        content: msg.content,
      });
    }

    const provider = getProvider();
    const response = await provider.generate(extractionMessages);

    // Parse the extracted memory, tolerating markdown fences.
    let extracted = null;
    try {
      let text = response.content.trim();
      if (text.startsWith('```')) {
        text = text.replace(/^```(?:json)?\s*\n?/, '').replace(/\n?```\s*$/, '');
      }
      extracted = JSON.parse(text);
    } catch (_) {
      // Parse failure — skip merge.
      return;
    }

    if (extracted) {
      await memory.mergeMemory(extracted);
    }
  } catch (_) {
    // Memory extraction is best-effort — never block.
  }
});

/**
 * GET /api/sacheta/memory
 *
 * Returns the current memory state (for debugging/inspection).
 */
router.get('/memory', async (req, res) => {
  try {
    const mem = await memory.loadMemory();
    res.json(mem);
  } catch (err) {
    res.status(500).json({ error: 'Failed to load memory' });
  }
});

function buildMemoryContext(mem) {
  const parts = [];

  if (mem.facts?.length > 0) {
    parts.push(`Known facts: ${mem.facts.join('; ')}`);
  }
  if (mem.themes?.length > 0) {
    parts.push(`Recurring themes: ${mem.themes.join(', ')}`);
  }
  if (mem.style?.tone) {
    parts.push(`Writing tone: ${mem.style.tone}`);
  }
  if (mem.style?.length) {
    parts.push(`Typical message length: ${mem.style.length}`);
  }

  return parts.join('\n');
}

module.exports = router;
