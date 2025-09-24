#!/bin/bash
# Script para iniciar o detector LIBRAS

echo "========================================"
echo "🚀 INICIANDO DETECTOR LIBRAS"
echo "========================================"
echo "Aguarde alguns segundos para inicialização..."
echo ""

# Verifica se está no ambiente desktop
if [ -z "$DISPLAY" ]; then
    echo " ERRO: Execute no ambiente desktop (não SSH)"
    echo " Abra um terminal na interface gráfica"
    exit 1
fi

# Aguarda sistema estabilizar
sleep 2

# Otimizações opcionais
if [ -f "./optimize.sh" ]; then
    echo " Aplicando otimizações..."
    ./optimize.sh
fi

# Inicia o detector
echo " Iniciando detector LIBRAS..."
python3 libras_detector_rpi.py

echo ""
echo " Detector finalizado."
echo "========================================"