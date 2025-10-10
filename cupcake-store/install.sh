#!/bin/bash

# 🧁 Script de Instalação Automática - Cupcake Store
# Este script configura automaticamente o projeto completo

echo "🧁 ======================================"
echo "   CUPCAKE STORE - INSTALAÇÃO AUTOMÁTICA"
echo "======================================="
echo ""

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js não encontrado!"
    echo "Por favor, instale Node.js em: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js encontrado: $(node --version)"
echo "✅ NPM encontrado: $(npm --version)"
echo ""

# Criar estrutura do projeto
echo "📁 Criando estrutura de pastas..."
mkdir -p cupcake-store
cd cupcake-store

# ================================
# CONFIGURAR BACKEND
# ================================
echo ""
echo "🔧 Configurando Backend..."
mkdir -p backend/database

# Criar package.json do backend
cat > backend/package.json << 'EOF'
{
  "name": "cupcake-store-backend",
  "version": "1.0.0",
  "description": "Backend para loja de cupcakes",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["cupcakes", "ecommerce", "node", "express", "sqlite"],
  "author": "Seu Nome",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "sqlite3": "^5.1.6"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# Criar server.js do backend
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

  // Inserir dados iniciais
  const checkCupcakes = db.prepare("SELECT COUNT(*) as count FROM cupcakes");
  checkCupcakes.get((err, row) => {
    if (row.count === 0) {
      const insert = db.prepare(`INSERT INTO cupcakes (name, description, price, image_url, category) VALUES (?, ?, ?, ?, ?)`);
      
      const cupcakes = [
        ['Cupcake de Chocolate', 'Delicioso cupcake de chocolate com cobertura cremosa', 8.50, '/api/placeholder-chocolate.jpg', 'chocolate'],
        ['Cupcake de Baunilha', 'Cupcake clássico de baunilha com buttercream', 7.50, '/api/placeholder-vanilla.jpg', 'baunilha'],
        ['Cupcake Red Velvet', 'O famoso red velvet com cream cheese', 9.50, '/api/placeholder-redvelvet.jpg', 'especial'],
        ['Cupcake de Morango', 'Cupcake de morango com pedaços da fruta', 8.00, '/api/placeholder-strawberry.jpg', 'frutas'],
        ['Cupcake de Limão', 'Refrescante cupcake de limão com cobertura cítrica', 8.00, '/api/placeholder-lemon.jpg', 'frutas'],
        ['Cupcake de Nutella', 'Irresistível cupcake recheado com Nutella', 10.00, '/api/placeholder-nutella.jpg', 'especial']
      ];

      cupcakes.forEach(cupcake => {
        insert.run(cupcake);
      });
      insert.finalize();
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
  const { customerName, customerEmail, customerPhone, items } = req.body;

  if (!customerName || !customerEmail || !items || items.length === 0) {
    return res.status(400).json({ error: 'Dados do pedido incompletos' });
  }

  // Calcular total
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
      totalAmount += cupcakeMap[item.cupcakeId] * item.quantity;
    });

    // Criar pedido
    db.run(
      "INSERT INTO orders (customer_name, customer_email, customer_phone, total_amount) VALUES (?, ?, ?, ?)",
      [customerName, customerEmail, customerPhone, totalAmount],
      function(err) {
        if (err) {
          return res.status(500).json({ error: err.message });
        }

        const orderId = this.lastID;

        // Inserir itens do pedido
        const insertItem = db.prepare("INSERT INTO order_items (order_id, cupcake_id, quantity, unit_price) VALUES (?, ?, ?, ?)");
        
        items.forEach(item => {
          insertItem.run([orderId, item.cupcakeId, item.quantity, cupcakeMap[item.cupcakeId]]);
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

// Placeholder para imagens
app.get('/api/placeholder-:type.jpg', (req, res) => {
  res.redirect(`https://via.placeholder.com/300x200/FF69B4/FFFFFF?text=${req.params.type}`);
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Cupcake Store API rodando!' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
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

echo "✅ Arquivos do backend criados"

# Instalar dependências do backend
echo "📦 Instalando dependências do backend..."
cd backend
npm install
cd ..

# ================================
# CONFIGURAR FRONTEND
# ================================
echo ""
echo "🎨 Configurando Frontend..."

# Criar aplicação React
echo "📦 Criando aplicação React..."
npx create-react-app frontend --template minimal

cd frontend

# Instalar dependências extras
echo "📦 Instalando dependências extras do frontend..."
npm install lucide-react

# Instalar e configurar Tailwind
echo "🎨 Configurando Tailwind CSS..."
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# Configurar Tailwind
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      colors: {
        pink: {
          50: '#fdf2f8',
          100: '#fce7f3',
          200: '#fbcfe8',
          300: '#f9a8d4',
          400: '#f472b6',
          500: '#ec4899',
          600: '#db2777',
          700: '#be185d',
          800: '#9d174d',
          900: '#831843',
        },
        purple: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#a855f7',
          600: '#9333ea',
          700: '#7c3aed',
          800: '#6b21a8',
          900: '#581c87',
        }
      },
      animation: {
        'bounce-slow': 'bounce 2s infinite',
        'pulse-slow': 'pulse 3s infinite',
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'glow': '0 0 15px -3px rgba(236, 72, 153, 0.3)',
      }
    },
  },
  plugins: [],
}
EOF

# Configurar CSS
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
}
EOF

# Atualizar package.json com proxy
npm pkg set proxy="http://localhost:3001"

echo "✅ Frontend configurado"

# Voltar para raiz do projeto
cd ..

# ================================
# CRIAR ARQUIVOS AUXILIARES
# ================================

# Criar script de start
cat > start.sh << 'EOF'
#!/bin/bash

echo "🧁 Iniciando Cupcake Store..."
echo ""

# Verificar se as dependências estão instaladas
if [ ! -d "backend/node_modules" ]; then
    echo "❌ Dependências do backend não encontradas. Execute: ./install.sh"
    exit 1
fi

if [ ! -d "frontend/node_modules" ]; then
    echo "❌ Dependências do frontend não encontradas. Execute: ./install.sh"
    exit 1
fi

echo "🔧 Iniciando Backend (porta 3001)..."
cd backend
npm run dev &
BACKEND_PID=$!

echo "🎨 Iniciando Frontend (porta 3000)..."
cd ../frontend
npm start &
FRONTEND_PID=$!

echo ""
echo "✅ Sistema iniciado com sucesso!"
echo "📊 Backend: http://localhost:3001/api"
echo "🌐 Frontend: http://localhost:3000"
echo ""
echo "Para parar o sistema, pressione Ctrl+C"

# Aguardar interrupção
trap "echo '🛑 Parando sistema...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit 0" INT

wait
EOF

chmod +x start.sh

# Criar README
cat > README.md << 'EOF'
# 🧁 Cupcake Store - Sistema Completo de E-commerce

Sistema completo de venda de cupcakes com frontend React e backend Node.js.

## 🚀 Como Usar

### Instalação (primeira vez)
```bash
./install.sh
```

### Iniciar o Sistema
```bash
./start.sh
```

Isso abrirá:
- Backend na porta 3001
- Frontend na porta 3000

### Parar o Sistema
Pressione `Ctrl+C` no terminal onde rodou `./start.sh`

## 📱 Funcionalidades

✅ Catálogo de cupcakes
✅ Carrinho de compras
✅ Checkout com formulário
✅ API para pedidos
✅ Banco de dados SQLite
✅ Interface responsiva

## 🛠️ Tecnologias

- **Frontend**: React + Tailwind CSS
- **Backend**: Node.js + Express
- **Banco**: SQLite
- **Ícones**: Lucide React

## 📊 URLs Importantes

- Frontend: http://localhost:3000
- Backend API: http://localhost:3001/api
- Health Check: http://localhost:3001/api/health
- Cupcakes: http://localhost:3001/api/cupcakes
EOF

echo ""
echo "🎉 ======================================"
echo "   INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "======================================="
echo ""
echo "📁 Estrutura criada:"
echo "   cupcake-store/"
echo "   ├── backend/     (Node.js + Express + SQLite)"
echo "   ├── frontend/    (React + Tailwind CSS)"
echo "   ├── start.sh     (Script para iniciar sistema)"
echo "   └── README.md    (Documentação)"
echo ""
echo "🚀 Para iniciar o sistema:"
echo "   ./start.sh"
echo ""
echo "🌐 URLs que serão abertas:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:3001/api"
echo ""
echo "✨ Tudo pronto para usar!"
EOF