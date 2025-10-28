const express = require("express");
const cors = require("cors");
const sqlite3 = require("sqlite3").verbose();
const bcrypt = require("bcrypt");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());
app.use("/images", express.static(path.join(__dirname, "public/images")));

const db = new sqlite3.Database("./database/cupcakes.db");

// ==========================================
// CRIAÇÃO DAS TABELAS
// ==========================================

db.serialize(() => {
  // Tabela de usuários (COM ROLE!)
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT DEFAULT 'user' CHECK(role IN ('user', 'admin')),
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

  // Tabela de favoritos
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
      const insert = db.prepare(
        `INSERT INTO cupcakes (name, description, price, image_url, category) VALUES (?, ?, ?, ?, ?)`
      );

      const cupcakes = [
        ["Cupcake de Chocolate", "Delicioso cupcake de chocolate com cobertura cremosa", 8.5, "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=400&h=300&fit=crop", "chocolate"],
        ["Cupcake de Baunilha", "Cupcake clássico de baunilha com buttercream", 7.5, "https://images.unsplash.com/photo-1426869884541-df7117556757?w=400&h=300&fit=crop", "baunilha"],
        ["Cupcake Red Velvet", "O famoso red velvet com cream cheese", 9.5, "https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?w=400&h=300&fit=crop", "especial"],
        ["Cupcake de Morango", "Cupcake de morango com pedaços da fruta", 8.0, "https://images.unsplash.com/photo-1519915212116-7cfef71f1d3e?w=400&h=300&fit=crop", "frutas"],
        ["Cupcake de Limão", "Refrescante cupcake de limão com cobertura cítrica", 8.0, "https://images.unsplash.com/photo-1599785209707-a456fc1337bb?w=400&h=300&fit=crop", "frutas"],
        ["Cupcake de Nutella", "Irresistível cupcake recheado com Nutella", 10.0, "https://images.unsplash.com/photo-1587668178277-295251f900ce?w=400&h=300&fit=crop", "especial"],
      ];

      cupcakes.forEach((cupcake) => {
        insert.run(cupcake);
      });
      insert.finalize();
      console.log("✅ Cupcakes inseridos!");
    }
  });
  checkCupcakes.finalize();

  // Criar usuário admin padrão
  db.get("SELECT COUNT(*) as count FROM users WHERE role = 'admin'", (err, row) => {
    if (!err && row.count === 0) {
      bcrypt.hash('admin123', 10, (err, hash) => {
        if (!err) {
          db.run(
            "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)",
            ['Administrador', 'admin@sweetcupcakes.com', hash, 'admin'],
            () => {
              console.log('👤 Usuário admin criado:');
              console.log('   Email: admin@sweetcupcakes.com');
              console.log('   Senha: admin123');
              console.log('   ⚠️  ALTERE A SENHA EM PRODUÇÃO!');
            }
          );
        }
      });
    }
  });
});

// ==========================================
// MIDDLEWARE DE AUTENTICAÇÃO ADMIN
// ==========================================

const authMiddleware = (req, res, next) => {
  const userId = req.headers['x-user-id'];
  
  if (!userId) {
    return res.status(401).json({ error: 'Autenticação necessária' });
  }

  db.get('SELECT id, role FROM users WHERE id = ?', [userId], (err, user) => {
    if (err || !user) {
      return res.status(401).json({ error: 'Usuário não encontrado' });
    }

    if (user.role !== 'admin') {
      return res.status(403).json({ error: 'Acesso negado. Apenas administradores.' });
    }

    req.user = user;
    next();
  });
};

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
        'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
        [name, email, hashedPassword, 'user'], // SEMPRE cria como 'user'
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Erro ao criar usuário' });
          }

          console.log('✅ Usuário criado:', name, '(user)');
          res.json({
            success: true,
            user: { id: this.lastID, name, email, role: 'user' },
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

      console.log('✅ Login bem-sucedido:', user.name, `(${user.role})`);
      res.json({
        success: true,
        user: { 
          id: user.id, 
          name: user.name, 
          email: user.email,
          role: user.role // Retorna o role
        },
        message: 'Login realizado com sucesso!'
      });
    } catch (error) {
      res.status(500).json({ error: 'Erro ao verificar senha' });
    }
  });
});

// Verificar permissão de admin
app.get('/api/auth/check-admin/:userId', (req, res) => {
  const { userId } = req.params;

  db.get('SELECT role FROM users WHERE id = ?', [userId], (err, user) => {
    if (err || !user) {
      return res.status(404).json({ isAdmin: false, error: 'Usuário não encontrado' });
    }

    res.json({ isAdmin: user.role === 'admin' });
  });
});

// ==========================================
// ROTAS DE FAVORITOS
// ==========================================

app.post("/api/favorites", (req, res) => {
  const { userId, cupcakeId } = req.body;

  if (!userId || !cupcakeId) {
    return res.status(400).json({ error: "userId e cupcakeId são obrigatórios" });
  }

  db.run(
    "INSERT OR IGNORE INTO favorites (user_id, cupcake_id) VALUES (?, ?)",
    [userId, cupcakeId],
    function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, message: "Adicionado aos favoritos!" });
    }
  );
});

app.delete("/api/favorites/:userId/:cupcakeId", (req, res) => {
  const { userId, cupcakeId } = req.params;

  db.run(
    "DELETE FROM favorites WHERE user_id = ? AND cupcake_id = ?",
    [userId, cupcakeId],
    function (err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ success: true, message: "Removido dos favoritos!" });
    }
  );
});

app.get("/api/favorites/:userId", (req, res) => {
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

app.get("/api/favorites/:userId/ids", (req, res) => {
  const { userId } = req.params;

  db.all(
    "SELECT cupcake_id FROM favorites WHERE user_id = ?",
    [userId],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      const ids = rows.map((row) => row.cupcake_id);
      res.json(ids);
    }
  );
});

// ==========================================
// ROTAS DE CUPCAKES (PÚBLICAS)
// ==========================================

app.get("/api/cupcakes", (req, res) => {
  db.all("SELECT * FROM cupcakes WHERE available = 1", (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(rows);
  });
});

app.get("/api/cupcakes/:id", (req, res) => {
  const { id } = req.params;
  db.get("SELECT * FROM cupcakes WHERE id = ?", [id], (err, row) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    if (!row) {
      res.status(404).json({ error: "Cupcake não encontrado" });
      return;
    }
    res.json(row);
  });
});

// ==========================================
// ROTAS DE PEDIDOS
// ==========================================

app.post("/api/orders", (req, res) => {
  const { userId, customerName, customerEmail, customerPhone, items } = req.body;

  if (!customerName || !customerEmail || !items || items.length === 0) {
    return res.status(400).json({ error: "Dados do pedido incompletos" });
  }

  let totalAmount = 0;
  const cupcakeIds = items.map((item) => item.cupcakeId);

  db.all(
    `SELECT id, price FROM cupcakes WHERE id IN (${cupcakeIds.map(() => "?").join(",")})`,
    cupcakeIds,
    (err, cupcakes) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      const cupcakeMap = {};
      cupcakes.forEach((cupcake) => {
        cupcakeMap[cupcake.id] = cupcake.price;
      });

      items.forEach((item) => {
        const price = cupcakeMap[item.cupcakeId];
        if (price) {
          totalAmount += price * item.quantity;
        }
      });

      db.run(
        "INSERT INTO orders (user_id, customer_name, customer_email, customer_phone, total_amount) VALUES (?, ?, ?, ?, ?)",
        [userId || null, customerName, customerEmail, customerPhone || "", totalAmount],
        function (err) {
          if (err) {
            return res.status(500).json({ error: err.message });
          }

          const orderId = this.lastID;
          const insertItem = db.prepare(
            "INSERT INTO order_items (order_id, cupcake_id, quantity, unit_price) VALUES (?, ?, ?, ?)"
          );

          items.forEach((item) => {
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
            message: "Pedido criado com sucesso!",
          });
        }
      );
    }
  );
});

app.get("/api/orders", (req, res) => {
  db.all(
    `SELECT o.*, 
           GROUP_CONCAT(c.name || ' (x' || oi.quantity || ')') as items
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    LEFT JOIN cupcakes c ON oi.cupcake_id = c.id
    GROUP BY o.id
    ORDER BY o.created_at DESC`,
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      res.json(rows);
    }
  );
});

// ==========================================
// ROTAS ADMINISTRATIVAS (PROTEGIDAS)
// ==========================================

// Criar novo cupcake
app.post('/api/admin/cupcakes', authMiddleware, (req, res) => {
  const { name, description, price, image_url, category } = req.body;

  if (!name || !price) {
    return res.status(400).json({ error: 'Nome e preço são obrigatórios' });
  }

  db.run(
    'INSERT INTO cupcakes (name, description, price, image_url, category) VALUES (?, ?, ?, ?, ?)',
    [name, description || '', price, image_url || '', category || 'outros'],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      console.log('✅ Cupcake criado:', name, `by admin ${req.user.id}`);
      res.json({
        success: true,
        cupcake: { id: this.lastID, name, description, price, image_url, category },
        message: 'Cupcake criado com sucesso!'
      });
    }
  );
});

// Atualizar cupcake
app.put('/api/admin/cupcakes/:id', authMiddleware, (req, res) => {
  const { id } = req.params;
  const { name, description, price, image_url, category, available } = req.body;

  if (!name || !price) {
    return res.status(400).json({ error: 'Nome e preço são obrigatórios' });
  }

  db.run(
    'UPDATE cupcakes SET name = ?, description = ?, price = ?, image_url = ?, category = ?, available = ? WHERE id = ?',
    [name, description || '', price, image_url || '', category || 'outros', available !== undefined ? available : 1, id],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ error: 'Cupcake não encontrado' });
      }

      console.log('✏️ Cupcake atualizado:', name, `by admin ${req.user.id}`);
      res.json({
        success: true,
        message: 'Cupcake atualizado com sucesso!'
      });
    }
  );
});

// Deletar cupcake
app.delete('/api/admin/cupcakes/:id', authMiddleware, (req, res) => {
  const { id } = req.params;

  db.run('DELETE FROM cupcakes WHERE id = ?', [id], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (this.changes === 0) {
      return res.status(404).json({ error: 'Cupcake não encontrado' });
    }

    console.log('🗑️ Cupcake deletado:', id, `by admin ${req.user.id}`);
    res.json({
      success: true,
      message: 'Cupcake deletado com sucesso!'
    });
  });
});

// Listar todos os cupcakes (incluindo inativos)
app.get('/api/admin/cupcakes', authMiddleware, (req, res) => {
  db.all("SELECT * FROM cupcakes ORDER BY created_at DESC", (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(rows);
  });
});

// Atualizar status do pedido
app.put('/api/admin/orders/:id', authMiddleware, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['pending', 'processing', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Status inválido' });
  }

  db.run(
    'UPDATE orders SET status = ? WHERE id = ?',
    [status, id],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (this.changes === 0) {
        return res.status(404).json({ error: 'Pedido não encontrado' });
      }

      console.log('📦 Status do pedido atualizado:', id, status, `by admin ${req.user.id}`);
      res.json({
        success: true,
        message: 'Status atualizado com sucesso!'
      });
    }
  );
});

// Detalhes completos do pedido
app.get('/api/admin/orders/:id', authMiddleware, (req, res) => {
  const { id } = req.params;

  db.get(
    `SELECT o.*, 
            json_group_array(
              json_object(
                'cupcake_name', c.name,
                'quantity', oi.quantity,
                'unit_price', oi.unit_price
              )
            ) as items
     FROM orders o
     LEFT JOIN order_items oi ON o.id = oi.order_id
     LEFT JOIN cupcakes c ON oi.cupcake_id = c.id
     WHERE o.id = ?
     GROUP BY o.id`,
    [id],
    (err, row) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      if (!row) {
        return res.status(404).json({ error: 'Pedido não encontrado' });
      }

      row.items = JSON.parse(row.items);
      res.json(row);
    }
  );
});

// Dashboard - Estatísticas
app.get('/api/admin/stats', authMiddleware, (req, res) => {
  const stats = {};

  db.get('SELECT COUNT(*) as total FROM orders', (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    stats.totalOrders = row.total;

    db.get('SELECT SUM(total_amount) as revenue FROM orders WHERE status != "cancelled"', (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      stats.totalRevenue = row.revenue || 0;

      db.get('SELECT COUNT(*) as total FROM cupcakes WHERE available = 1', (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        stats.totalCupcakes = row.total;

        db.get('SELECT COUNT(*) as total FROM orders WHERE status = "pending"', (err, row) => {
          if (err) return res.status(500).json({ error: err.message });
          stats.pendingOrders = row.total;

          db.get(
            `SELECT c.name, SUM(oi.quantity) as total_sold
             FROM order_items oi
             JOIN cupcakes c ON oi.cupcake_id = c.id
             GROUP BY oi.cupcake_id
             ORDER BY total_sold DESC
             LIMIT 1`,
            (err, row) => {
              if (err) return res.status(500).json({ error: err.message });
              stats.topCupcake = row || { name: 'N/A', total_sold: 0 };

              res.json(stats);
            }
          );
        });
      });
    });
  });
});

// ==========================================
// HEALTH CHECK
// ==========================================

app.get("/api/health", (req, res) => {
  res.json({ status: "OK", message: "Cupcake Store API com sistema admin!" });
});

// ==========================================
// INICIALIZAÇÃO DO SERVIDOR
// ==========================================

app.listen(PORT, () => {
  console.log(`🧁 Servidor rodando na porta ${PORT}`);
  console.log(`📊 API disponível em http://localhost:${PORT}/api`);
  console.log(`🔒 Sistema de autenticação admin ativo!`);
});

process.on("SIGINT", () => {
  db.close((err) => {
    if (err) {
      console.error(err.message);
    }
    console.log("💤 Conexão com banco de dados fechada.");
    process.exit(0);
  });
});