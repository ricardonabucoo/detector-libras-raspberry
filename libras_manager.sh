#!/bin/bash

# 🤖 Gerenciador do Detector LIBRAS - Raspberry Pi 3B+
# Script para facilitar o gerenciamento do sistema

PROJECT_DIR="$HOME/libras_detector"
VENV_DIR="$HOME/libras_detector_env"
SERVICE_NAME="libras-detector"

show_banner() {
    clear
    echo "🤖 ==============================================="
    echo "   DETECTOR LIBRAS - RASPBERRY PI 3B+"
    echo "   Gerenciador do Sistema"
    echo "==============================================="
    echo ""
}

check_installation() {
    if [[ ! -d "$PROJECT_DIR" ]] || [[ ! -d "$VENV_DIR" ]]; then
        echo "❌ Instalação não encontrada!"
        echo "   Execute primeiro: ./setup_raspberry_pi.sh"
        exit 1
    fi
}

show_status() {
    echo "📊 STATUS DO SISTEMA"
    echo "===================="
    
    # Verifica temperatura
    temp=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2)
    echo "🌡️  Temperatura: ${temp:-"N/A"}"
    
    # Verifica memória
    mem_info=$(free -h | grep Mem | awk '{print $3"/"$2}')
    echo "🧠 Memória: $mem_info"
    
    # Verifica câmera
    camera_count=$(ls /dev/video* 2>/dev/null | wc -l)
    echo "📷 Câmera: $camera_count dispositivo(s) detectado(s)"
    
    # Verifica serviço
    if systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        echo "⚙️  Serviço: 🟢 ATIVO"
    else
        echo "⚙️  Serviço: 🔴 INATIVO"
    fi
    
    # Verifica GPIO
    if [[ -d "/sys/class/gpio" ]]; then
        echo "🔌 GPIO: ✅ Disponível"
    else
        echo "🔌 GPIO: ❌ Indisponível"
    fi
    
    echo ""
}

test_camera() {
    echo "📷 TESTANDO CÂMERA..."
    cd "$PROJECT_DIR"
    source "$VENV_DIR/bin/activate"
    
    if python3 test_camera.py; then
        echo "✅ Câmera funcionando corretamente!"
    else
        echo "❌ Problema com a câmera detectado"
        echo "💡 Dicas:"
        echo "   - Verifique se a câmera está conectada"
        echo "   - Execute: sudo raspi-config → Interface Options → Camera → Enable"
        echo "   - Para câmera USB: ls /dev/video*"
    fi
    
    read -p "Pressione Enter para continuar..."
}

test_gpio() {
    echo "🔌 TESTANDO GPIO..."
    cd "$PROJECT_DIR"
    source "$VENV_DIR/bin/activate"
    
    echo "⚠️  Conecte LEDs nos pinos 18,19,20,21 para ver o teste visual"
    python3 test_gpio.py
    
    read -p "Pressione Enter para continuar..."
}

run_detector() {
    echo "🚀 INICIANDO DETECTOR..."
    echo "   Ctrl+C para parar"
    echo ""
    
    cd "$PROJECT_DIR"
    source "$VENV_DIR/bin/activate"
    python3 advanced_hand_detection_pi.py
}

install_service() {
    echo "📋 INSTALANDO SERVIÇO SYSTEMD..."
    
    cd "$PROJECT_DIR"
    
    if [[ -f "libras-detector.service" ]]; then
        sudo cp libras-detector.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        echo "✅ Serviço instalado com sucesso!"
        echo ""
        echo "Comandos disponíveis:"
        echo "   sudo systemctl start $SERVICE_NAME"
        echo "   sudo systemctl stop $SERVICE_NAME"
        echo "   sudo systemctl status $SERVICE_NAME"
        echo "   sudo journalctl -u $SERVICE_NAME -f"
    else
        echo "❌ Arquivo de serviço não encontrado"
        echo "   Execute primeiro a configuração completa"
    fi
    
    read -p "Pressione Enter para continuar..."
}

manage_service() {
    if ! systemctl list-units --full -all | grep -Fq "$SERVICE_NAME.service"; then
        echo "❌ Serviço não está instalado"
        echo "   Use a opção 'Instalar Serviço' primeiro"
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    while true; do
        clear
        echo "⚙️  GERENCIAR SERVIÇO"
        echo "==================="
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo "Status: 🟢 ATIVO"
        else
            echo "Status: 🔴 INATIVO"
        fi
        
        echo ""
        echo "1) ▶️  Iniciar serviço"
        echo "2) ⏹️  Parar serviço"
        echo "3) 🔄 Reiniciar serviço"
        echo "4) 📋 Ver status detalhado"
        echo "5) 📜 Ver logs em tempo real"
        echo "6) 🔙 Voltar"
        echo ""
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                sudo systemctl start $SERVICE_NAME
                echo "✅ Serviço iniciado"
                ;;
            2)
                sudo systemctl stop $SERVICE_NAME
                echo "⏹️  Serviço parado"
                ;;
            3)
                sudo systemctl restart $SERVICE_NAME
                echo "🔄 Serviço reiniciado"
                ;;
            4)
                sudo systemctl status $SERVICE_NAME
                ;;
            5)
                echo "📜 Logs em tempo real (Ctrl+C para sair):"
                sudo journalctl -u $SERVICE_NAME -f
                ;;
            6)
                break
                ;;
            *)
                echo "❌ Opção inválida"
                ;;
        esac
        
        if [[ $choice != 5 ]]; then
            read -p "Pressione Enter para continuar..."
        fi
    done
}

configure_detector() {
    echo "⚙️  CONFIGURAÇÃO DO DETECTOR"
    echo "============================"
    
    cd "$PROJECT_DIR"
    
    echo "Configurações atuais:"
    echo ""
    
    # Mostra configurações atuais
    if [[ -f "advanced_hand_detection_pi.py" ]]; then
        target_word=$(grep "self.target_word" advanced_hand_detection_pi.py | cut -d'"' -f2)
        min_area=$(grep "self.min_area" advanced_hand_detection_pi.py | awk '{print $3}')
        max_area=$(grep "self.max_area" advanced_hand_detection_pi.py | awk '{print $3}')
        
        echo "🎯 Palavra alvo: $target_word"
        echo "📏 Área mínima da mão: $min_area"
        echo "📐 Área máxima da mão: $max_area"
        echo ""
        
        echo "Opções:"
        echo "1) Alterar palavra alvo"
        echo "2) Ajustar sensibilidade da detecção"
        echo "3) Alterar pinos GPIO do motor"
        echo "4) Voltar"
        echo ""
        
        read -p "Escolha uma opção: " config_choice
        
        case $config_choice in
            1)
                read -p "Digite a nova palavra alvo (apenas letras): " new_word
                new_word=$(echo "$new_word" | tr '[:lower:]' '[:upper:]' | tr -cd '[:alpha:]')
                if [[ -n "$new_word" ]]; then
                    sed -i "s/self.target_word = \".*\"/self.target_word = \"$new_word\"/" advanced_hand_detection_pi.py
                    echo "✅ Palavra alvo alterada para: $new_word"
                fi
                ;;
            2)
                echo "Ajustar área de detecção da mão:"
                echo "Valores menores = mais sensível (detecta mãos menores/distantes)"
                echo "Valores maiores = menos sensível (apenas mãos grandes/próximas)"
                echo ""
                read -p "Nova área mínima (atual: $min_area): " new_min
                read -p "Nova área máxima (atual: $max_area): " new_max
                
                if [[ "$new_min" =~ ^[0-9]+$ ]] && [[ "$new_max" =~ ^[0-9]+$ ]]; then
                    sed -i "s/self.min_area = .*/self.min_area = $new_min/" advanced_hand_detection_pi.py
                    sed -i "s/self.max_area = .*/self.max_area = $new_max/" advanced_hand_detection_pi.py
                    echo "✅ Configuração de área alterada"
                fi
                ;;
            3)
                current_pins=$(grep "self.motor_pins = " advanced_hand_detection_pi.py | cut -d'[' -f2 | cut -d']' -f1)
                echo "Pinos GPIO atuais: [$current_pins]"
                echo "Digite 4 números de pinos GPIO separados por espaço (ex: 17 18 27 22):"
                read -p "Novos pinos: " new_pins
                
                if [[ "$new_pins" =~ ^[0-9\ ]+$ ]]; then
                    formatted_pins=$(echo "$new_pins" | tr ' ' ', ')
                    sed -i "s/self.motor_pins = \[.*\]/self.motor_pins = [$formatted_pins]/" advanced_hand_detection_pi.py
                    echo "✅ Pinos GPIO alterados para: [$formatted_pins]"
                fi
                ;;
        esac
    else
        echo "❌ Arquivo principal não encontrado"
    fi
    
    read -p "Pressione Enter para continuar..."
}

backup_system() {
    echo "💾 BACKUP DO SISTEMA"
    echo "===================="
    
    backup_name="libras_detector_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    echo "Criando backup: $backup_name"
    tar -czf "/tmp/$backup_name" "$PROJECT_DIR" "$VENV_DIR" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Backup criado em: /tmp/$backup_name"
        echo "💡 Para restaurar: tar -xzf /tmp/$backup_name -C ~/"
    else
        echo "❌ Erro ao criar backup"
    fi
    
    read -p "Pressione Enter para continuar..."
}

view_logs() {
    echo "📜 LOGS DO SISTEMA"
    echo "=================="
    echo ""
    echo "1) Logs do serviço systemd"
    echo "2) Logs de detecção (se existir)"
    echo "3) Logs do sistema (dmesg)"
    echo "4) Voltar"
    echo ""
    
    read -p "Escolha uma opção: " log_choice
    
    case $log_choice in
        1)
            if systemctl list-units --full -all | grep -Fq "$SERVICE_NAME.service"; then
                echo "📜 Logs do serviço (Ctrl+C para sair):"
                sudo journalctl -u $SERVICE_NAME -f
            else
                echo "❌ Serviço não instalado"
            fi
            ;;
        2)
            if [[ -f "$PROJECT_DIR/detector.log" ]]; then
                echo "📜 Últimas 50 linhas do log de detecção:"
                tail -50 "$PROJECT_DIR/detector.log"
            else
                echo "❌ Log de detecção não encontrado"
            fi
            read -p "Pressione Enter para continuar..."
            ;;
        3)
            echo "📜 Logs do sistema (últimas 50 linhas):"
            dmesg | tail -50
            read -p "Pressione Enter para continuar..."
            ;;
        4)
            return
            ;;
    esac
}

main_menu() {
    while true; do
        show_banner
        check_installation
        show_status
        
        echo "MENU PRINCIPAL"
        echo "=============="
        echo "1) 🚀 Executar Detector"
        echo "2) 📷 Testar Câmera"
        echo "3) 🔌 Testar GPIO/Motor"
        echo "4) 📋 Instalar Serviço"
        echo "5) ⚙️  Gerenciar Serviço"
        echo "6) 🔧 Configurar Detector"
        echo "7) 📜 Ver Logs"
        echo "8) 💾 Backup do Sistema"
        echo "9) ❌ Sair"
        echo ""
        
        read -p "Escolha uma opção (1-9): " choice
        
        case $choice in
            1) run_detector ;;
            2) test_camera ;;
            3) test_gpio ;;
            4) install_service ;;
            5) manage_service ;;
            6) configure_detector ;;
            7) view_logs ;;
            8) backup_system ;;
            9) 
                echo "👋 Até logo!"
                exit 0
                ;;
            *)
                echo "❌ Opção inválida. Pressione Enter para tentar novamente."
                read
                ;;
        esac
    done
}

# Verifica se está sendo executado como root
if [[ $EUID -eq 0 ]]; then
    echo "❌ Não execute este script como root (sudo)"
    echo "   Execute como usuário normal: ./libras_manager.sh"
    exit 1
fi

# Inicia o menu principal
main_menu
