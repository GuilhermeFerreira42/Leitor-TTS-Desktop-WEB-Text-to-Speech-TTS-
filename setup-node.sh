#!/bin/bash
set -e

echo "==> Carregando nvm..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Verifica se node já está disponível
if ! command -v node &> /dev/null; then
  echo "==> Instalando nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  echo "==> Instalando Node.js 20..."
  nvm install 20
  nvm use 20
fi

echo "==> Node: $(node --version)"
echo "==> npm:  $(npm --version)"

# Instala o protoc via apt (necessário para compilar os .proto)
if ! command -v protoc &> /dev/null; then
  echo "==> Instalando protoc via apt..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq protobuf-compiler
fi

echo "==> protoc: $(protoc --version)"

echo "==> Navegando para o diretorio da extensao..."
cd /mnt/c/Users/Usuario/Desktop/vscode-next/cline-/cline/apps/vscode

echo "==> Instalando dependencias..."
npm install --legacy-peer-deps 2>&1 | tail -5

echo "==> Compilando protos..."
npm run protos

echo "==> Preparando pasta dist..."
mkdir -p dist

echo "==> Compilando a extensao (esbuild)..."
node esbuild.mjs

echo ""
echo "✅ Compilação concluída com sucesso!"
echo "O bundle foi gerado em: dist/extension.js"
