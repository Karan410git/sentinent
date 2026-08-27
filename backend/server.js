require('dotenv').config();

const express = require('express');
const cors = require('cors');
const sachetaRoutes = require('./routes/sacheta');
const { getProvider } = require('./providers');

const app = express();
const PORT = process.env.PORT || 3000;
const AI_PROVIDER = process.env.AI_PROVIDER || 'deepseek';

// Middleware.
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Request logging.
app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
  next();
});

// Routes.
app.use('/api/sacheta', sachetaRoutes);

// Health check.
app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Start.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Sacheta backend running on port ${PORT}`);
  console.log(`AI provider: ${AI_PROVIDER}`);

  if (AI_PROVIDER === 'deepseek') {
    if (!process.env.DEEPSEEK_API_KEY) {
      console.warn('⚠️  DEEPSEEK_API_KEY is not set. AI responses will fail.');
    } else {
      console.log(`DeepSeek model: ${process.env.DEEPSEEK_MODEL || '(not set)'}`);
    }
  }
});