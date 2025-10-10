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
