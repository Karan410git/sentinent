const https = require('https');

const DEEPSEEK_API_URL = 'api.deepseek.com';
const DEEPSEEK_API_PATH = '/v1/chat/completions';

/**
 * Build the HTTP request options for DeepSeek.
 * Model and API key are read from environment variables.
 */
function getRequestOptions() {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  const model = process.env.DEEPSEEK_MODEL;

  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY is not configured');
  }
  if (!model) {
    throw new Error('DEEPSEEK_MODEL is not configured');
  }

  return {
    apiKey,
    model,
  };
}

/**
 * Send a chat completion request to DeepSeek via HTTPS.
 * @param {Array<{role: string, content: string}>} messages
 * @returns {Promise<Object>}
 */
function callDeepSeek(messages) {
  return new Promise((resolve, reject) => {
    const { apiKey, model } = getRequestOptions();

    const requestBody = JSON.stringify({
      model,
      messages,
      temperature: 0.85,
      max_tokens: 800,
      stream: false,
    });

    const options = {
      hostname: DEEPSEEK_API_URL,
      port: 443,
      path: DEEPSEEK_API_PATH,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'Content-Length': Buffer.byteLength(requestBody),
      },
      timeout: 30000,
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          const error = new Error(`DeepSeek API error: HTTP ${res.statusCode}`);
          error.status = res.statusCode;
          error.body = data;
          reject(error);
          return;
        }
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error('Malformed response from DeepSeek'));
        }
      });
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('DeepSeek request timed out'));
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(requestBody);
    req.end();
  });
}

/**
 * Generate a response from DeepSeek.
 * @param {Array<{role: string, content: string}>} messages
 * @returns {Promise<{content: string, model: string}>}
 */
async function generate(messages) {
  const response = await callDeepSeek(messages);

  const choice = response.choices?.[0];
  if (!choice?.message?.content) {
    throw new Error('Empty response from DeepSeek');
  }

  return {
    content: choice.message.content,
    model: response.model || process.env.DEEPSEEK_MODEL,
  };
}

module.exports = { generate };
