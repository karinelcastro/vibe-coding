#!/bin/bash

echo "❤️ Instalando Sistema de Favoritos Completo..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# ==========================================
# BACKEND - Adicionar tabela e rotas de favoritos
# ==========================================

echo "📦 Atualizando backend com sistema de favoritos..."

cat > backend/server.js << 'EOFBACKEND'
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());
app.use('/images', express.static(path.join(__dirname, 'public/images')));

const db = new sqlite3.Database('./database/cupcakes.db');

db.serialize(() => {
  // Tabela de usuários
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabela de cupcakes
  db.run(`CREATE TABLE IF NOT EXISTS cupcakes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image_url TEXT,
    category TEXT,
    available BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Tabela de favoritos (NOVA!)
  db.run(`CREATE TABLE IF NOT EXISTS favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    cupcake_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY(cupcake_id) REFERENCES cupcakes(id) ON DELETE CASCADE,
    UNIQUE(user_id, cupcake_id)
  )`);

  // Tabela de pedidos
  db.run(`CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id)
  )`);

  // Tabela de itens do pedido
  db.run(`CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER,
    cupcake_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id),
    FOREIGN KEY(cupcake_id) REFERENCES cupcakes(id)
  )`);

  // Inserir cupcakes se não existirem
  const checkCupcakes = db.prepare("SELECT COUNT(*) as count FROM cupcakes");
  checkCupcakes.get((err, row) => {
    if (row.count === 0) {
      const insert = db.prepare(`INSERT INTO cupcakes (name, description, price, image_url, category) VALUES (?, ?, ?, ?, ?)`);
      
      const cupcakes = [
        ['Cupcake de Chocolate', 'Delicioso cupcake de chocolate com cobertura cremosa', 8.50, 'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=400&h=300&fit=crop', 'chocolate'],
        ['Cupcake de Baunilha', 'Cupcake clássico de baunilha com buttercream', 7.50, 'https://images.unsplash.com/photo-1426869884541-df7117556757?w=400&h=300&fit=crop', 'baunilha'],
        ['Cupcake Red Velvet', 'O famoso red velvet com cream cheese', 9.50, 'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?w=400&h=300&fit=crop', 'especial'],
        ['Cupcake de Morango', 'Cupcake de morango com pedaços da fruta', 8.00, 'https://images.unsplash.com/photo-1519915212116-7cfef71f1d3e?w=400&h=300&fit=crop', 'frutas'],
        ['Cupcake de Limão', 'Refrescante cupcake de limão com cobertura cítrica', 8.00, 'https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=400&h=300&fit=crop', 'frutas'],
        ['Cupcake de Nutella', 'Irresistível cupcake recheado com Nutella', 10.00, 'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=400&h=300&fit=crop', 'especial']
      ];

      cupcakes.forEach(cupcake => {
        insert.run(cupcake);
      });
      insert.finalize();
      console.log('✅ Cupcakes inseridos!');
    }
  });
  checkCupcakes.finalize();
});

// ==========================================
// ROTAS DE AUTENTICAÇÃO
// ==========================================

app.post('/api/auth/register', async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: 'A senha deve ter no mínimo 6 caracteres' });
  }

  db.get('SELECT id FROM users WHERE email = ?', [email], async (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Erro ao verificar email' });
    }

    if (row) {
      return res.status(400).json({ error: 'Este email já está cadastrado' });
    }

    try {
      const hashedPassword = await bcrypt.hash(password, 10);

      db.run(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [name, email, hashedPassword],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Erro ao criar usuário' });
          }

          console.log('✅ Usuário criado:', name);
          res.json({
            success: true,
            user: { id: this.lastID, name, email },
            message: 'Usuário cadastrado com sucesso!'
          });
        }
      );
    } catch (error) {
      res.status(500).json({ error: 'Erro ao processar senha' });
    }
  });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email e senha são obrigatórios' });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) {
      return res.status(500).json({ error: 'Erro ao buscar usuário' });
    }

    if (!user) {
      return res.status(401).json({ error: 'Email ou senha incorretos' });
    }

    try {
      const passwordMatch = await bcrypt.compare(password, user.password);

      if (!passwordMatch) {
        return res.status(401).json({ error: 'Email ou senha incorretos' });
      }

      console.log('✅ Login bem-sucedido:', user.name);
      res.json({
        success: true,
        user: { id: user.id, name: user.name, email: user.email },
        message: 'Login realizado com sucesso!'
      });
    } catch (error) {
      res.status(500).json({ error: 'Erro ao verificar senha' });
    }
  });
});

// ==========================================
// ROTAS DE FAVORITOS (NOVAS!)
// ==========================================

// Adicionar aos favoritos
app.post('/api/favorites', (req, res) => {
  const { userId, cupcakeId } = req.body;

  if (!userId || !cupcakeId) {
    return res.status(400).json({ error: 'userId e cupcakeId são obrigatórios' });
  }

  db.run(
    'INSERT OR IGNORE INTO favorites (user_id, cupcake_id) VALUES (?, ?)',
    [userId, cupcakeId],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      console.log('❤️ Favorito adicionado:', userId, cupcakeId);
      res.json({ success: true, message: 'Adicionado aos favoritos!' });
    }
  );
});

// Remover dos favoritos
app.delete('/api/favorites/:userId/:cupcakeId', (req, res) => {
  const { userId, cupcakeId } = req.params;

  db.run(
    'DELETE FROM favorites WHERE user_id = ? AND cupcake_id = ?',
    [userId, cupcakeId],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      console.log('💔 Favorito removido:', userId, cupcakeId);
      res.json({ success: true, message: 'Removido dos favoritos!' });
    }
  );
});

// Listar favoritos do usuário
app.get('/api/favorites/:userId', (req, res) => {
  const { userId } = req.params;

  db.all(
    `SELECT c.* FROM cupcakes c
     INNER JOIN favorites f ON c.id = f.cupcake_id
     WHERE f.user_id = ?
     ORDER BY f.created_at DESC`,
    [userId],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.json(rows);
    }
  );
});

// Verificar se cupcake está nos favoritos
app.get('/api/favorites/:userId/check/:cupcakeId', (req, res) => {
  const { userId, cupcakeId } = req.params;

  db.get(
    'SELECT id FROM favorites WHERE user_id = ? AND cupcake_id = ?',
    [userId, cupcakeId],
    (err, row) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.json({ isFavorite: !!row });
    }
  );
});

// Listar IDs dos favoritos (para carregar no frontend)
app.get('/api/favorites/:userId/ids', (req, res) => {
  const { userId } = req.params;

  db.all(
    'SELECT cupcake_id FROM favorites WHERE user_id = ?',
    [userId],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      const ids = rows.map(row => row.cupcake_id);
      res.json(ids);
    }
  );
});

// ==========================================
// ROTAS DE CUPCAKES
// ==========================================

app.get('/api/cupcakes', (req, res) => {
  db.all("SELECT * FROM cupcakes WHERE available = 1", (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.get('/api/cupcakes/:id', (req, res) => {
  const { id } = req.params;
  db.get("SELECT * FROM cupcakes WHERE id = ?", [id], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (!row) {
      res.status(404).json({ error: 'Cupcake não encontrado' });
      return;
    }
    res.json(row);
  });
});

// ==========================================
// ROTAS DE PEDIDOS
// ==========================================

app.post('/api/orders', (req, res) => {
  const { userId, customerName, customerEmail, customerPhone, items } = req.body;

  if (!customerName || !customerEmail || !items || items.length === 0) {
    return res.status(400).json({ error: 'Dados do pedido incompletos' });
  }

  let totalAmount = 0;
  const cupcakeIds = items.map(item => item.cupcakeId);
  
  db.all(`SELECT id, price FROM cupcakes WHERE id IN (${cupcakeIds.map(() => '?').join(',')})`, cupcakeIds, (err, cupcakes) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    const cupcakeMap = {};
    cupcakes.forEach(cupcake => {
      cupcakeMap[cupcake.id] = cupcake.price;
    });

    items.forEach(item => {
      const price = cupcakeMap[item.cupcakeId];
      if (price) {
        totalAmount += price * item.quantity;
      }
    });

    db.run(
      "INSERT INTO orders (user_id, customer_name, customer_email, customer_phone, total_amount) VALUES (?, ?, ?, ?, ?)",
      [userId || null, customerName, customerEmail, customerPhone || '', totalAmount],
      function(err) {
        if (err) {
          return res.status(500).json({ error: err.message });
        }

        const orderId = this.lastID;
        const insertItem = db.prepare("INSERT INTO order_items (order_id, cupcake_id, quantity, unit_price) VALUES (?, ?, ?, ?)");
        
        items.forEach(item => {
          const price = cupcakeMap[item.cupcakeId];
          if (price) {
            insertItem.run([orderId, item.cupcakeId, item.quantity, price]);
          }
        });
        
        insertItem.finalize();

        res.json({
          success: true,
          orderId: orderId,
          total: totalAmount,
          message: 'Pedido criado com sucesso!'
        });
      }
    );
  });
});

app.get('/api/orders', (req, res) => {
  db.all(`
    SELECT o.*, 
           GROUP_CONCAT(c.name || ' (x' || oi.quantity || ')') as items
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN cupcakes c ON oi.cupcake_id = c.id
    GROUP BY o.id
    ORDER BY o.created_at DESC
  `, (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cupcake Store API com favoritos!' });
});

app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
  console.log(`❤️ Sistema de favoritos ativo!`);
});

process.on('SIGINT', () => {
  db.close((err) => {
    if (err) {
      console.error(err.message);
    }
    console.log('💤 Conexão com banco de dados fechada.');
    process.exit(0);
  });
});
EOFBACKEND

echo "✅ Backend atualizado!"

# ==========================================
# FRONTEND - Adicionar aba de favoritos
# ==========================================

echo "🎨 Atualizando frontend com aba de favoritos..."

cd frontend/src

cat > App.js << 'EOFFRONTEND'
import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:3001/api';

const Loading = () => (
  <div className="loading">
    <div className="spinner"></div>
  </div>
);

const Header = ({ cartItems, onCartClick, user, onLoginClick, onLogout, currentView, onViewChange }) => {
  const itemCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <header className="header">
      <div className="container">
        <div className="header-content">
          <div>
            <h1>🧁 Sweet Cupcakes</h1>
            <p>Os melhores cupcakes da cidade!</p>
          </div>
          
          <div className="header-actions">
            {user ? (
              <div className="user-section">
                <span className="user-greeting">Olá, {user.name}!</span>
                <button onClick={onLogout} className="logout-button">Sair</button>
              </div>
            ) : (
              <button onClick={onLoginClick} className="login-button">👤 Entrar</button>
            )}
            
            <button 
              onClick={() => onViewChange('catalog')} 
              className={`nav-button ${currentView === 'catalog' ? 'active' : ''}`}
            >
              🏠 Catálogo
            </button>

            {user && (
              <button 
                onClick={() => onViewChange('favorites')} 
                className={`nav-button ${currentView === 'favorites' ? 'active' : ''}`}
              >
                ❤️ Favoritos
              </button>
            )}
            
            <button onClick={onCartClick} className="cart-button">
              🛒 <span>Carrinho</span>
              {itemCount > 0 && <span className="cart-badge">{itemCount}</span>}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

const CupcakeCard = ({ cupcake, onAddToCart, isFavorite, onToggleFavorite, showFavoriteButton = true }) => {
  const [imageError, setImageError] = useState(false);
  
  return (
    <div className="cupcake-card">
      <div className="card-image-container">
        {imageError ? (
          <div className="image-fallback">
            <span className="fallback-emoji">🧁</span>
            <p>Imagem não disponível</p>
          </div>
        ) : (
          <img
            src={cupcake.image_url}
            alt={cupcake.name}
            className="card-image"
            onError={() => setImageError(true)}
            loading="lazy"
          />
        )}
        {showFavoriteButton && (
          <button
            onClick={() => onToggleFavorite(cupcake.id)}
            className={`like-button ${isFavorite ? 'liked' : ''}`}
          >
            {isFavorite ? '❤️' : '🤍'}
          </button>
        )}
        <div className="category-badge">{cupcake.category}</div>
      </div>

      <div className="card-content">
        <h3 className="card-title">{cupcake.name}</h3>
        <p className="card-description">{cupcake.description}</p>
        
        <div className="card-footer">
          <div className="price-section">
            <span className="price">R$ {parseFloat(cupcake.price).toFixed(2)}</span>
            <div className="rating">
              <span className="star">★★★★★</span>
              <span className="rating-text">(4.8)</span>
            </div>
          </div>
          
          <button onClick={() => onAddToCart(cupcake)} className="add-button">
            ➕ Adicionar
          </button>
        </div>
      </div>
    </div>
  );
};

const Cart = ({ isOpen, onClose, cartItems, onUpdateQuantity, onCheckout }) => {
  const total = cartItems.reduce((sum, item) => sum + (parseFloat(item.price) * item.quantity), 0);

  if (!isOpen) return null;

  return (
    <>
      <div className="cart-overlay" onClick={onClose}></div>
      <div className="cart-sidebar">
        <div className="cart-header">
          <h2>Seu Carrinho ({cartItems.reduce((sum, item) => sum + item.quantity, 0)})</h2>
          <button onClick={onClose} className="close-button">✕</button>
        </div>

        <div className="cart-content">
          {cartItems.length === 0 ? (
            <div className="empty-cart">
              <div className="empty-cart-icon">🛒</div>
              <p>Seu carrinho está vazio</p>
              <small>Adicione alguns cupcakes deliciosos!</small>
            </div>
          ) : (
            <>
              <div className="cart-items">
                {cartItems.map(item => (
                  <div key={item.id} className="cart-item">
                    <div className="cart-item-image-container">
                      <img src={item.image_url} alt={item.name} className="cart-item-image" 
                        onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'flex'; }} />
                      <div className="cart-image-fallback">🧁</div>
                    </div>
                    <div className="cart-item-info">
                      <h4>{item.name}</h4>
                      <p className="cart-item-price">R$ {parseFloat(item.price).toFixed(2)}</p>
                    </div>
                    <div className="quantity-controls">
                      <button onClick={() => onUpdateQuantity(item.id, item.quantity - 1)} className="quantity-button">➖</button>
                      <span className="quantity">{item.quantity}</span>
                      <button onClick={() => onUpdateQuantity(item.id, item.quantity + 1)} className="quantity-button">➕</button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="cart-total">
                <div className="total-row">
                  <span>Total:</span>
                  <span className="total-price">R$ {total.toFixed(2)}</span>
                </div>
              </div>

              <button onClick={onCheckout} className="checkout-button">Finalizar Pedido</button>
            </>
          )}
        </div>
      </div>
    </>
  );
};

const AuthModal = ({ isOpen, onClose, onLoginSuccess }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({ name: '', email: '', password: '', confirmPassword: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    if (!isLogin) {
      if (formData.password !== formData.confirmPassword) {
        setError('As senhas não coincidem');
        setIsSubmitting(false);
        return;
      }
      if (formData.password.length < 6) {
        setError('A senha deve ter no mínimo 6 caracteres');
        setIsSubmitting(false);
        return;
      }
    }

    try {
      const endpoint = isLogin ? '/auth/login' : '/auth/register';
      const body = isLogin 
        ? { email: formData.email, password: formData.password }
        : { name: formData.name, email: formData.email, password: formData.password };

      const response = await fetch(`${API_BASE}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      const result = await response.json();

      if (response.ok && result.success) {
        onLoginSuccess(result.user);
        setFormData({ name: '', email: '', password: '', confirmPassword: '' });
        onClose();
      } else {
        setError(result.error || 'Erro ao processar solicitação');
      }
    } catch (error) {
      setError('Erro ao conectar com o servidor');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal auth-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{isLogin ? 'Entrar' : 'Criar Conta'}</h2>
          <button onClick={onClose} className="close-button">✕</button>
        </div>

        <div className="auth-tabs">
          <button className={`auth-tab ${isLogin ? 'active' : ''}`} onClick={() => { setIsLogin(true); setError(''); }}>Login</button>
          <button className={`auth-tab ${!isLogin ? 'active' : ''}`} onClick={() => { setIsLogin(false); setError(''); }}>Cadastro</button>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {!isLogin && (
            <div className="form-group">
              <label>Nome Completo *</label>
              <input type="text" required value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} placeholder="Seu nome" />
            </div>
          )}

          <div className="form-group">
            <label>E-mail *</label>
            <input type="email" required value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} placeholder="seu@email.com" />
          </div>

          <div className="form-group">
            <label>Senha *</label>
            <input type="password" required value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})} placeholder="Mínimo 6 caracteres" />
          </div>

          {!isLogin && (
            <div className="form-group">
              <label>Confirmar Senha *</label>
              <input type="password" required value={formData.confirmPassword} onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})} placeholder="Digite a senha novamente" />
            </div>
          )}

          {error && <div className="error-message">⚠️ {error}</div>}

          <button type="submit" disabled={isSubmitting} className="login-submit-button">
            {isSubmitting ? <><div className="button-spinner"></div>Processando...</> : (isLogin ? 'Entrar' : 'Criar Conta')}
          </button>
        </form>
      </div>
    </div>
  );
};

const CheckoutModal = ({ isOpen, onClose, cartItems, onOrderComplete, user }) => {
  const [formData, setFormData] = useState({ customerName: user?.name || '', customerEmail: user?.email || '', customerPhone: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (user) {
      setFormData(prev => ({ ...prev, customerName: user.name, customerEmail: user.email }));
    }
  }, [user]);

  const total = cartItems.reduce((sum, item) => sum + (parseFloat(item.price) * item.quantity), 0);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    try {
      const response = await fetch(`${API_BASE}/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: user?.id || null,
          ...formData,
          items: cartItems.map(item => ({ cupcakeId: item.id, quantity: item.quantity }))
        }),
      });

      const result = await response.json();

      if (response.ok && result.success) {
        onOrderComplete(result);
        setFormData({ customerName: '', customerEmail: '', customerPhone: '' });
      } else {
        setError(result.error || 'Erro ao processar pedido');
      }
    } catch (error) {
      setError('Erro ao conectar com o servidor');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal checkout-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Finalizar Pedido</h2>
          <button onClick={onClose} className="close-button">✕</button>
        </div>

        <div className="checkout-content">
          <div className="order-summary">
            <h3>Resumo do Pedido:</h3>
            {cartItems.map(item => (
              <div key={item.id} className="summary-item">
                <span>{item.name} x{item.quantity}</span>
                <span>R$ {(parseFloat(item.price) * item.quantity).toFixed(2)}</span>
              </div>
            ))}
            <div className="summary-total">
              <span><strong>Total:</strong></span>
              <span><strong>R$ {total.toFixed(2)}</strong></span>
            </div>
          </div>

          {error && <div className="error-message">⚠️ {error}</div>}

          <form onSubmit={handleSubmit} className="checkout-form">
            <div className="form-group">
              <label>Nome Completo *</label>
              <input type="text" required value={formData.customerName} onChange={(e) => setFormData({...formData, customerName: e.target.value})} placeholder="Seu nome completo" disabled={!!user} />
            </div>

            <div className="form-group">
              <label>E-mail *</label>
              <input type="email" required value={formData.customerEmail} onChange={(e) => setFormData({...formData, customerEmail: e.target.value})} placeholder="seu@email.com" disabled={!!user} />
            </div>

            <div className="form-group">
              <label>Telefone</label>
              <input type="tel" value={formData.customerPhone} onChange={(e) => setFormData({...formData, customerPhone: e.target.value})} placeholder="(11) 99999-9999" />
            </div>

            <button type="submit" disabled={isSubmitting} className="checkout-submit-button">
              {isSubmitting ? <><div className="button-spinner"></div>Processando...</> : `Confirmar Pedido - R$ ${total.toFixed(2)}`}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

const App = () => {
  const [cupcakes, setCupcakes] = useState([]);
  const [favoriteCupcakes, setFavoriteCupcakes] = useState([]);
  const [cartItems, setCartItems] = useState([]);
  const [favorites, setFavorites] = useState([]);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showCart, setShowCart] = useState(false);
  const [showAuth, setShowAuth] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(null);
  const [currentView, setCurrentView] = useState('catalog');

  useEffect(() => {
    fetchCupcakes();
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      const userData = JSON.parse(savedUser);
      setUser(userData);
      loadFavorites(userData.id);
    }
  }, []);

  useEffect(() => {
    if (currentView === 'favorites' && user) {
      fetchFavoriteCupcakes();
    }
  }, [currentView, user]);

  const fetchCupcakes = async () => {
    try {
      setError(null);
      const response = await fetch(`${API_BASE}/cupcakes`);
      if (!response.ok) throw new Error('Erro ao carregar cupcakes');
      const data = await response.json();
      setCupcakes(data);
    } catch (error) {
      setError('Erro ao conectar com o servidor. Verifique se o backend está rodando na porta 3001.');
    } finally {
      setLoading(false);
    }
  };

  const loadFavorites = async (userId) => {
    try {
      const response = await fetch(`${API_BASE}/favorites/${userId}/ids`);
      if (response.ok) {
        const ids = await response.json();
        setFavorites(ids);
      }
    } catch (error) {
      console.error('Erro ao carregar favoritos:', error);
    }
  };

  const fetchFavoriteCupcakes = async () => {
    if (!user) return;
    
    try {
      const response = await fetch(`${API_BASE}/favorites/${user.id}`);
      if (response.ok) {
        const data = await response.json();
        setFavoriteCupcakes(data);
      }
    } catch (error) {
      console.error('Erro ao carregar cupcakes favoritos:', error);
    }
  };

  const addToCart = (cupcake) => {
    setCartItems(prev => {
      const existing = prev.find(item => item.id === cupcake.id);
      if (existing) {
        return prev.map(item => item.id === cupcake.id ? { ...item, quantity: item.quantity + 1 } : item);
      }
      return [...prev, { ...cupcake, quantity: 1 }];
    });
  };

  const updateQuantity = (id, newQuantity) => {
    if (newQuantity <= 0) {
      setCartItems(prev => prev.filter(item => item.id !== id));
    } else {
      setCartItems(prev => prev.map(item => item.id === id ? { ...item, quantity: newQuantity } : item));
    }
  };

  const toggleFavorite = async (cupcakeId) => {
    if (!user) {
      setShowAuth(true);
      return;
    }

    const isFavorite = favorites.includes(cupcakeId);

    try {
      if (isFavorite) {
        const response = await fetch(`${API_BASE}/favorites/${user.id}/${cupcakeId}`, {
          method: 'DELETE',
        });

        if (response.ok) {
          setFavorites(prev => prev.filter(id => id !== cupcakeId));
          if (currentView === 'favorites') {
            setFavoriteCupcakes(prev => prev.filter(c => c.id !== cupcakeId));
          }
        }
      } else {
        const response = await fetch(`${API_BASE}/favorites`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId: user.id, cupcakeId }),
        });

        if (response.ok) {
          setFavorites(prev => [...prev, cupcakeId]);
        }
      }
    } catch (error) {
      console.error('Erro ao atualizar favoritos:', error);
    }
  };

  const handleLoginSuccess = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
    loadFavorites(userData.id);
    setShowAuth(false);
  };

  const handleLogout = () => {
    setUser(null);
    setFavorites([]);
    setFavoriteCupcakes([]);
    setCurrentView('catalog');
    localStorage.removeItem('user');
  };

  const handleCheckout = () => {
    setShowCart(false);
    setShowCheckout(true);
  };

  const handleOrderComplete = (result) => {
    setShowCheckout(false);
    setCartItems([]);
    setOrderSuccess(result);
    setTimeout(() => setOrderSuccess(null), 8000);
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', background: '#f9fafb', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Loading />
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <div className="error-box">
          <h2>⚠️ Erro de Conexão</h2>
          <p>{error}</p>
          <button onClick={fetchCupcakes}>Tentar Novamente</button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', background: '#f9fafb' }}>
      <Header 
        cartItems={cartItems} 
        onCartClick={() => setShowCart(true)} 
        user={user} 
        onLoginClick={() => setShowAuth(true)} 
        onLogout={handleLogout}
        currentView={currentView}
        onViewChange={setCurrentView}
      />

      {orderSuccess && (
        <div className="success-banner">
          <p><strong>🎉 Pedido #{orderSuccess.orderId} criado com sucesso!</strong></p>
          <p>Total: R$ {orderSuccess.total.toFixed(2)} - Entraremos em contato em breve!</p>
        </div>
      )}

      <main className="container main-content">
        {currentView === 'catalog' ? (
          <>
            <div className="hero">
              <h2>Nossos Cupcakes</h2>
              <p>Descubra nossa incrível seleção de cupcakes artesanais, feitos com amor e os melhores ingredientes. Cada mordida é uma explosão de sabor que vai deixar você querendo mais!</p>
            </div>

            {cupcakes.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '2rem 0' }}>
                <p style={{ color: '#6b7280' }}>Nenhum cupcake disponível no momento.</p>
              </div>
            ) : (
              <div className="cupcakes-grid">
                {cupcakes.map(cupcake => (
                  <CupcakeCard 
                    key={cupcake.id} 
                    cupcake={cupcake} 
                    onAddToCart={addToCart} 
                    isFavorite={favorites.includes(cupcake.id)} 
                    onToggleFavorite={toggleFavorite} 
                  />
                ))}
              </div>
            )}
          </>
        ) : (
          <>
            <div className="hero">
              <h2>❤️ Meus Favoritos</h2>
              <p>Seus cupcakes preferidos estão salvos aqui!</p>
            </div>

            {favoriteCupcakes.length === 0 ? (
              <div className="empty-favorites">
                <div className="empty-icon">💔</div>
                <h3>Nenhum favorito ainda</h3>
                <p>Clique no coração dos cupcakes que você ama para salvá-los aqui!</p>
                <button onClick={() => setCurrentView('catalog')} className="back-button">
                  🏠 Ir para o Catálogo
                </button>
              </div>
            ) : (
              <div className="cupcakes-grid">
                {favoriteCupcakes.map(cupcake => (
                  <CupcakeCard 
                    key={cupcake.id} 
                    cupcake={cupcake} 
                    onAddToCart={addToCart} 
                    isFavorite={true} 
                    onToggleFavorite={toggleFavorite} 
                  />
                ))}
              </div>
            )}
          </>
        )}

        <div className="contact-section">
          <h3>Entre em Contato</h3>
          <p>Dúvidas? Encomendas especiais? Fale conosco!</p>
          <div className="contact-grid">
            <div className="contact-item">
              <div className="contact-icon">📞</div>
              <h4>Telefone</h4>
              <p>(11) 99999-9999</p>
            </div>
            <div className="contact-item">
              <div className="contact-icon">✉️</div>
              <h4>E-mail</h4>
              <p>contato@sweetcupcakes.com</p>
            </div>
            <div className="contact-item">
              <div className="contact-icon">📍</div>
              <h4>Endereço</h4>
              <p>Rua dos Doces, 123<br />São Paulo, SP</p>
            </div>
          </div>
        </div>
      </main>

      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-brand"><h4>🧁 Sweet Cupcakes</h4></div>
            <p>Os melhores cupcakes artesanais da cidade, feitos com amor desde 2024.</p>
            <p className="footer-copy">© 2024 Sweet Cupcakes. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>

      <Cart isOpen={showCart} onClose={() => setShowCart(false)} cartItems={cartItems} onUpdateQuantity={updateQuantity} onCheckout={handleCheckout} />
      <AuthModal isOpen={showAuth} onClose={() => setShowAuth(false)} onLoginSuccess={handleLoginSuccess} />
      <CheckoutModal isOpen={showCheckout} onClose={() => setShowCheckout(false)} cartItems={cartItems} onOrderComplete={handleOrderComplete} user={user} />
    </div>
  );
};

export default App;
EOFFRONTEND

# Adicionar CSS para favoritos
cat >> index.css << 'EOFCSS'

/* Navegação */
.nav-button {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  cursor: pointer;
  font-size: 0.875rem;
  transition: all 0.2s;
}

.nav-button:hover {
  background: rgba(255, 255, 255, 0.2);
}

.nav-button.active {
  background: rgba(255, 255, 255, 0.3);
  font-weight: 600;
}

/* Favoritos vazios */
.empty-favorites {
  text-align: center;
  padding: 4rem 2rem;
  background: white;
  border-radius: 1rem;
  max-width: 600px;
  margin: 2rem auto;
}

.empty-icon {
  font-size: 5rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.empty-favorites h3 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.empty-favorites p {
  color: #6b7280;
  margin-bottom: 2rem;
}

.back-button {
  background: linear-gradient(to right, #ec4899, #a855f7);
  color: white;
  border: none;
  padding: 0.75rem 2rem;
  border-radius: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.back-button:hover {
  background: linear-gradient(to right, #db2777, #9333ea);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.4);
}

/* Responsive */
@media (max-width: 768px) {
  .header-actions {
    flex-wrap: wrap;
    gap: 0.5rem;
  }
  
  .nav-button {
    font-size: 0.75rem;
    padding: 0.4rem 0.75rem;
  }
}
EOFCSS

cd ../..

echo ""
echo "✅ ═══════════════════════════════════════════════"
echo "   SISTEMA DE FAVORITOS INSTALADO COM SUCESSO!"
echo "   ═══════════════════════════════════════════════"
echo ""
echo "❤️ FUNCIONALIDADES:"
echo "   ✅ Favoritos persistem no banco de dados"
echo "   ✅ Aba dedicada para ver favoritos"
echo "   ✅ Sincronização em tempo real"
echo "   ✅ Botão de navegação no header"
echo "   ✅ Mensagem quando não há favoritos"
echo "   ✅ Requer login para favoritar"
echo ""
echo "📊 BANCO DE DADOS:"
echo "   ✅ Nova tabela 'favorites' criada"
echo "   ✅ Relacionamento user_id + cupcake_id"
echo "   ✅ Evita duplicatas (UNIQUE constraint)"
echo ""
echo "🔄 Para aplicar, apague o banco e reinicie:"
echo "   rm backend/database/cupcakes.db"
echo "   ./start.sh"
echo ""
echo "🧪 TESTAR:"
echo "   1. Faça login"
echo "   2. Clique no coração ❤️ dos cupcakes"
echo "   3. Clique no botão 'Favoritos' no header"
echo "   4. Veja seus cupcakes salvos!"
echo "   5. Faça logout e login novamente"
echo "   6. Os favoritos continuam lá!"
echo ""
echo "✨ Favoritos agora são permanentes!"