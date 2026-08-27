const path = require('path');

let providerModule = null;
let ProviderClass = null;

function getProvider() {
  if (!ProviderClass) {
    const providerName = process.env.AI_PROVIDER || 'deepseek';
    
    switch (providerName.toLowerCase()) {
      case 'deepseek':
        ProviderClass = require('./deepseek');
        break;
      case 'groq':
        ProviderClass = require('./groq');
        break;
      default:
        throw new Error(`Unsupported AI provider: ${providerName}`);
    }
  }
  return ProviderClass;
}

module.exports = {
  getProvider,
  setProvider: (providerName) => {
    ProviderClass = null;
    providerModule = null;
    process.env.AI_PROVIDER = providerName;
  },
};