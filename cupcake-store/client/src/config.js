const API_BASE = process.env.NODE_ENV === 'production'
  ? '/api'  // Em produção, usa URL relativa (mesmo domínio)
  : 'http://localhost:3001/api';  // Em dev, usa localhost

export default API_BASE;