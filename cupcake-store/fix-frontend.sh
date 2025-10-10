#!/bin/bash

echo "🔧 Corrigindo Frontend do Cupcake Store..."

# Verificar se estamos na pasta correta
if [ ! -d "frontend/src" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# Backup do App.js original
cp frontend/src/App.js frontend/src/App.js.backup 2>/dev/null

echo "✅ Criando App.js corrigido..."

# Criar o App.js correto
cat > frontend/src/App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { ShoppingCart, Plus, Minus, Heart, Star, Phone, Mail, MapPin } from 'lucide-react';

const API_BASE = 'http://localhost:3001/api';

// Componente de Loading
const Loading = () => (
  <div className="flex justify-center items-center h-64">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-pink-500"></div>
  </div>
);

// Componente do Header
const Header = ({ cartItems, onCartClick }) => {
  const itemCount = cartItems.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <header className="bg-gradient-to-r from-pink-500 to-purple-600 text-white shadow-lg">
      <div className="container mx-auto px-4 py-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold">🧁 Sweet Cupcakes</h1>
            <p className="text-pink-100 mt-1">Os melhores cupcakes da cidade!</p>
          </div>
          <button
            onClick={onCartClick}
            className="relative bg-white/20 hover:bg-white/30 px-4 py-2 rounded-full transition-all duration-200 flex items-center space-x-2"
          >
            <ShoppingCart className="w-5 h-5" />
            <span className="font-medium">Carrinho</span>
            {itemCount > 0 && (
              <span className="absolute -top-2 -right-2 bg-yellow-400 text-pink-600 rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold">
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
    <div className="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1">
      <div className="relative">
        <img
          src={cupcake.image_url}
          alt={cupcake.name}
          className="w-full h-48 object-cover"
        />
        <button
          onClick={() => setIsLiked(!isLiked)}
          className={`absolute top-3 right-3 p-2 rounded-full transition-colors ${
            isLiked ? 'bg-red-500 text-white' : 'bg-white/80 text-gray-600'
          }`}
        >
          <Heart className="w-4 h-4" fill={isLiked ? 'currentColor' : 'none'} />
        </button>
        <div className="absolute top-3 left-3">
          <span className="bg-pink-500 text-white px-2 py-1 rounded-full text-xs font-bold capitalize">
            {cupcake.category}
          </span>
        </div>
      </div>

      <div className="p-4">
        <h3 className="text-lg font-bold text-gray-800 mb-2">{cupcake.name}</h3>
        <p className="text-gray-600 text-sm mb-3">{cupcake.description}</p>
        
        <div className="flex items-center justify-between">
          <div className="flex flex-col">
            <span className="text-2xl font-bold text-pink-600">
              R$ {parseFloat(cupcake.price).toFixed(2)}
            </span>
            <div className="flex items-center mt-1">
              {[...Array(5)].map((_, i) => (
                <Star key={i} className="w-3 h-3 fill-yellow-400 text-yellow-400" />
              ))}
              <span className="text-xs text-gray-500 ml-1">(4.8)</span>
            </div>
          </div>
          
          <button
            onClick={() => onAddToCart(cupcake)}
            className="bg-gradient-to-r from-pink-500 to-purple-600 text-white px-4 py-2 rounded-lg hover:from-pink-600 hover:to-purple-700 transition-all duration-200 flex items-center space-x-1 transform hover:scale-105"
          >
            <Plus className="w-4 h-4" />
            <span className="text-sm font-medium">Adicionar</span>
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
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loading />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="bg-red-100 border border-red-400 text-red-700 px-6 py-4 rounded-lg">
            <h2 className="text-xl font-bold mb-2">⚠️ Erro de Conexão</h2>
            <p className="mb-4">{error}</p>
            <button
              onClick={fetchCupcakes}
              className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition-colors"
            >
              Tentar Novamente
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header cartItems={cartItems} onCartClick={() => console.log('Cart clicked')} />

      <main className="container mx-auto px-4 py-8">
        <div className="text-center mb-8">
          <h2 className="text-4xl font-bold text-gray-800 mb-4">Nossos Cupcakes</h2>
          <p className="text-gray-600 max-w-2xl mx-auto">
            Descubra nossa incrível seleção de cupcakes artesanais, feitos com amor e os melhores ingredientes.
          </p>
        </div>

        {cupcakes.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-gray-500">Carregando cupcakes...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {cupcakes.map(cupcake => (
              <CupcakeCard
                key={cupcake.id}
                cupcake={cupcake}
                onAddToCart={addToCart}
              />
            ))}
          </div>
        )}

        <div className="mt-16 bg-white rounded-xl shadow-lg p-8 text-center">
          <h3 className="text-2xl font-bold text-gray-800 mb-4">🎉 Sistema Funcionando!</h3>
          <p className="text-gray-600">
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

echo "✅ Configurando CSS do Tailwind..."

# Criar index.css correto
cat > frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  margin: 0;
  padding: 0;
}
EOF

echo "✅ Frontend corrigido!"
echo ""
echo "🚀 Agora execute:"
echo "   ./start.sh"
echo ""
echo "🌐 Acesse: http://localhost:3000"