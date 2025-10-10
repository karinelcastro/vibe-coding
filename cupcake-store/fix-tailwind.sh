#!/bin/bash

echo "🔧 Corrigindo configuração do Tailwind CSS..."

# Verificar se estamos na pasta correta
if [ ! -d "frontend" ]; then
    echo "❌ Execute este script na pasta 'cupcake-store'"
    exit 1
fi

cd frontend

echo "📦 Reinstalando Tailwind CSS com versões compatíveis..."

# Remover Tailwind atual
npm uninstall tailwindcss postcss autoprefixer

# Instalar versões compatíveis
npm install -D tailwindcss@latest postcss@latest autoprefixer@latest

# Recriar configuração do Tailwind
echo "✅ Recriando configuração do Tailwind..."

cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
    "./public/index.html"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
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

# Recriar postcss.config.js
echo "✅ Recriando configuração do PostCSS..."

cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Corrigir index.css
echo "✅ Corrigindo index.css..."

cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

* {
  box-sizing: border-box;
}
EOF

echo "✅ Tailwind CSS configurado com sucesso!"
echo ""
echo "🚀 Agora execute:"
echo "   cd .."
echo "   ./start.sh"
echo ""
echo "🌐 O erro do Tailwind deve estar resolvido!"