#!/bin/bash

echo "🔧 Removendo Tailwind e usando CSS puro para funcionar..."

# Verificar se estamos na pasta correta
if [ ! -d "frontend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

cd frontend

echo "🗑️ Removendo Tailwind CSS..."
npm uninstall tailwindcss postcss autoprefixer

# Remover arquivos de configuração do Tailwind
rm -f tailwind.config.js postcss.config.js

echo "✅ Criando CSS customizado..."

# Criar index.css com CSS puro
cat > src/index.css << 'EOF'
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f9fafb;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

/* Header Styles */
.header {
  background: linear-gradient(to right, #ec4899, #a855f7);
  color: white;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 0;
}

.header h1 {
  font-size: 2rem;
  font-weight: 700;
}

.header p {
  color: #fce7f3;
  margin-top: 0.25rem;
}

.cart-button {
  position: relative;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 9999px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 500;
  transition: all 0.2s;
}

.cart-button:hover {
  background: rgba(255, 255, 255, 0.3);
}

.cart-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  background: #facc15;
  color: #ec4899;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
  font-weight: 700;
}

/* Main Content */
.main-content {
  padding: 2rem 0;
}

.hero {
  text-align: center;
  margin-bottom: 2rem;
}

.hero h2 {
  font-size: 2.5rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 1rem;
}

.hero p {
  color: #6b7280;
  max-width: 42rem;
  margin: 0 auto;
}

/* Loading */
.loading {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 16rem;
}

.spinner {
  border: 3px solid #f3f4f6;
  border-top: 3px solid #ec4899;
  border-radius: 50%;
  width: 3rem;
  height: 3rem;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Error */
.error-container {
  min-height: 100vh;
  background: #f9fafb;
  display: flex;
  align-items: center;
  justify-content: center;
}

.error-box {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
  padding: 1.5rem;
  border-radius: 0.5rem;
  text-align: center;
  max-width: 28rem;
}

.error-box h2 {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.error-box button {
  background: #dc2626;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  cursor: pointer;
  margin-top: 1rem;
  transition: background-color 0.2s;
}

.error-box button:hover {
  background: #b91c1c;
}

/* Grid */
.cupcakes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

/* Card */
.cupcake-card {
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: all 0.3s;
}

.cupcake-card:hover {
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.card-image-container {
  position: relative;
}

.card-image {
  width: 100%;
  height: 12rem;
  object-fit: cover;
}

.like-button {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  background: rgba(255, 255, 255, 0.8);
  color: #6b7280;
  border: none;
  padding: 0.5rem;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.2s;
}

.like-button.liked {
  background: #dc2626;
  color: white;
}

.category-badge {
  position: absolute;
  top: 0.75rem;
  left: 0.75rem;
  background: #ec4899;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: capitalize;
}

.card-content {
  padding: 1rem;
}

.card-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.card-description {
  color: #6b7280;
  font-size: 0.875rem;
  margin-bottom: 0.75rem;
}

.card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.price-section {
  display: flex;
  flex-direction: column;
}

.price {
  font-size: 1.5rem;
  font-weight: 700;
  color: #ec4899;
}

.rating {
  display: flex;
  align-items: center;
  margin-top: 0.25rem;
}

.star {
  color: #facc15;
  font-size: 0.75rem;
  margin-right: 0.125rem;
}

.rating-text {
  font-size: 0.75rem;
  color: #6b7280;
  margin-left: 0.25rem;
}

.add-button {
  background: linear-gradient(to right, #ec4899, #a855f7);
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s;
}

.add-button:hover {
  background: linear-gradient(to right, #db2777, #9333ea);
  transform: scale(1.05);
}

/* Success message */
.success-banner {
  background: #10b981;
  color: white;
  text-align: center;
  padding: 1rem;
  animation: bounce 0.5s;
}

.success-banner p {
  font-weight: 500;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-10px);
  }
  60% {
    transform: translateY(-5px);
  }
}

/* Status section */
.status-section {
  margin-top: 4rem;
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  padding: 2rem;
  text-align: center;
}

.status-section h3 {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 1rem;
}

.status-section p {
  color: #6b7280;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 1.5rem;
  }
  
  .hero h2 {
    font-size: 2rem;
  }
  
  .cupcakes-grid {
    grid-template-columns: 1fr;
  }
}
EOF

echo "✅ Criando App.js sem Tailwind..."

# Criar App.js sem Tailwind
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
const Header = ({ cartItems, onCartClick }) => {
  const itemCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <header className="header">
      <div className="container">
        <div className="header-content">
          <div>
            <h1>🧁 Sweet Cupcakes</h1>
            <p>Os melhores cupcakes da cidade!</p>
          </div>
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
    </header>
  );
};

// Componente do Card de Cupcake
const CupcakeCard = ({ cupcake, onAddToCart }) => {
  const [isLiked, setIsLiked] = useState(false);

  return (
    <div className="cupcake-card">
      <div className="card-image-container">
        <img
          src={cupcake.image_url}
          alt={cupcake.name}
          className="card-image"
        />
        <button
          onClick={() => setIsLiked(!isLiked)}
          className={`like-button ${isLiked ? 'liked' : ''}`}
        >
          {isLiked ? '❤️' : '🤍'}
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
            ➕
            <span>Adicionar</span>
          </button>
        </div>
      </div>
    </div>
  );
};

// Componente Principal
const App = () => {
  const [cupcakes, setCupcakes] = useState([]);
  const [cartItems, setCartItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchCupcakes();
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
      <Header cartItems={cartItems} onCartClick={() => console.log('Cart clicked')} />

      <main className="container main-content">
        <div className="hero">
          <h2>Nossos Cupcakes</h2>
          <p>
            Descubra nossa incrível seleção de cupcakes artesanais, feitos com amor e os melhores ingredientes.
          </p>
        </div>

        {cupcakes.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '2rem 0' }}>
            <p style={{ color: '#6b7280' }}>Carregando cupcakes...</p>
          </div>
        ) : (
          <div className="cupcakes-grid">
            {cupcakes.map(cupcake => (
              <CupcakeCard
                key={cupcake.id}
                cupcake={cupcake}
                onAddToCart={addToCart}
              />
            ))}
          </div>
        )}

        <div className="status-section">
          <h3>🎉 Sistema Funcionando!</h3>
          <p>
            Frontend e Backend conectados com sucesso!<br />
            Carrinho: {cartItems.length} itens
          </p>
        </div>
      </main>
    </div>
  );
};

export default App;
EOF

echo "✅ Sistema corrigido sem Tailwind!"
echo ""
echo "🚀 Agora execute:"
echo "   cd .."
echo "   ./start.sh"
echo ""
echo "🌐 O sistema deve funcionar perfeitamente!"