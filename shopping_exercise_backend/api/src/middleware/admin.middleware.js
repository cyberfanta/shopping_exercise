const adminMiddleware = (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: { message: 'Unauthorized', status: 401 } });
    }

    // Check if user is admin or superadmin
    if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
      return res.status(403).json({ 
        error: { 
          message: 'Access denied. Admin privileges required.', 
          status: 403 
        } 
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
  }
};

module.exports = adminMiddleware;

