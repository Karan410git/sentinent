const supabase = require('./supabase');

/**
 * Load Sacheta's long-term memory for a user from Supabase.
 * @param {string} userId - The authenticated user's ID.
 * @returns {Promise<Object>}
 */
async function loadMemory(userId) {
  if (!supabase || !userId) {
    return { facts: [], themes: [], style: { tone: 'neutral', length: 'medium' } };
  }

  try {
    const { data, error } = await supabase
      .from('memories')
      .select('content')
      .eq('user_id', userId)
      .maybeSingle();

    if (error || !data || !data.content) {
      return { facts: [], themes: [], style: { tone: 'neutral', length: 'medium' } };
    }

    return data.content;
  } catch (_) {
    return { facts: [], themes: [], style: { tone: 'neutral', length: 'medium' } };
  }
}

/**
 * Save Sacheta's long-term memory for a user in Supabase.
 * @param {string} userId - The authenticated user's ID.
 * @param {Object} memory
 */
async function saveMemory(userId, memory) {
  if (!supabase || !userId) return;

  try {
    await supabase
      .from('memories')
      .upsert(
        { user_id: userId, content: memory },
        { onConflict: 'user_id' }
      );
  } catch (_) {
    // Best-effort — never block.
  }
}

/**
 * Merge newly extracted facts into existing memory for a user.
 * @param {string} userId - The authenticated user's ID.
 * @param {Object} extracted - { facts: [], themes: [], style: {} }
 */
async function mergeMemory(userId, extracted) {
  const existing = await loadMemory(userId);

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

  await saveMemory(userId, merged);
  return merged;
}

module.exports = { loadMemory, saveMemory, mergeMemory };
