#!/bin/bash

echo "🔄 Recriando banco de dados com schema correto..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# Parar o servidor se estiver rodando
echo "🛑 Parando servidor..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
pkill -f "node.*server.js" 2>/dev/null || true

sleep 2

# Fazer backup do banco antigo (se existir)
if [ -f "backend/database/cupcakes.db" ]; then
    echo "💾 Fazendo backup do banco antigo..."
    mv backend/database/cupcakes.db backend/database/cupcakes.db.backup.$(date +%Y%m%d_%H%M%S)
fi

# Remover banco antigo
echo "🗑️ Removendo banco antigo..."
rm -f backend/database/cupcakes.db

echo "✅ Banco removido! O servidor vai criar um novo com a coluna user_id"
echo ""
echo "📊 Nova estrutura da tabela orders:"
echo "   - id"
echo "   - user_id (NOVO!)"
echo "   - customer_name"
echo "   - customer_email"
echo "   - customer_phone"
echo "   - total_amount"
echo "   - status"
echo "   - created_at"
echo ""
echo "🚀 Agora execute:"
echo "   ./start.sh"
echo ""
echo "✨ O banco será recriado automaticamente com a estrutura correta!"