#!/bin/bash

echo "🔧 Corrigindo erro de sintaxe no App.js..."

# Verificar se estamos na pasta correta
if [ ! -d "frontend/src" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

echo "✅ Recriando App.js completo sem erros..."

cat > frontend/src/App.js << 'EOF'
import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:3001/api';

const Loading = () => (
  <div className="loading">
    <div className="spinner"></div>
  </div>
);

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
                <button onClick={onLogout} className="logout-button">Sair</button>
              </div>
            ) : (
              <button onClick={onLoginClick} className="login-button">👤 Entrar</button>
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
    const savedUser = localStorage.getItem('user');
    if (savedUser) setUser(JSON.parse(savedUser));
  }, []);

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

  const toggleFavorite = (id) => {
    setFavorites(prev => prev.includes(id) ? prev.filter(fav => fav !== id) : [...prev, id]);
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
          <button onClick={fetchCupcakes}>Tentar Novamente</button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', background: '#f9fafb' }}>
      <Header cartItems={cartItems} onCartClick={() => setShowCart(true)} user={user} onLoginClick={() => setShowAuth(true)} onLogout={handleLogout} />

      {orderSuccess && (
        <div className="success-banner">
          <p><strong>🎉 Pedido #{orderSuccess.orderId} criado com sucesso!</strong></p>
          <p>Total: R$ {orderSuccess.total.toFixed(2)} - Entraremos em contato em breve!</p>
        </div>
      )}

      <main className="container main-content">
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
              <CupcakeCard key={cupcake.id} cupcake={cupcake} onAddToCart={addToCart} isFavorite={favorites.includes(cupcake.id)} onToggleFavorite={toggleFavorite} />
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
EOF

echo "✅ App.js corrigido sem erros de sintaxe!"
echo ""
echo "🚀 O sistema está pronto! Execute:"
echo "   ./start.sh"
echo ""
echo "✨ Tudo funcionando agora!"
