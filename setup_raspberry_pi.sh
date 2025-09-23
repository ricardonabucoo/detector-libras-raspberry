#!/bin/bash

# 🤖 SCRIPT DE CONFIGURAÇÃO COMPLETA PARA DETECTOR LIBRAS
# ========================================================
# Este script automatiza TODA a configuração necessária na Raspberry Pi 3B+
# Execute apenas UMA VEZ após instalar o Ubuntu na Pi

echo "🚀 Configurando Raspberry Pi 3B+ para Detector LIBRAS"
echo "====================================================="
echo ""
echo "⚠️  IMPORTANTE: Este processo pode levar 20-30 minutos"
echo "    Mantenha a Pi conectada à internet"
echo ""
read -p "Pressione Enter para continuar ou Ctrl+C para cancelar..."

# =============================================================================
# 1️⃣ ATUALIZAÇÃO DO SISTEMA
# =============================================================================
echo ""
echo "📦 ETAPA 1/8: Atualizando sistema Ubuntu..."
echo "============================================"
sudo apt update && sudo apt upgrade -y

# =============================================================================
# 2️⃣ INSTALAÇÃO DE DEPENDÊNCIAS DO SISTEMA
# =============================================================================
echo ""
echo "🔧 ETAPA 2/8: Instalando dependências do sistema..."
echo "=================================================="

# Python e ferramentas básicas
echo "  🐍 Instalando Python 3 e ferramentas..."
sudo apt install -y python3-pip python3-dev python3-venv python3-setuptools

# OpenCV e bibliotecas de imagem
echo "  📷 Instalando bibliotecas OpenCV e imagem..."
sudo apt install -y libopencv-dev python3-opencv
sudo apt install -y cmake pkg-config libjpeg-dev libtiff5-dev libjasper-dev libpng-dev
sudo apt install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt install -y libxvidcore-dev libx264-dev libfontconfig1-dev libcairo2-dev
sudo apt install -y libgdk-pixbuf2.0-dev libpango1.0-dev libgtk2.0-dev libgtk-3-dev

# Bibliotecas matemáticas e científicas
echo "  🧮 Instalando bibliotecas científicas..."
sudo apt install -y libatlas-base-dev gfortran libhdf5-dev libhdf5-serial-dev libhdf5-103
sudo apt install -y python3-pyqt5 python3-h5py

# Bibliotecas adicionais para compatibilidade
sudo apt install -y libjasper1 libqtgui4 libqt4-test 2>/dev/null || true

# =============================================================================
# 3️⃣ CONFIGURAÇÃO DE HARDWARE (GPIO, CÂMERA)
# =============================================================================
echo ""
echo "🔌 ETAPA 3/8: Configurando hardware (GPIO, câmera)..."
echo "===================================================="

# Backup do config.txt
sudo cp /boot/config.txt /boot/config.txt.backup 2>/dev/null || sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# Configura GPIO
echo "  ⚡ Habilitando GPIO, I2C, SPI..."
CONFIG_FILE="/boot/config.txt"
if [[ ! -f "$CONFIG_FILE" ]]; then
    CONFIG_FILE="/boot/firmware/config.txt"
fi

# Adiciona configurações se não existirem
grep -q "dtparam=i2c_arm=on" $CONFIG_FILE || echo "dtparam=i2c_arm=on" | sudo tee -a $CONFIG_FILE
grep -q "dtparam=spi=on" $CONFIG_FILE || echo "dtparam=spi=on" | sudo tee -a $CONFIG_FILE
grep -q "start_x=1" $CONFIG_FILE || echo "start_x=1" | sudo tee -a $CONFIG_FILE
grep -q "gpu_mem=128" $CONFIG_FILE || echo "gpu_mem=128" | sudo tee -a $CONFIG_FILE

# Configura usuário para acessar hardware
echo "  👤 Configurando permissões de usuário..."
sudo usermod -a -G dialout,gpio,i2c,spi,video $USER

# =============================================================================
# 4️⃣ CRIAÇÃO DO AMBIENTE VIRTUAL PYTHON
# =============================================================================
echo ""
echo "🐍 ETAPA 4/8: Criando ambiente virtual Python..."
echo "==============================================="

# Remove ambiente antigo se existir
if [[ -d ~/libras_detector_env ]]; then
    echo "  🗑️  Removendo ambiente virtual antigo..."
    rm -rf ~/libras_detector_env
fi

# Cria novo ambiente
python3 -m venv ~/libras_detector_env
source ~/libras_detector_env/bin/activate

# Atualiza pip
pip install --upgrade pip setuptools wheel

# =============================================================================
# 5️⃣ INSTALAÇÃO DE BIBLIOTECAS PYTHON
# =============================================================================
echo ""
echo "📚 ETAPA 5/8: Instalando bibliotecas Python..."
echo "============================================="

# Instala bibliotecas compatíveis com Pi 3B+
echo "  📦 NumPy (otimizado para ARM)..."
pip install numpy==1.19.5

echo "  📷 OpenCV (versão compatível)..."
pip install opencv-python==4.5.1.48

echo "  🔌 RPi.GPIO para controle do hardware..."
pip install RPi.GPIO

echo "  📊 Bibliotecas adicionais..."
pip install Pillow==8.3.2
pip install scipy==1.7.3 2>/dev/null || echo "  ⚠️  SciPy opcional não instalado"

# =============================================================================
# 6️⃣ CRIAÇÃO DA ESTRUTURA DO PROJETO
# =============================================================================
echo ""
echo "📁 ETAPA 6/8: Criando estrutura do projeto..."
echo "============================================"

# Cria diretório principal
mkdir -p ~/libras_detector
cd ~/libras_detector

# Cria script de inicialização
echo "  📄 Criando script de inicialização..."
cat > start_detector.sh << 'EOF'
#!/bin/bash
echo "🤖 Iniciando Detector LIBRAS..."
echo "================================"
echo ""

# Ativa ambiente virtual
source ~/libras_detector_env/bin/activate

# Verifica se arquivo principal existe
if [[ ! -f ~/libras_detector/advanced_hand_detection_pi.py ]]; then
    echo "❌ Arquivo principal não encontrado!"
    echo "   Copie advanced_hand_detection_pi.py para ~/libras_detector/"
    exit 1
fi

# Verifica câmera
if [[ ! -e /dev/video0 ]]; then
    echo "⚠️  Aviso: Câmera não detectada em /dev/video0"
    echo "   Verifique se a câmera está conectada"
fi

# Executa detector
cd ~/libras_detector
python3 advanced_hand_detection_pi.py
EOF

chmod +x start_detector.sh

# Cria arquivo de serviço systemd
echo "  ⚙️  Criando serviço systemd..."
cat > libras-detector.service << 'EOF'
[Unit]
Description=Detector LIBRAS para Raspberry Pi
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${HOME}/libras_detector
Environment=PYTHONPATH=${HOME}/libras_detector_env/lib/python3.7/site-packages
ExecStart=${HOME}/libras_detector_env/bin/python ${HOME}/libras_detector/advanced_hand_detection_pi.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Substitui variáveis no arquivo de serviço
sed -i "s|\${USER}|$USER|g" libras-detector.service
sed -i "s|\${HOME}|$HOME|g" libras-detector.service

# Script para instalar serviço
echo "  🔧 Criando instalador de serviço..."
cat > install_service.sh << 'EOF'
#!/bin/bash
echo "📋 Instalando serviço systemd..."
sudo cp libras-detector.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable libras-detector.service
echo "✅ Serviço instalado!"
echo ""
echo "Comandos disponíveis:"
echo "  sudo systemctl start libras-detector    # Iniciar"
echo "  sudo systemctl stop libras-detector     # Parar"
echo "  sudo systemctl status libras-detector   # Status"
echo "  sudo journalctl -u libras-detector -f   # Ver logs"
EOF

chmod +x install_service.sh

# =============================================================================
# 7️⃣ CRIAÇÃO DE SCRIPTS DE TESTE
# =============================================================================
echo ""
echo "🧪 ETAPA 7/8: Criando scripts de teste..."
echo "========================================"

# Script de teste da câmera
echo "  📷 Script de teste da câmera..."
cat > test_camera.py << 'EOF'
#!/usr/bin/env python3
"""
🎥 Teste da Câmera para Detector LIBRAS
Verifica se a câmera está funcionando corretamente
"""
import cv2
import sys
import os

def test_camera():
    print("🎥 TESTE DA CÂMERA")
    print("==================")
    
    # Lista dispositivos de vídeo disponíveis
    video_devices = []
    for i in range(5):  # Testa /dev/video0 até /dev/video4
        if os.path.exists(f'/dev/video{i}'):
            video_devices.append(i)
    
    if not video_devices:
        print("❌ Nenhum dispositivo de vídeo encontrado!")
        print("💡 Dicas:")
        print("   - Verifique se a câmera está conectada")
        print("   - Para câmera Pi: sudo raspi-config → Interface Options → Camera")
        print("   - Para câmera USB: lsusb | grep -i camera")
        return False
    
    print(f"📷 Dispositivos encontrados: {video_devices}")
    
    # Testa cada dispositivo
    for device in video_devices:
        print(f"\n🔍 Testando /dev/video{device}...")
        
        cap = cv2.VideoCapture(device)
        if not cap.isOpened():
            print(f"  ❌ Não foi possível abrir /dev/video{device}")
            continue
        
        # Configura câmera
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_FPS, 15)
        
        # Captura frame de teste
        print("  📸 Capturando frame de teste...")
        ret, frame = cap.read()
        
        if ret and frame is not None:
            height, width = frame.shape[:2]
            print(f"  ✅ Sucesso! Resolução: {width}x{height}")
            
            # Salva imagem de teste
            test_image = f'/tmp/test_camera_video{device}.jpg'
            cv2.imwrite(test_image, frame)
            print(f"  💾 Imagem salva: {test_image}")
            
            cap.release()
            return True
        else:
            print(f"  ❌ Erro na captura do frame")
        
        cap.release()
    
    print("\n❌ Nenhuma câmera funcionando encontrada!")
    return False

if __name__ == "__main__":
    success = test_camera()
    if success:
        print("\n🎉 Câmera pronta para uso!")
    else:
        print("\n🔧 Resolva os problemas da câmera antes de continuar")
    
    sys.exit(0 if success else 1)
EOF

chmod +x test_camera.py

# Script de teste do GPIO
echo "  🔌 Script de teste do GPIO..."
cat > test_gpio.py << 'EOF'
#!/usr/bin/env python3
"""
🔌 Teste do GPIO para Motor Stepper
Testa se o GPIO está configurado corretamente
"""
import RPi.GPIO as GPIO
import time
import sys

def test_gpio():
    print("🔌 TESTE DO GPIO")
    print("================")
    
    try:
        # Configuração GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)
        
        # Pinos do motor stepper
        motor_pins = [18, 19, 20, 21]  # GPIO 18, 19, 20, 21
        
        print(f"⚡ Configurando pinos GPIO: {motor_pins}")
        
        # Configura pinos como saída
        for pin in motor_pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)
        
        print("✅ GPIO configurado com sucesso!")
        
        # Teste visual - pisca cada pino
        print("\n💡 TESTE VISUAL (conecte LEDs para ver):")
        print("   GPIO 18 → LED → GND")
        print("   GPIO 19 → LED → GND") 
        print("   GPIO 20 → LED → GND")
        print("   GPIO 21 → LED → GND")
        print("")
        
        for cycle in range(3):
            print(f"🔄 Ciclo {cycle + 1}/3:")
            for pin in motor_pins:
                print(f"  💡 GPIO {pin} ON")
                GPIO.output(pin, GPIO.HIGH)
                time.sleep(0.5)
                GPIO.output(pin, GPIO.LOW)
                time.sleep(0.1)
        
        # Teste do motor stepper (sequência real)
        print("\n🎛️  TESTE DE SEQUÊNCIA DO MOTOR:")
        print("   (conecte motor stepper 28BYJ-48 + ULN2003)")
        
        step_sequence = [
            [1, 0, 0, 1],  # Step 1
            [1, 1, 0, 0],  # Step 2
            [0, 1, 1, 0],  # Step 3
            [0, 0, 1, 1]   # Step 4
        ]
        
        steps = 50  # 50 passos de teste
        delay = 0.005
        
        print(f"🔄 Executando {steps} passos...")
        
        for step in range(steps):
            for i in range(4):
                for pin_index, pin in enumerate(motor_pins):
                    GPIO.output(pin, step_sequence[i][pin_index])
                time.sleep(delay)
        
        # Desliga todas as bobinas
        for pin in motor_pins:
            GPIO.output(pin, GPIO.LOW)
        
        print("✅ Teste de motor concluído!")
        print("\n🎯 RESULTADO DO TESTE:")
        print("  ✅ GPIO funcionando corretamente")
        print("  ✅ Pinos configurados: 18, 19, 20, 21")
        print("  ✅ Sequência de passos executada")
        
        return True
        
    except Exception as e:
        print(f"❌ ERRO no teste GPIO: {e}")
        print("\n🔧 SOLUÇÕES:")
        print("  1. Execute: sudo usermod -a -G gpio $USER")
        print("  2. Reinicie: sudo reboot") 
        print("  3. Verifique conexões do hardware")
        return False
        
    finally:
        GPIO.cleanup()
        print("🧹 GPIO limpo")

if __name__ == "__main__":
    success = test_gpio()
    if success:
        print("\n🎉 GPIO pronto para uso!")
    else:
        print("\n🔧 Resolva os problemas do GPIO antes de continuar")
    
    sys.exit(0 if success else 1)
EOF

chmod +x test_gpio.py

# Script de diagnóstico do sistema
echo "  🩺 Script de diagnóstico do sistema..."
cat > system_diagnostic.py << 'EOF'
#!/usr/bin/env python3
"""
🩺 Diagnóstico Completo do Sistema
Verifica se tudo está configurado corretamente
"""
import os
import sys
import subprocess
import importlib

def run_command(cmd):
    """Executa comando e retorna resultado"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout.strip()
    except:
        return False, ""

def check_system():
    print("🩺 DIAGNÓSTICO COMPLETO DO SISTEMA")
    print("==================================")
    
    # Sistema operacional
    success, output = run_command("cat /etc/os-release | grep PRETTY_NAME")
    print(f"🖥️  SO: {output.split('=')[1].strip('\"') if success else 'Desconhecido'}")
    
    # Temperatura
    success, temp = run_command("vcgencmd measure_temp")
    print(f"🌡️  Temperatura: {temp.split('=')[1] if success else 'N/A'}")
    
    # Memória
    success, mem = run_command("free -h | grep Mem | awk '{print $3\"/\"$2}'")
    print(f"🧠 Memória: {mem if success else 'N/A'}")
    
    # Python
    print(f"🐍 Python: {sys.version.split()[0]}")
    
    # Bibliotecas importantes
    libraries = ['cv2', 'numpy', 'RPi.GPIO']
    print("\n📚 BIBLIOTECAS:")
    for lib in libraries:
        try:
            importlib.import_module(lib)
            print(f"  ✅ {lib}")
        except ImportError:
            print(f"  ❌ {lib} - não instalado")
    
    # Dispositivos de vídeo
    video_devices = [f"/dev/video{i}" for i in range(5) if os.path.exists(f"/dev/video{i}")]
    print(f"\n📷 Câmeras: {len(video_devices)} encontrada(s)")
    for dev in video_devices:
        print(f"  📹 {dev}")
    
    # GPIO
    gpio_available = os.path.exists("/sys/class/gpio")
    print(f"🔌 GPIO: {'✅ Disponível' if gpio_available else '❌ Indisponível'}")
    
    # Grupos do usuário
    success, groups = run_command("groups")
    user_groups = groups.split() if success else []
    required_groups = ['gpio', 'video', 'dialout']
    print(f"\n👤 GRUPOS DO USUÁRIO:")
    for group in required_groups:
        status = "✅" if group in user_groups else "❌"
        print(f"  {status} {group}")
    
    # Arquivos do projeto
    project_files = [
        '~/libras_detector/advanced_hand_detection_pi.py',
        '~/libras_detector/start_detector.sh',
        '~/libras_detector_env/bin/python'
    ]
    print(f"\n📁 ARQUIVOS DO PROJETO:")
    for file in project_files:
        expanded_path = os.path.expanduser(file)
        exists = os.path.exists(expanded_path)
        status = "✅" if exists else "❌"
        print(f"  {status} {file}")
    
    print("\n" + "="*50)
    print("🎯 RESUMO:")
    all_good = (
        len(video_devices) > 0 and
        gpio_available and
        'gpio' in user_groups and
        'video' in user_groups
    )
    
    if all_good:
        print("🎉 Sistema pronto para uso!")
    else:
        print("⚠️  Sistema precisa de ajustes")
        print("   Execute: ./setup_raspberry_pi.sh")

if __name__ == "__main__":
    check_system()
EOF

chmod +x system_diagnostic.py

# =============================================================================
# 8️⃣ FINALIZAÇÃO E INSTRUÇÕES
# =============================================================================
echo ""
echo "✅ ETAPA 8/8: Finalizando configuração..."
echo "========================================"

# Cria arquivo de informações
cat > INFORMACOES.txt << 'EOF'
🤖 DETECTOR LIBRAS - RASPBERRY PI 3B+
=====================================

📋 ARQUIVOS PRINCIPAIS:
- advanced_hand_detection_pi.py  → Código principal do detector
- start_detector.sh              → Script para iniciar o detector
- libras_manager.sh              → Gerenciador do sistema

🧪 SCRIPTS DE TESTE:
- test_camera.py                 → Testa se a câmera funciona
- test_gpio.py                   → Testa GPIO e motor stepper
- system_diagnostic.py           → Diagnóstico completo

⚙️  SERVIÇOS:
- install_service.sh             → Instala serviço systemd
- libras-detector.service        → Arquivo de serviço

🔌 CONEXÕES DO MOTOR STEPPER:
Driver ULN2003 → Raspberry Pi
IN1 → GPIO 18 (Pin 12)
IN2 → GPIO 19 (Pin 35)
IN3 → GPIO 20 (Pin 38)  
IN4 → GPIO 21 (Pin 40)
VCC → 5V (Pin 2)
GND → GND (Pin 6)

📱 COMANDOS ÚTEIS:
- ./start_detector.sh           → Inicia detector
- python3 test_camera.py        → Testa câmera
- python3 test_gpio.py          → Testa GPIO/motor
- python3 system_diagnostic.py  → Diagnóstico completo

🔧 PRÓXIMOS PASSOS:
1. Copie advanced_hand_detection_pi.py para esta pasta
2. Reinicie o sistema: sudo reboot
3. Execute: ./start_detector.sh
EOF

# Mostra resumo final
echo ""
echo "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "====================================="
echo ""
echo "📂 Localização do projeto: ~/libras_detector"
echo "🐍 Ambiente virtual: ~/libras_detector_env"
echo ""
echo "📋 PRÓXIMOS PASSOS OBRIGATÓRIOS:"
echo "==============================="
echo "1️⃣  Copie o arquivo principal:"
echo "    cp advanced_hand_detection_pi.py ~/libras_detector/"
echo ""
echo "2️⃣  REINICIE o sistema (IMPORTANTE!):"
echo "    sudo reboot"
echo ""
echo "3️⃣  Após reiniciar, teste tudo:"
echo "    cd ~/libras_detector"
echo "    python3 test_camera.py"
echo "    python3 test_gpio.py"
echo "    python3 system_diagnostic.py"
echo ""
echo "4️⃣  Execute o detector:"
echo "    ./start_detector.sh"
echo ""
echo "🔧 CONEXÕES DO HARDWARE:"
echo "========================"
echo "Motor Stepper 28BYJ-48 + ULN2003:"
echo "  GPIO 18 (Pin 12) → IN1"
echo "  GPIO 19 (Pin 35) → IN2"
echo "  GPIO 20 (Pin 38) → IN3"
echo "  GPIO 21 (Pin 40) → IN4"
echo "  5V (Pin 2)       → VCC"
echo "  GND (Pin 6)      → GND"
echo ""
echo "📷 Câmera USB ou Pi Camera conectada"
echo ""
echo "⚠️  IMPORTANTE: O sistema só funcionará após REINICIAR!"
echo ""

deactivate  # Sai do ambiente virtual

