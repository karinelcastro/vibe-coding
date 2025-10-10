#!/bin/bash

echo "🔄 Recriando banco de dados com URLs corretas..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# Parar qualquer processo rodando na porta 3001
echo "🛑 Parando processos na porta 3001..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || true
pkill -f "node.*server.js" 2>/dev/null || true

sleep 2

# Remover banco antigo
echo "🗑️ Removendo banco de dados antigo..."
rm -f backend/database/cupcakes.db

# Criar pasta database se não existir
mkdir -p backend/database

echo "✅ Banco removido. O servidor vai criar um novo com URLs do Unsplash!"
echo ""
echo "🚀 Agora execute:"
echo "   ./start.sh"
echo ""
echo "🖼️ As imagens dos cupcakes virão do Unsplash e devem funcionar!"