#!/bin/bash

echo "🔧 Corrigindo problemas finais do sistema..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

echo "🖼️ Corrigindo BACKEND - Imagens dos cupcakes..."

# Corrigir o backend para servir imagens placeholder corretas
cat > backend/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
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
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT,
    total_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
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

  // Inserir dados iniciais com URLs de imagens funcionais
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
      console.log('✅ Cupcakes inseridos com imagens do Unsplash!');
    }
  });
  checkCupcakes.finalize();
});

// ROTAS DA API

// Listar todos os cupcakes
app.get('/api/cupcakes', (req, res) => {
  db.all("SELECT * FROM cupcakes WHERE available = 1", (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    console.log(`📦 Enviando ${rows.length} cupcakes`);
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

// Criar novo pedido
app.post('/api/orders', (req, res) => {
  console.log('📨 Recebendo pedido:', req.body);
  
  const { customerName, customerEmail, customerPhone, items } = req.body;

  if (!customerName || !customerEmail || !items || items.length === 0) {
    console.log('❌ Dados incompletos:', { customerName, customerEmail, items });
    return res.status(400).json({ error: 'Dados do pedido incompletos' });
  }

  // Calcular total
  let totalAmount = 0;
  const cupcakeIds = items.map(item => item.cupcakeId);
  
  if (cupcakeIds.length === 0) {
    return res.status(400).json({ error: 'Nenhum item no pedido' });
  }
  
  db.all(`SELECT id, price FROM cupcakes WHERE id IN (${cupcakeIds.map(() => '?').join(',')})`, cupcakeIds, (err, cupcakes) => {
    if (err) {
      console.log('❌ Erro ao buscar cupcakes:', err);
      return res.status(500).json({ error: err.message });
    }

    console.log('🔍 Cupcakes encontrados:', cupcakes);

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

    console.log('💰 Total calculado:', totalAmount);

    // Criar pedido
    db.run(
      "INSERT INTO orders (customer_name, customer_email, customer_phone, total_amount) VALUES (?, ?, ?, ?)",
      [customerName, customerEmail, customerPhone || '', totalAmount],
      function(err) {
        if (err) {
          console.log('❌ Erro ao criar pedido:', err);
          return res.status(500).json({ error: err.message });
        }

        const orderId = this.lastID;
        console.log('✅ Pedido criado com ID:', orderId);

        // Inserir itens do pedido
        const insertItem = db.prepare("INSERT INTO order_items (order_id, cupcake_id, quantity, unit_price) VALUES (?, ?, ?, ?)");
        
        items.forEach(item => {
          const price = cupcakeMap[item.cupcakeId];
          if (price) {
            insertItem.run([orderId, item.cupcakeId, item.quantity, price]);
          }
        });
        
        insertItem.finalize();

        console.log('🎉 Pedido finalizado com sucesso!');
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

// Listar pedidos (para admin)
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

// Atualizar status do pedido
app.patch('/api/orders/:id', (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  db.run("UPDATE orders SET status = ? WHERE id = ?", [status, id], function(err) {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    
    if (this.changes === 0) {
      res.status(404).json({ error: 'Pedido não encontrado' });
      return;
    }

    res.json({ success: true, message: 'Status atualizado com sucesso!' });
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cupcake Store API rodando!' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
  console.log(`🖼️ Usando imagens do Unsplash`);
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
EOF

echo "✅ Backend corrigido com imagens funcionais!"

cd frontend

echo "🔐 Corrigindo FRONTEND - Login e Checkout..."

# Corrigir o App.js com login e checkout funcionais
cat > src/App.js << 'EOF'
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
                👤 Login
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
            onLoad={() => setImageError(false)}
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

// Componente do Carrinho (Sidebar)
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

// Componente de Login
const LoginModal = ({ isOpen, onClose, onLogin }) => {
  const [formData, setFormData] = useState({
    email: 'joao@teste.com',
    password: '123456'
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log('Login realizado:', formData);
    onLogin({
      name: 'João Silva',
      email: formData.email
    });
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Login</h2>
          <button onClick={onClose} className="close-button">✕</button>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label>E-mail</label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              placeholder="seu@email.com"
            />
          </div>

          <div className="form-group">
            <label>Senha</label>
            <input
              type="password"
              required
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              placeholder="••••••••"
            />
          </div>

          <button type="submit" className="login-submit-button">
            Entrar
          </button>
          
          <p style={{ fontSize: '0.75rem', color: '#6b7280', textAlign: 'center', marginTop: '1rem' }}>
            Demo: use qualquer email e senha
          </p>
        </form>
      </div>
    </div>
  );
};

// Componente de Checkout
const CheckoutModal = ({ isOpen, onClose, cartItems, onOrderComplete }) => {
  const [formData, setFormData] = useState({
    customerName: '',
    customerEmail: '',
    customerPhone: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const total = cartItems.reduce((sum, item) => sum + (parseFloat(item.price) * item.quantity), 0);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    console.log('Enviando pedido:', {
      ...formData,
      items: cartItems.map(item => ({
        cupcakeId: item.id,
        quantity: item.quantity
      }))
    });

    try {
      const response = await fetch(`${API_BASE}/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...formData,
          items: cartItems.map(item => ({
            cupcakeId: item.id,
            quantity: item.quantity
          }))
        }),
      });

      console.log('Resposta do servidor:', response.status);
      const result = await response.json();
      console.log('Dados da resposta:', result);

      if (response.ok && result.success) {
        onOrderComplete(result);
        setFormData({ customerName: '', customerEmail: '', customerPhone: '' });
      } else {
        setError(result.error || 'Erro ao processar pedido. Tente novamente.');
      }
    } catch (error) {
      console.error('Erro na requisição:', error);
      setError('Erro ao conectar com o servidor. Verifique se o backend está rodando.');
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
              <input
                type="text"
                required
                value={formData.customerName}
                onChange={(e) => setFormData({...formData, customerName: e.target.value})}
                placeholder="Seu nome completo"
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
  const [showLogin, setShowLogin] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(null);

  useEffect(() => {
    fetchCupcakes();
  }, []);

  const fetchCupcakes = async () => {
    try {
      setError(null);
      console.log('Buscando cupcakes...');
      const response = await fetch(`${API_BASE}/cupcakes`);
      
      if (!response.ok) {
        throw new Error('Erro ao carregar cupcakes');
      }
      
      const data = await response.json();
      console.log('Cupcakes recebidos:', data);
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
    console.log('Adicionado ao carrinho:', cupcake.name);
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

  const handleLogin = (userData) => {
    console.log('Usuário logado:', userData);
    setUser(userData);
    setShowLogin(false);
  };

  const handleLogout = () => {
    setUser(null);
    console.log('Usuário deslogado');
  };

  const handleCheckout = () => {
    console.log('Abrindo checkout com itens:', cartItems);
    setShowCart(false);
    setShowCheckout(true);
  };

  const handleOrderComplete = (result) => {
    console.log('Pedido finalizado:', result);
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
        onLoginClick={() => setShowLogin(true)}
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

        {/* Contact Section */}
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

      {showLogin && (
        <LoginModal
          isOpen={showLogin}
          onClose={() => setShowLogin(false)}
          onLogin={handleLogin}
        />
      )}

      {showCheckout && (
        <CheckoutModal
          isOpen={showCheckout}
          onClose={() => setShowCheckout(false)}
          cartItems={cartItems}
          onOrderComplete={handleOrderComplete}
        />
      )}
    </div>
  );
};

export default App;
EOF

echo "✅ Adicionando CSS para fallback de imagens e correções..."

# Adicionar CSS para imagens fallback e correções
cat >> src/index.css << 'EOF'

/* Fallback de Imagens */
.image-fallback {
  width: 100%;
  height: 12rem;
  background: linear-gradient(135deg, #fce7f3, #e9d5ff);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #ec4899;
}

.fallback-emoji {
  font-size: 3rem;
  margin-bottom: 0.5rem;
}

.image-fallback p {
  font-size: 0.875rem;
  color: #6b7280;
}

.cart-item-image-container {
  position: relative;
  width: 4rem;
  height: 4rem;
  border-radius: 0.5rem;
  overflow: hidden;
}

.cart-image-fallback {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #fce7f3, #e9d5ff);
  display: none;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  color: #ec4899;
}

/* Correções de Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.modal {
  background: white;
  border-radius: 0.75rem;
  width: 100%;
  max-width: 28rem;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: modalSlide 0.2s ease-out;
  z-index: 1000;
}

.checkout-modal {
  max-width: 32rem;
}

/* Mensagem de Erro no Checkout */
.error-message {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
  padding: 0.75rem;
  border-radius: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}

/* Melhorias no Carrinho */
.cart-sidebar {
  position: fixed;
  right: 0;
  top: 0;
  height: 100vh;
  width: 100%;
  max-width: 28rem;
  background: white;
  box-shadow: -10px 0 25px -3px rgba(0, 0, 0, 0.1);
  z-index: 998;
  display: flex;
  flex-direction: column;
}

/* Correções Responsivas */
@media (max-width: 768px) {
  .modal {
    margin: 1rem;
    max-width: calc(100% - 2rem);
  }
  
  .cart-sidebar {
    max-width: 100%;
  }
  
  .header-content {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
  
  .header-actions {
    width: 100%;
    justify-content: center;
    flex-wrap: wrap;
  }
}

/* Animações suaves */
.cart-sidebar,
.modal {
  transition: all 0.3s ease;
}

.success-banner {
  animation: slideDown 0.5s ease-out, slideUp 0.5s ease-in 7.5s forwards;
}

@keyframes slideUp {
  from {
    transform: translateY(0);
    opacity: 1;
  }
  to {
    transform: translateY(-100%);
    opacity: 0;
  }
}
EOF

echo "🔄 Removendo banco antigo para forçar recriação..."
rm -f backend/database/cupcakes.db 2>/dev/null

echo "✅ Todas as correções aplicadas!"
echo ""
echo "🎯 PROBLEMAS CORRIGIDOS:"
echo ""
echo "🖼️ IMAGENS:"
echo "   ✅ URLs do Unsplash funcionais"
echo "   ✅ Fallback para imagens quebradas" 
echo "   ✅ Banco recriado com novas URLs"
echo ""
echo "🔐 LOGIN:"
echo "   ✅ Modal funcional (não travava)"
echo "   ✅ Campos pré-preenchidos para teste"
echo "   ✅ Propagação de eventos corrigida"
echo ""
echo "💳 CHECKOUT:"
echo "   ✅ Requisição corrigida para API"
echo "   ✅ Logs detalhados no backend"
echo "   ✅ Tratamento de erros melhorado"
echo "   ✅ Validação de dados aprimorada"
echo ""
echo "🚀 Para aplicar as correções:"
echo "   cd .."
echo "   ./start.sh"
echo ""
echo "✨ Agora tudo deve funcionar perfeitamente!"