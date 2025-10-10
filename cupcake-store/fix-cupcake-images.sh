#!/bin/bash

echo "🖼️ Corrigindo imagens dos cupcakes para corresponder aos sabores..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# Parar o servidor
echo "🛑 Parando servidor..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
pkill -f "node.*server.js" 2>/dev/null || true

sleep 2

# Remover banco antigo
echo "🗑️ Removendo banco para recriar com imagens corretas..."
rm -f backend/database/cupcakes.db

# Atualizar server.js com URLs de imagens corretas
echo "✅ Atualizando server.js com imagens específicas para cada sabor..."

cat > backend/server.js << 'EOFSERVER'
const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

const db = new sqlite3.Database('./database/cupcakes.db');

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

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

  db.run(`CREATE TABLE IF NOT EXISTS order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER,
    cupcake_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY(order_id) REFERENCES orders(id),
    FOREIGN KEY(cupcake_id) REFERENCES cupcakes(id)
  )`);

  const checkCupcakes = db.prepare("SELECT COUNT(*) as count FROM cupcakes");
  checkCupcakes.get((err, row) => {
    if (row.count === 0) {
      const insert = db.prepare(`INSERT INTO cupcakes (name, description, price, image_url, category) VALUES (?, ?, ?, ?, ?)`);
      
      // URLs de imagens ESPECÍFICAS para cada sabor
      const cupcakes = [
        [
          'Cupcake de Chocolate', 
          'Delicioso cupcake de chocolate com cobertura cremosa', 
          8.50, 
          'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=400&h=300&fit=crop&q=80',
          'chocolate'
        ],
        [
          'Cupcake de Baunilha', 
          'Cupcake clássico de baunilha com buttercream', 
          7.50, 
          'https://images.unsplash.com/photo-1426869884541-df7117556757?w=400&h=300&fit=crop&q=80',
          'baunilha'
        ],
        [
          'Cupcake Red Velvet', 
          'O famoso red velvet com cream cheese', 
          9.50, 
          'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?w=400&h=300&fit=crop&q=80',
          'especial'
        ],
        [
          'Cupcake de Morango', 
          'Cupcake de morango com pedaços da fruta', 
          8.00, 
          'https://images.unsplash.com/photo-1519915212116-7cfef71f1d3e?w=400&h=300&fit=crop&q=80',
          'frutas'
        ],
        [
          'Cupcake de Limão', 
          'Refrescante cupcake de limão com cobertura cítrica', 
          8.00, 
          'https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=400&h=300&fit=crop&q=80',
          'frutas'
        ],
        [
          'Cupcake de Nutella', 
          'Irresistível cupcake recheado com Nutella', 
          10.00, 
          'https://images.unsplash.com/photo-1587668178277-295251f900ce?w=400&h=300&fit=crop&q=80',
          'especial'
        ]
      ];

      cupcakes.forEach(cupcake => {
        insert.run(cupcake);
      });
      insert.finalize();
      console.log('✅ Cupcakes inseridos com imagens específicas para cada sabor!');
    }
  });
  checkCupcakes.finalize();
});

// ROTAS DE AUTENTICAÇÃO
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

// ROTAS DE CUPCAKES
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

// ROTAS DE PEDIDOS
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
  res.json({ status: 'OK', message: 'Cupcake Store API rodando!' });
});

app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
  console.log(`🖼️ Imagens específicas para cada sabor de cupcake!`);
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
EOFSERVER

echo "✅ Server.js atualizado com URLs de imagens corretas!"
echo ""
echo "🖼️ IMAGENS ESPECÍFICAS:"
echo "   🍫 Chocolate - Cupcake marrom com cobertura de chocolate"
echo "   🤍 Baunilha - Cupcake branco com buttercream clássico"
echo "   ❤️ Red Velvet - Cupcake vermelho com cream cheese"
echo "   🍓 Morango - Cupcake rosa com morangos"
echo "   🍋 Limão - Cupcake amarelo com cobertura cítrica"
echo "   🍫 Nutella - Cupcake com chocolate e avelãs"
echo ""
echo "🚀 Agora execute:"
echo "   ./start.sh"
echo ""
echo "✨ As imagens agora correspondem aos sabores!"