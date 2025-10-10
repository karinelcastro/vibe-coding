#!/bin/bash

echo "📁 Criando estrutura de pastas para suas imagens..."

# Verificar se estamos na pasta correta
if [ ! -d "backend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

# Criar toda a estrutura de pastas
echo "✅ Criando: backend/public/images/cupcakes/"
mkdir -p backend/public/images/cupcakes

# Verificar se foi criado
if [ -d "backend/public/images/cupcakes" ]; then
    echo "✅ Pasta criada com sucesso!"
else
    echo "❌ Erro ao criar pasta"
    exit 1
fi

# Criar arquivo .gitkeep para garantir que a pasta seja versionada
touch backend/public/images/cupcakes/.gitkeep

# Criar README na pasta
cat > backend/public/images/cupcakes/README.md << 'EOF'
# 📸 Pasta de Imagens dos Cupcakes

## Como adicionar suas fotos:

### 1. Prepare suas fotos
- Formato: JPG ou PNG
- Tamanho recomendado: 800x600 pixels

### 2. Renomeie EXATAMENTE assim:
- `chocolate.jpg`
- `baunilha.jpg`
- `red-velvet.jpg`
- `morango.jpg`
- `limao.jpg`
- `nutella.jpg`

### 3. Cole as fotos NESTA PASTA

### 4. Reinicie o sistema:
```bash
cd ../../..  # voltar para raiz
rm backend/database/cupcakes.db
./start.sh
```

## 🎨 Dicas:
- Use boa iluminação
- Fundo limpo
- Mostre bem a cobertura
- Foto de cima ou levemente inclinada

## 🌐 Onde baixar fotos gratuitas:
- https://unsplash.com/s/photos/cupcake
- https://pixabay.com/images/search/cupcake/
- https://pexels.com/search/cupcake/
EOF

# Criar instruções na raiz do projeto
cat > COMO_ADICIONAR_FOTOS.txt << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║     📸 COMO ADICIONAR SUAS PRÓPRIAS FOTOS DE CUPCAKES     ║
╚═══════════════════════════════════════════════════════════╝

🎯 LOCALIZAÇÃO DA PASTA:
   📁 backend/public/images/cupcakes/

🎯 NOMES DOS ARQUIVOS (EXATOS):
   ✅ chocolate.jpg     - Cupcake de Chocolate
   ✅ baunilha.jpg      - Cupcake de Baunilha
   ✅ red-velvet.jpg    - Cupcake Red Velvet
   ✅ morango.jpg       - Cupcake de Morango
   ✅ limao.jpg         - Cupcake de Limão
   ✅ nutella.jpg       - Cupcake de Nutella

🎯 PASSO A PASSO:

   1. Abra a pasta: backend/public/images/cupcakes/
   
   2. Cole suas 6 fotos renomeadas
   
   3. No terminal, execute:
      rm backend/database/cupcakes.db
      ./start.sh

🎯 ESPECIFICAÇÕES DAS FOTOS:

   Formato: .jpg ou .png
   Tamanho: 800x600 pixels (recomendado)
   Peso: Máximo 500KB cada
   
🎯 DICAS PARA BOAS FOTOS:

   ✅ Luz natural (perto de janela)
   ✅ Fundo limpo (branco, madeira clara)
   ✅ Ângulo: 45° ou de cima
   ✅ Foco na cobertura do cupcake
   ✅ Sem sombras muito escuras

🌐 BAIXAR FOTOS GRATUITAS:

   Unsplash: https://unsplash.com/s/photos/cupcake
   Pexels:   https://pexels.com/search/cupcake/
   Pixabay:  https://pixabay.com/images/search/cupcake/

💡 ENQUANTO NÃO TIVER SUAS FOTOS:

   O sistema continuará usando imagens do Unsplash
   automaticamente. Sem problemas!

╔═══════════════════════════════════════════════════════════╗
║  Precisa de ajuda? Verifique o README.md na pasta images ║
╚═══════════════════════════════════════════════════════════╝
EOF

# Listar estrutura criada
echo ""
echo "📋 ESTRUTURA CRIADA:"
echo ""
tree -L 4 backend/public 2>/dev/null || find backend/public -type d 2>/dev/null | sed 's|[^/]*/| |g'

echo ""
echo "✅ ═══════════════════════════════════════════════"
echo "   PASTA CRIADA COM SUCESSO!"
echo "   ═══════════════════════════════════════════════"
echo ""
echo "📁 Localização:"
echo "   $(pwd)/backend/public/images/cupcakes/"
echo ""
echo "📝 Instruções detalhadas:"
echo "   $(pwd)/COMO_ADICIONAR_FOTOS.txt"
echo ""
echo "📸 AGORA VOCÊ PODE:"
echo ""
echo "   1. Abrir a pasta no explorador de arquivos:"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "      explorer backend\\public\\images\\cupcakes"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "      open backend/public/images/cupcakes"
else
    echo "      nautilus backend/public/images/cupcakes"
fi
echo ""
echo "   2. Colar suas 6 fotos renomeadas"
echo ""
echo "   3. Reiniciar o sistema:"
echo "      rm backend/database/cupcakes.db"
echo "      ./start.sh"
echo ""
echo "💡 Por enquanto, o sistema usa fotos do Unsplash!"
echo ""