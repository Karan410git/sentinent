/**
 * Authentication middleware for Supabase token verification.
 *
 * Uses the Supabase client's auth.getUser(token) to validate
 * the Bearer token server-side. No manual JWT parsing.
 *
 * Attaches the authenticated user's ID to req.userId.
 * Rejects requests with missing or invalid tokens.
 */
const supabase = require('./supabase');

async function requireAuth(req, res, next) {
  if (!supabase) {
    console.error('[Auth] Supabase client not configured');
    return res.status(500).json({
      error: 'server_misconfigured',
      message: 'Authentication is not configured on the server.',
    });
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Authentication required.',
    });
  }

  const token = authHeader.slice(7);

  if (!token || token.length === 0) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Authentication required.',
    });
  }

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      console.error('[Auth] Token verification failed:', error?.message || 'no user');
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Invalid or expired token.',
      });
    }

    console.log('[Auth] ✓ Verified userId:', user.id);
    req.userId = user.id;
    next();
  } catch (err) {
    console.error('[Auth] Auth check error:', err.message);
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Invalid or expired token.',
    });
  }
}

module.exports = requireAuth;
