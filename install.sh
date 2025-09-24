#!/bin/bash

# Script de instalação do Detector LIBRAS para Raspberry Pi 3B+
# Autor: Sistema de Detecção LIBRAS
# Uso: ./install.sh

set -e  # Sai se algum comando falhar

echo "========================================"
echo "  DETECTOR LIBRAS - RASPBIAN DESKTOP"
echo "========================================"
echo ""
echo "Instalando dependências..."
echo ""

# Verifica se está rodando como root
if [[ $EUID -eq 0 ]]; then
   echo " Não execute como root (sudo). Execute como usuário pi."
   exit 1
fi

# Verifica se está no Raspbian
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo " Este script foi projetado para Raspberry Pi"
    echo "Continuando mesmo assim..."
fi

# Atualiza sistema
echo "📦 Atualizando sistema..."
sudo apt update -y
sudo apt upgrade -y

echo "🔧 Instalando dependências do sistema..."
sudo apt install -y python3-pip python3-dev python3-setuptools
sudo apt install -y cmake pkg-config build-essential
sudo apt install -y libjpeg-dev libtiff5-dev libjasper-dev libpng-dev
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt install -y libxvidcore-dev libx264-dev
sudo apt install -y libfontconfig1-dev libcairo2-dev
sudo apt install -y libgdk-pixbuf2.0-dev libpango1.0-dev
sudo apt install -y libgtk2.0-dev libgtk-3-dev
sudo apt install -y libatlas-base-dev gfortran
sudo apt install -y libhdf5-dev libhdf5-serial-dev libhdf5-103
sudo apt install -y libqtgui4 libqtwebkit4 libqt4-test python3-pyqt5
sudo apt install -y v4l-utils  # Para controle avançado de webcam
sudo apt install -y python3-tk  # Para GUI adicional
sudo apt install -y cheese  # Para testar webcam

echo "📷 Configurando suporte para Webcam USB..."
# Webcam USB não precisa de configuração especial

echo " Habilitando interfaces GPIO, SPI e I2C..."
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0

echo " Instalando bibliotecas Python..."

# Atualiza pip
python3 -m pip install --upgrade pip

echo " Instalando OpenCV com suporte GUI..."
pip3 install opencv-python==4.5.3.56
pip3 install opencv-contrib-python==4.5.3.56

echo " Instalando NumPy..."
pip3 install numpy

echo " Instalando RPi.GPIO..."
pip3 install RPi.GPIO

echo " Instalando dependências adicionais..."
pip3 install imutils
pip3 install pillow
pip3 install psutil  # Para monitoramento

echo " Configurando permissões do usuário..."
sudo usermod -a -G gpio pi
sudo usermod -a -G video pi

echo " Configurando arquivos do projeto..."

# Torna scripts executáveis
chmod +x start_libras.sh
chmod +x monitor.py
chmod +x optimize.sh

# Cria diretório para logs e debug
mkdir -p logs
mkdir -p debug_frames

# Copia configuração de exemplo se não existir
if [ ! -f "user_config.json" ]; then
    cp examples/user_config.json . 2>/dev/null || echo "Arquivo de config exemplo não encontrado"
fi

echo " Configurando memória GPU para OpenCV..."
# Verifica memória GPU atual
GPU_MEM=$(vcgencmd get_mem gpu | cut -d'=' -f2 | cut -d'M' -f1)
if [ "$GPU_MEM" -lt 64 ]; then
    echo "⚙️ Aumentando memória GPU para 128MB..."
    echo "gpu_mem=128" | sudo tee -a /boot/config.txt
    echo " Será necessário reiniciar após a instalação"
    NEED_REBOOT=1
fi

echo "🎨 Criando atalho na área de trabalho..."
cat > ~/Desktop/LibrasDetector.desktop << 'EOF'
[Desktop Entry]
Name=Detector LIBRAS
Comment=Detector de linguagem de sinais LIBRAS
Exec=lxterminal --working-directory=%PWD% -e "./start_libras.sh"
Icon=camera-video
Terminal=false
Type=Application
Categories=AudioVideo;Education;
StartupNotify=true
EOF

# Substitui %PWD% pelo diretório atual
sed -i "s|%PWD%|$(pwd)|g" ~/Desktop/LibrasDetector.desktop
chmod +x ~/Desktop/LibrasDetector.desktop

echo "📱 Criando entrada no menu de aplicações..."
sudo tee /usr/share/applications/libras-detector.desktop << EOF
[Desktop Entry]
Name=Detector LIBRAS
Comment=Sistema de detecção de linguagem de sinais
Exec=lxterminal --working-directory=$(pwd) -e "python3 libras_detector_rpi.py"
Icon=camera-video
Terminal=false
Type=Application
Categories=AudioVideo;Education;
StartupNotify=true
EOF

echo ""
echo "========================================"
echo " INSTALAÇÃO CONCLUÍDA!"
echo "========================================"
echo ""
echo " PRÓXIMOS PASSOS:"
echo ""
echo "1️  Conecte uma WEBCAM USB na Raspberry Pi"
echo "   - Teste com: lsusb | grep -i camera"
echo "   - Ou abra 'cheese' para testar"
echo ""
echo "2️  Conecte o MOTOR STEPPER aos pinos GPIO:"
echo "   IN1 → GPIO 18 (Pin 12)"
echo "   IN2 → GPIO 19 (Pin 35)"
echo "   IN3 → GPIO 20 (Pin 38)"
echo "   IN4 → GPIO 21 (Pin 40)"
echo "   VCC → 5V (Pin 2)"
echo "   GND → GND (Pin 6)"
echo ""

if [ "$NEED_REBOOT" = "1" ]; then
echo "3️  REINICIE o sistema:"
echo "   sudo reboot"
echo ""
echo "4️ Após reiniciar, teste os componentes:"
else
echo "3️ Teste os componentes:"
fi

echo "   python3 test_camera.py    # Testa webcam USB"
echo "   python3 test_gpio.py      # Testa motor stepper"
echo ""
echo "4️  Execute o detector:"
echo "   ./start_libras.sh"
echo "   # ou clique no atalho da área de trabalho"
echo ""
echo " Consulte a documentação em docs/ para mais detalhes"
echo ""
echo " DETECTOR LIBRAS PRONTO PARA USO!"
echo "========================================"

# Salva informações da instalação
cat > installation_info.txt << EOF
Instalação concluída em: $(date)
Sistema: $(uname -a)
Python: $(python3 --version)
OpenCV: $(python3 -c "import cv2; print(cv2.__version__)" 2>/dev/null || echo "Erro ao detectar")
Usuário: $(whoami)
Diretório: $(pwd)
EOF

echo "ℹ Informações da instalação salvas em: installation_info.txt"