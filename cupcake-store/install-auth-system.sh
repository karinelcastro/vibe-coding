#!/bin/bash

echo "🔐 Instalando Sistema de Autenticação Completo..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# ==========================================
# PARTE 1: BACKEND - Adicionar autenticação
# ==========================================

echo "📦 Instalando bcrypt para criptografia de senhas..."
cd backend
npm install bcrypt

echo "✅ Atualizando servidor com sistema de autenticação..."

cat > server.js << 'EOFBACKEND'
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Inicializar banco de dados
const db = new sqlite3.Database('./database/cupcakes.db');

// Criar tabelas
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
        ['Cupcake de Chocolate', 'Delicioso cupcake de chocolate com cobertura cremosa', 8.50, 'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=400&h=300&fit=crop&auto=format', 'chocolate'],
        ['Cupcake de Baunilha', 'Cupcake clássico de baunilha com buttercream', 7.50, 'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?w=400&h=300&fit=crop&auto=format', 'baunilha'],
        ['Cupcake Red Velvet', 'O famoso red velvet com cream cheese', 9.50, 'https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=400&h=300&fit=crop&auto=format', 'especial'],
        ['Cupcake de Morango', 'Cupcake de morango com pedaços da fruta', 8.00, 'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=400&h=300&fit=crop&auto=format', 'frutas'],
        ['Cupcake de Limão', 'Refrescante cupcake de limão com cobertura cítrica', 8.00, 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=400&h=300&fit=crop&auto=format', 'frutas'],
        ['Cupcake de Nutella', 'Irresistível cupcake recheado com Nutella', 10.00, 'https://images.unsplash.com/photo-1603532648955-039310d9ed75?w=400&h=300&fit=crop&auto=format', 'especial']
      ];

      cupcakes.forEach(cupcake => {
        insert.run(cupcake);
      });
      insert.finalize();
      console.log('✅ Cupcakes inseridos com sucesso!');
    }
  });
  checkCupcakes.finalize();
});

// ==========================================
// ROTAS DE AUTENTICAÇÃO
// ==========================================

// Registrar novo usuário
app.post('/api/auth/register', async (req, res) => {
  const { name, email, password } = req.body;

  console.log('📝 Tentativa de registro:', { name, email });

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: 'A senha deve ter no mínimo 6 caracteres' });
  }

  // Verificar se email já existe
  db.get('SELECT id FROM users WHERE email = ?', [email], async (err, row) => {
    if (err) {
      console.error('❌ Erro ao verificar email:', err);
      return res.status(500).json({ error: 'Erro ao verificar email' });
    }

    if (row) {
      return res.status(400).json({ error: 'Este email já está cadastrado' });
    }

    try {
      // Hash da senha
      const hashedPassword = await bcrypt.hash(password, 10);

      // Inserir usuário
      db.run(
        'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
        [name, email, hashedPassword],
        function(err) {
          if (err) {
            console.error('❌ Erro ao criar usuário:', err);
            return res.status(500).json({ error: 'Erro ao criar usuário' });
          }

          console.log('✅ Usuário criado com ID:', this.lastID);
          res.json({
            success: true,
            user: {
              id: this.lastID,
              name,
              email
            },
            message: 'Usuário cadastrado com sucesso!'
          });
        }
      );
    } catch (error) {
      console.error('❌ Erro ao criptografar senha:', error);
      res.status(500).json({ error: 'Erro ao processar senha' });
    }
  });
});

// Login de usuário
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  console.log('🔐 Tentativa de login:', email);

  if (!email || !password) {
    return res.status(400).json({ error: 'Email e senha são obrigatórios' });
  }

  // Buscar usuário
  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) {
      console.error('❌ Erro ao buscar usuário:', err);
      return res.status(500).json({ error: 'Erro ao buscar usuário' });
    }

    if (!user) {
      return res.status(401).json({ error: 'Email ou senha incorretos' });
    }

    try {
      // Verificar senha
      const passwordMatch = await bcrypt.compare(password, user.password);

      if (!passwordMatch) {
        return res.status(401).json({ error: 'Email ou senha incorretos' });
      }

      console.log('✅ Login bem-sucedido:', user.name);
      res.json({
        success: true,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        },
        message: 'Login realizado com sucesso!'
      });
    } catch (error) {
      console.error('❌ Erro ao verificar senha:', error);
      res.status(500).json({ error: 'Erro ao verificar senha' });
    }
  });
});

// Verificar se email existe
app.get('/api/auth/check-email/:email', (req, res) => {
  const { email } = req.params;

  db.get('SELECT id FROM users WHERE email = ?', [email], (err, row) => {
    if (err) {
      return res.status(500).json({ error: 'Erro ao verificar email' });
    }
    res.json({ exists: !!row });
  });
});

// ==========================================
// ROTAS DE CUPCAKES
// ==========================================

// Listar todos os cupcakes
app.get('/api/cupcakes', (req, res) => {
  db.all("SELECT * FROM cupcakes WHERE available = 1", (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Buscar cupcake por ID
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

// Criar novo pedido
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

        console.log('✅ Pedido criado:', orderId);
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

// Listar pedidos do usuário
app.get('/api/orders/user/:userId', (req, res) => {
  const { userId } = req.params;

  db.all(`
    SELECT o.*, 
           GROUP_CONCAT(c.name || ' (x' || oi.quantity || ')') as items
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN cupcakes c ON oi.cupcake_id = c.id
    WHERE o.user_id = ?
    GROUP BY o.id
    ORDER BY o.created_at DESC
  `, [userId], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

// Listar todos os pedidos (admin)
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

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cupcake Store API rodando com autenticação!' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
  console.log(`🔐 Sistema de autenticação ativo!`);
});

// Fechar conexão do banco ao encerrar
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

cd ..

# ==========================================
# PARTE 2: FRONTEND - Interface de auth
# ==========================================

echo "✅ Atualizando frontend com sistema de login/cadastro..."

cd frontend/src

cat > App.js << 'EOFFRONTEND'
import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:3001/api';

// Componente de Loading
const Loading = () => (
  <div className="loading">
    <div className="spinner"></div>
  </div>
);

// Componente do Header
const Header = ({ cartItems, onCartClick, user, onLoginClick, onLogout }) => {
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
                <button onClick={onLogout} className="logout-button">
                  Sair
                </button>
              </div>
            ) : (
              <button onClick={onLoginClick} className="login-button">
                👤 Entrar
              </button>
            )}
            
            <button onClick={onCartClick} className="cart-button">
              🛒
              <span>Carrinho</span>
              {itemCount > 0 && (
                <span className="cart-badge">
                  {itemCount}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

// Componente do Card de Cupcake
const CupcakeCard = ({ cupcake, onAddToCart, isFavorite, onToggleFavorite }) => {
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
        <button
          onClick={() => onToggleFavorite(cupcake.id)}
          className={`like-button ${isFavorite ? 'liked' : ''}`}
        >
          {isFavorite ? '❤️' : '🤍'}
        </button>
        <div className="category-badge">
          {cupcake.category}
        </div>
      </div>

      <div className="card-content">
        <h3 className="card-title">{cupcake.name}</h3>
        <p className="card-description">{cupcake.description}</p>
        
        <div className="card-footer">
          <div className="price-section">
            <span className="price">
              R$ {parseFloat(cupcake.price).toFixed(2)}
            </span>
            <div className="rating">
              <span className="star">★</span>
              <span className="star">★</span>
              <span className="star">★</span>
              <span className="star">★</span>
              <span className="star">★</span>
              <span className="rating-text">(4.8)</span>
            </div>
          </div>
          
          <button
            onClick={() => onAddToCart(cupcake)}
            className="add-button"
          >
            ➕ Adicionar
          </button>
        </div>
      </div>
    </div>
  );
};

// Componente do Carrinho
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
                      <img 
                        src={item.image_url} 
                        alt={item.name} 
                        className="cart-item-image"
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.nextSibling.style.display = 'flex';
                        }}
                      />
                      <div className="cart-image-fallback">🧁</div>
                    </div>
                    <div className="cart-item-info">
                      <h4>{item.name}</h4>
                      <p className="cart-item-price">R$ {parseFloat(item.price).toFixed(2)}</p>
                    </div>
                    <div className="quantity-controls">
                      <button 
                        onClick={() => onUpdateQuantity(item.id, item.quantity - 1)}
                        className="quantity-button"
                      >
                        ➖
                      </button>
                      <span className="quantity">{item.quantity}</span>
                      <button 
                        onClick={() => onUpdateQuantity(item.id, item.quantity + 1)}
                        className="quantity-button"
                      >
                        ➕
                      </button>
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

              <button onClick={onCheckout} className="checkout-button">
                Finalizar Pedido
              </button>
            </>
          )}
        </div>
      </div>
    </>
  );
};

// Componente de Autenticação (Login/Cadastro)
const AuthModal = ({ isOpen, onClose, onLoginSuccess }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    // Validações
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
        headers: {
          'Content-Type': 'application/json',
        },
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
          <button 
            className={`auth-tab ${isLogin ? 'active' : ''}`}
            onClick={() => {
              setIsLogin(true);
              setError('');
            }}
          >
            Login
          </button>
          <button 
            className={`auth-tab ${!isLogin ? 'active' : ''}`}
            onClick={() => {
              setIsLogin(false);
              setError('');
            }}
          >
            Cadastro
          </button>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {!isLogin && (
            <div className="form-group">
              <label>Nome Completo *</label>
              <input
                type="text"
                required
                value={formData.customerName}
                onChange={(e) => setFormData({...formData, customerName: e.target.value})}
                placeholder="Seu nome completo"
                disabled={!!user}
              />
            </div>

            <div className="form-group">
              <label>E-mail *</label>
              <input
                type="email"
                required
                value={formData.customerEmail}
                onChange={(e) => setFormData({...formData, customerEmail: e.target.value})}
                placeholder="seu@email.com"
                disabled={!!user}
              />
            </div>

            <div className="form-group">
              <label>Telefone</label>
              <input
                type="tel"
                value={formData.customerPhone}
                onChange={(e) => setFormData({...formData, customerPhone: e.target.value})}
                placeholder="(11) 99999-9999"
              />
            </div>

            <button type="submit" disabled={isSubmitting} className="checkout-submit-button">
              {isSubmitting ? (
                <>
                  <div className="button-spinner"></div>
                  Processando...
                </>
              ) : (
                `Confirmar Pedido - R$ ${total.toFixed(2)}`
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

// Componente Principal
const App = () => {
  const [cupcakes, setCupcakes] = useState([]);
  const [cartItems, setCartItems] = useState([]);
  const [favorites, setFavorites] = useState([]);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showCart, setShowCart] = useState(false);
  const [showAuth, setShowAuth] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(null);

  useEffect(() => {
    fetchCupcakes();
    // Recuperar usuário do localStorage se existir
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
  }, []);

  const fetchCupcakes = async () => {
    try {
      setError(null);
      const response = await fetch(`${API_BASE}/cupcakes`);
      
      if (!response.ok) {
        throw new Error('Erro ao carregar cupcakes');
      }
      
      const data = await response.json();
      setCupcakes(data);
    } catch (error) {
      console.error('Erro ao carregar cupcakes:', error);
      setError('Erro ao conectar com o servidor. Verifique se o backend está rodando na porta 3001.');
    } finally {
      setLoading(false);
    }
  };

  const addToCart = (cupcake) => {
    setCartItems(prev => {
      const existing = prev.find(item => item.id === cupcake.id);
      if (existing) {
        return prev.map(item =>
          item.id === cupcake.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { ...cupcake, quantity: 1 }];
    });
  };

  const updateQuantity = (id, newQuantity) => {
    if (newQuantity <= 0) {
      setCartItems(prev => prev.filter(item => item.id !== id));
    } else {
      setCartItems(prev =>
        prev.map(item =>
          item.id === id ? { ...item, quantity: newQuantity } : item
        )
      );
    }
  };

  const toggleFavorite = (id) => {
    setFavorites(prev =>
      prev.includes(id)
        ? prev.filter(fav => fav !== id)
        : [...prev, id]
    );
  };

  const handleLoginSuccess = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
    setShowAuth(false);
  };

  const handleLogout = () => {
    setUser(null);
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
          <button onClick={fetchCupcakes}>
            Tentar Novamente
          </button>
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
      />

      {orderSuccess && (
        <div className="success-banner">
          <p><strong>🎉 Pedido #{orderSuccess.orderId} criado com sucesso!</strong></p>
          <p>Total: R$ {orderSuccess.total.toFixed(2)} - Entraremos em contato em breve!</p>
        </div>
      )}

      <main className="container main-content">
        <div className="hero">
          <h2>Nossos Cupcakes</h2>
          <p>
            Descubra nossa incrível seleção de cupcakes artesanais, feitos com amor e os melhores ingredientes.
            Cada mordida é uma explosão de sabor que vai deixar você querendo mais!
          </p>
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
            <div className="footer-brand">
              <h4>🧁 Sweet Cupcakes</h4>
            </div>
            <p>Os melhores cupcakes artesanais da cidade, feitos com amor desde 2024.</p>
            <p className="footer-copy">© 2024 Sweet Cupcakes. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>

      <Cart
        isOpen={showCart}
        onClose={() => setShowCart(false)}
        cartItems={cartItems}
        onUpdateQuantity={updateQuantity}
        onCheckout={handleCheckout}
      />

      <AuthModal
        isOpen={showAuth}
        onClose={() => setShowAuth(false)}
        onLoginSuccess={handleLoginSuccess}
      />

      <CheckoutModal
        isOpen={showCheckout}
        onClose={() => setShowCheckout(false)}
        cartItems={cartItems}
        onOrderComplete={handleOrderComplete}
        user={user}
      />
    </div>
  );
};

export default App;
EOFFRONTEND

# Adicionar CSS para abas de autenticação
cat >> index.css << 'EOFCSS'

/* Auth Modal */
.auth-modal {
  max-width: 28rem;
}

.auth-tabs {
  display: flex;
  border-bottom: 2px solid #e5e7eb;
  margin-bottom: 1.5rem;
}

.auth-tab {
  flex: 1;
  padding: 1rem;
  background: none;
  border: none;
  font-size: 1rem;
  font-weight: 500;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.auth-tab:hover {
  color: #ec4899;
}

.auth-tab.active {
  color: #ec4899;
  font-weight: 600;
}

.auth-tab.active::after {
  content: '';
  position: absolute;
  bottom: -2px;
  left: 0;
  right: 0;
  height: 2px;
  background: #ec4899;
}

.form-group input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

/* Success animation */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.success-banner {
  animation: fadeIn 0.3s ease-out;
}
EOFCSS

cd ../..

echo ""
echo "✅ Sistema de Autenticação Completo Instalado!"
echo ""
echo "🔐 FUNCIONALIDADES:"
echo "   ✅ Cadastro de novos usuários"
echo "   ✅ Login com validação real"
echo "   ✅ Senhas criptografadas (bcrypt)"
echo "   ✅ Sessão persistente (localStorage)"
echo "   ✅ Abas Login/Cadastro no mesmo modal"
echo "   ✅ Validações de formulário"
echo "   ✅ Pedidos vinculados ao usuário"
echo ""
echo "📊 BANCO DE DADOS:"
echo "   ✅ Tabela 'users' criada"
echo "   ✅ Senhas com hash bcrypt"
echo "   ✅ Pedidos vinculados a usuários"
echo ""
echo "🚀 Para iniciar:"
echo "   ./start.sh"
echo ""
echo "🧪 TESTAR:"
echo "   1. Clique em 'Entrar'"
echo "   2. Vá na aba 'Cadastro'"
echo "   3. Crie um novo usuário"
echo "   4. Faça login com as credenciais"
echo "   5. Seu nome aparecerá no header"
echo ""
echo "✨ Agora o sistema tem autenticação real!"
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                placeholder="Seu nome"
              />
            </div>
          )}

          <div className="form-group">
            <label>E-mail *</label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              placeholder="seu@email.com"
            />
          </div>

          <div className="form-group">
            <label>Senha *</label>
            <input
              type="password"
              required
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              placeholder="Mínimo 6 caracteres"
            />
          </div>

          {!isLogin && (
            <div className="form-group">
              <label>Confirmar Senha *</label>
              <input
                type="password"
                required
                value={formData.confirmPassword}
                onChange={(e) => setFormData({...formData, confirmPassword: e.target.value})}
                placeholder="Digite a senha novamente"
              />
            </div>
          )}

          {error && (
            <div className="error-message">
              ⚠️ {error}
            </div>
          )}

          <button type="submit" disabled={isSubmitting} className="login-submit-button">
            {isSubmitting ? (
              <>
                <div className="button-spinner"></div>
                Processando...
              </>
            ) : (
              isLogin ? 'Entrar' : 'Criar Conta'
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

// Componente de Checkout
const CheckoutModal = ({ isOpen, onClose, cartItems, onOrderComplete, user }) => {
  const [formData, setFormData] = useState({
    customerName: user?.name || '',
    customerEmail: user?.email || '',
    customerPhone: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (user) {
      setFormData(prev => ({
        ...prev,
        customerName: user.name,
        customerEmail: user.email
      }));
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: user?.id || null,
          ...formData,
          items: cartItems.map(item => ({
            cupcakeId: item.id,
            quantity: item.quantity
          }))
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

          {error && (
            <div className="error-message">
              ⚠️ {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="checkout-form">
            <div className="form-group">
              <label>Nome Completo *</label>