require('dotenv').config();

const express = require('express');
const cors = require('cors');
const sachetaRoutes = require('./routes/sacheta');

const app = express();
const PORT = process.env.PORT || 3000;
const AI_PROVIDER = process.env.AI_PROVIDER || 'deepseek';
// Middleware.
app.use(cors({
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
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

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Sacheta backend running on port ${PORT}`);
    console.log(`AI provider: ${AI_PROVIDER}`);
  });
}

module.exports = app;