#!/bin/bash
# Script de otimização para melhor performance

echo " Otimizando sistema para detector LIBRAS..."

# Fechar programas que consomem recursos
sudo pkill chromium-browser 2>/dev/null || true
sudo pkill firefox 2>/dev/null || true
sudo pkill libreoffice 2>/dev/null || true

# Ajustar prioridades
sudo sysctl vm.swappiness=10 2>/dev/null || true

echo " Otimizações aplicadas!"