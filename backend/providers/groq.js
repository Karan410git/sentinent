const Groq = require('groq-sdk');

let client = null;

function getClient() {
  if (!client) {
    const apiKey = process.env.GROQ_API_KEY;

    if (!apiKey) {
      throw new Error('GROQ_API_KEY is not configured');
    }

    client = new Groq({ apiKey });
  }

  return client;
}

function cleanResponse(content) {
  if (!content || typeof content !== 'string') {
    return '';
  }

  return content
    .replace(/<think>[\s\S]*?<\/think>/gi, '')
    .trim();
}

async function generate(messages) {
  const groq = getClient();
  const model = process.env.GROQ_MODEL;

  if (!model) {
    throw new Error('GROQ_MODEL is not configured');
  }

  const response = await groq.chat.completions.create({
    model,
    messages,
    reasoning_effort: 'none',
    temperature: 0.7,
    max_tokens: 500,
  });

  const choice = response.choices?.[0];

  if (!choice?.message?.content) {
    throw new Error('Empty response from Groq');
  }

  const content = cleanResponse(choice.message.content);

  if (!content) {
    throw new Error('Empty response after cleaning');
  }

  return {
    content,
    model: response.model || model,
  };
}

module.exports = { generate };