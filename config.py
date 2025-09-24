# -*- coding: utf-8 -*-
"""
Configuração Avançada do Detector LIBRAS para Raspberry Pi 3B+
==============================================================

Este arquivo contém todas as configurações personalizáveis do sistema.
Modifique os valores conforme necessário para seu hardware específico.

Autor: Sistema de Detecção LIBRAS
Data: 2024
"""

import os

# ========================================
# CONFIGURAÇÕES DE HARDWARE
# ========================================

class HardwareConfig:
    """Configurações de hardware"""
    
    # Pinos GPIO para motor stepper (modo BCM)
    # Ajuste conforme suas conexões físicas
    MOTOR_PINS = [18, 19, 20, 21]  # [IN1, IN2, IN3, IN4]
    
    # Configurações do motor
    MOTOR_STEPS_PER_REVOLUTION = 2048  # Para motor 28BYJ-48 com redução
    MOTOR_DEFAULT_STEPS = 1000         # Passos padrão ao ativar
    MOTOR_STEP_DELAY = 0.003          # Delay entre passos (segundos)
    MOTOR_DIRECTION = 1               # 1=horário, -1=anti-horário
    
    # Configuração da câmera
    CAMERA_INDEX = 0                  # Índice da câmera (0=primeira câmera)
    CAMERA_WIDTH = 640                # Largura do frame
    CAMERA_HEIGHT = 480               # Altura do frame  
    CAMERA_FPS = 20                   # Frames por segundo
    
    # ROI (Region of Interest) - área de detecção na tela
    ROI_X = 200                       # Posição X do ROI
    ROI_Y = 60                        # Posição Y do ROI
    ROI_WIDTH = 300                   # Largura do ROI
    ROI_HEIGHT = 300                  # Altura do ROI


# ========================================
# CONFIGURAÇÕES DE DETECÇÃO
# ========================================

class DetectionConfig:
    """Configurações de detecção de gestos"""
    
    # Área mínima e máxima para considerar como mão
    MIN_HAND_AREA = 8000              # Pixels² mínimos
    MAX_HAND_AREA = 50000             # Pixels² máximos
    
    # Parâmetros para detecção de pele (HSV)
    HSV_LOWER = [0, 20, 70]           # Valor mínimo HSV
    HSV_UPPER = [25, 255, 255]        # Valor máximo HSV
    
    # Parâmetros para detecção de pele (YCrCb)
    YCRCB_LOWER = [0, 133, 77]        # Valor mínimo YCrCb
    YCRCB_UPPER = [255, 173, 127]     # Valor máximo YCrCb
    
    # Parâmetros de morfologia
    MORPH_KERNEL_SIZE = (5, 5)        # Tamanho do kernel morfológico
    GAUSSIAN_BLUR_SIZE = (3, 3)       # Tamanho do blur gaussiano
    
    # Detecção de dedos
    MIN_DEFECT_DEPTH = 6000           # Profundidade mínima para defeito
    MIN_FINGER_ANGLE = 30             # Ângulo mínimo entre dedos (graus)
    MAX_FINGER_ANGLE = 120            # Ângulo máximo entre dedos (graus)
    MAX_FINGERS = 5                   # Número máximo de dedos detectáveis


# ========================================
# CONFIGURAÇÕES DE ESTABILIZAÇÃO
# ========================================

class StabilizationConfig:
    """Configurações para estabilização de gestos"""
    
    # Buffer de gestos
    GESTURE_BUFFER_SIZE = 20          # Tamanho do buffer de gestos
    LETTER_HISTORY_SIZE = 10          # Histórico de letras detectadas
    
    # Estabilização
    STABILITY_FRAMES = 10             # Frames para confirmar gesto estável
    CONFIDENCE_THRESHOLD = 0.7        # Confiança mínima (0.0 a 1.0)
    
    # Cooldown
    ACTIVATION_COOLDOWN = 5           # Segundos entre ativações do motor
    GESTURE_CHANGE_DELAY = 1          # Delay mínimo entre mudanças de gesto


# ========================================
# CONFIGURAÇÕES DE CLASSIFICAÇÃO
# ========================================

class ClassificationConfig:
    """Parâmetros para classificação de letras LIBRAS"""
    
    # Limites para classificação da letra A (punho fechado)
    A_MAX_FINGERS = 1
    A_MIN_SOLIDITY = 0.85
    A_MAX_COMPACTNESS = 8
    
    # Limites para classificação da letra B (mão aberta)
    B_MIN_FINGERS = 4
    B_MIN_SOLIDITY = 0.9
    B_MAX_ASPECT_RATIO = 1.3
    
    # Limites para classificação da letra C (formato C)
    C_MIN_FINGERS = 1
    C_MAX_FINGERS = 2
    C_MIN_SOLIDITY = 0.6
    C_MAX_SOLIDITY = 0.8
    C_MIN_COMPACTNESS = 12
    
    # Limites para classificação da letra D (indicador)
    D_FINGERS = 1
    D_MIN_ASPECT_RATIO = 1.5
    D_MAX_EXTENT = 0.6
    
    # Limites para classificação da letra E (punho)
    E_FINGERS = 0
    E_MIN_SOLIDITY = 0.9
    E_MAX_COMPACTNESS = 6
    
    # Limites para classificação da letra F (três dedos)
    F_FINGERS = 3
    F_MIN_SOLIDITY = 0.75
    
    # Limites para classificação da letra G (indicador + polegar)
    G_FINGERS = 2
    G_MIN_ASPECT_RATIO = 1.2
    
    # Limites para classificação da letra I (mindinho)
    I_FINGERS = 1
    I_MAX_ASPECT_RATIO = 1.2
    I_MIN_EXTENT = 0.6
    
    # Limites para classificação da letra L (L shape)
    L_FINGERS = 2
    L_MIN_ASPECT_RATIO = 1.4
    L_MIN_COMPACTNESS = 15
    
    # Limites para classificação da letra O (circular)
    O_MAX_FINGERS = 2
    O_MIN_SOLIDITY = 0.7
    O_MAX_SOLIDITY = 0.85
    O_MIN_COMPACTNESS = 8
    O_MAX_COMPACTNESS = 15
    
    # Limites para classificação da letra U (dois dedos juntos)
    U_FINGERS = 2
    U_MAX_ASPECT_RATIO = 1.3
    U_MIN_SOLIDITY = 0.8
    
    # Limites para classificação da letra V (vitória)
    V_FINGERS = 2
    V_MIN_DEFECTS = 1
    V_MAX_SOLIDITY = 0.8


# ========================================
# CONFIGURAÇÕES DE INTERFACE
# ========================================

class InterfaceConfig:
    """Configurações da interface gráfica"""
    
    # Cores (BGR)
    COLOR_GOOD_DETECTION = (0, 255, 0)      # Verde
    COLOR_BAD_DETECTION = (0, 0, 255)       # Vermelho
    COLOR_ROI_RECTANGLE = (255, 0, 0)       # Azul
    COLOR_TEXT_PRIMARY = (255, 255, 255)    # Branco
    COLOR_TEXT_SECONDARY = (0, 255, 255)    # Amarelo ciano
    COLOR_MOTOR_ACTIVE = (0, 255, 0)        # Verde
    COLOR_MOTOR_INACTIVE = (0, 0, 255)      # Vermelho
    
    # Fontes e tamanhos
    FONT_MAIN = cv2.FONT_HERSHEY_SIMPLEX if 'cv2' in globals() else None
    FONT_SIZE_LARGE = 1.0
    FONT_SIZE_MEDIUM = 0.7
    FONT_SIZE_SMALL = 0.5
    FONT_THICKNESS_BOLD = 3
    FONT_THICKNESS_NORMAL = 2
    FONT_THICKNESS_THIN = 1
    
    # Janelas
    MAIN_WINDOW_NAME = "Detector LIBRAS - Raspberry Pi 3B+"
    MASK_WINDOW_NAME = "Mascara de Detecao"
    MASK_WINDOW_SIZE = (200, 200)
    
    # Interface
    SHOW_DEBUG_INFO = True                   # Mostra informações de debug
    SHOW_MASK_WINDOW = True                  # Mostra janela da máscara
    SHOW_FPS = True                          # Mostra FPS na tela
    SHOW_GESTURE_HISTORY = True              # Mostra histórico de gestos


# ========================================
# CONFIGURAÇÕES DE PALAVRAS E COMANDOS
# ========================================

class WordConfig:
    """Configurações de palavras-chave e comandos"""
    
    # Palavra padrão que ativa o motor
    DEFAULT_TARGET_WORD = "UAU"
    
    # Lista de palavras pré-definidas (para mudança rápida)
    PREDEFINED_WORDS = [
        "UAU",      # Palavra padrão
        "OLA",      # Olá
        "LEGAL",    # Legal  
        "BOM",      # Bom
        "COOL",     # Cool
        "OK",       # OK
        "SIM",      # Sim
        "NAO",      # Não
        "HELP",     # Ajuda
        "GO"        # Vai
    ]
    
    # Comandos especiais do motor
    MOTOR_COMMANDS = {
        "ATIVAR": {"steps": 1000, "delay": 0.003, "direction": 1},
        "RAPIDO": {"steps": 500, "delay": 0.001, "direction": 1},
        "LENTO": {"steps": 2000, "delay": 0.01, "direction": 1},
        "REVERSO": {"steps": 1000, "delay": 0.003, "direction": -1}
    }


# ========================================
# CONFIGURAÇÕES DE SISTEMA
# ========================================

class SystemConfig:
    """Configurações gerais do sistema"""
    
    # Paths e arquivos
    PROJECT_DIR = os.path.expanduser("~/libras_detector")
    LOG_FILE = os.path.join(PROJECT_DIR, "detector.log")
    CONFIG_FILE = os.path.join(PROJECT_DIR, "user_config.json")
    
    # Logging
    ENABLE_LOGGING = True
    LOG_LEVEL = "INFO"  # DEBUG, INFO, WARNING, ERROR
    MAX_LOG_SIZE = 10 * 1024 * 1024  # 10MB
    LOG_BACKUP_COUNT = 3
    
    # Performance
    MAX_FPS_LIMIT = 30                       # FPS máximo
    CPU_USAGE_THRESHOLD = 80                 # % CPU para alertas
    MEMORY_USAGE_THRESHOLD = 80              # % Memória para alertas
    
    # Sistema
    ENABLE_GPIO_WARNINGS = False             # Avisos GPIO
    AUTO_CLEANUP_ON_EXIT = True              # Limpeza automática
    SAVE_CONFIG_ON_CHANGE = True             # Salva config ao modificar


# ========================================
# CONFIGURAÇÕES DE CALIBRAÇÃO
# ========================================

class CalibrationConfig:
    """Configurações para calibração automática"""
    
    # Calibração de pele
    AUTO_CALIBRATE_SKIN = False              # Calibração automática
    CALIBRATION_SAMPLES = 100                # Amostras para calibração
    CALIBRATION_TOLERANCE = 10               # Tolerância na calibração
    
    # Calibração de área da mão
    AUTO_ADJUST_AREA = True                  # Ajuste automático de área
    AREA_LEARNING_RATE = 0.1                 # Taxa de aprendizado
    
    # Calibração de ROI
    AUTO_ADJUST_ROI = False                  # ROI automático
    ROI_MARGIN = 50                          # Margem do ROI automático


# ========================================
# CONFIGURAÇÕES AVANÇADAS
# ========================================

class AdvancedConfig:
    """Configurações avançadas para usuários experientes"""
    
    # Algoritmos alternativos
    USE_ALTERNATIVE_SKIN_DETECTION = False   # Algoritmo alternativo
    USE_MACHINE_LEARNING_CLASSIFICATION = False  # ML para classificação
    
    # Otimizações de performance
    USE_MULTITHREADING = True                # Multi-threading
    THREAD_POOL_SIZE = 2                     # Tamanho do pool de threads
    FRAME_SKIP_RATIO = 0                     # Pular frames (0=sem pular)
    
    # Filtros avançados
    USE_KALMAN_FILTER = False                # Filtro de Kalman
    USE_TEMPORAL_SMOOTHING = True            # Suavização temporal
    TEMPORAL_WINDOW_SIZE = 5                 # Janela temporal
    
    # Debugging
    SAVE_DEBUG_FRAMES = False                # Salva frames para debug
    DEBUG_FRAME_INTERVAL = 30                # Intervalo para salvar
    DEBUG_OUTPUT_DIR = os.path.join(PROJECT_DIR, "debug_frames")


# ========================================
# CONFIGURAÇÕES DE REDE (FUTURO)
# ========================================

class NetworkConfig:
    """Configurações de rede para expansões futuras"""
    
    # API REST (para controle remoto)
    ENABLE_REST_API = False
    API_HOST = "0.0.0.0"
    API_PORT = 8080
    
    # WebSocket (para streaming)
    ENABLE_WEBSOCKET = False
    WS_PORT = 8081
    
    # MQTT (para IoT)
    ENABLE_MQTT = False
    MQTT_BROKER = "localhost"
    MQTT_PORT = 1883
    MQTT_TOPIC_BASE = "libras_detector"


# ========================================
# CLASSE PRINCIPAL DE CONFIGURAÇÃO
# ========================================

class Config:
    """Classe principal que unifica todas as configurações"""
    
    def __init__(self):
        self.hardware = HardwareConfig()
        self.detection = DetectionConfig()
        self.stabilization = StabilizationConfig()
        self.classification = ClassificationConfig()
        self.interface = InterfaceConfig()
        self.words = WordConfig()
        self.system = SystemConfig()
        self.calibration = CalibrationConfig()
        self.advanced = AdvancedConfig()
        self.network = NetworkConfig()
    
    def load_from_file(self, config_path=None):
        """Carrega configurações de arquivo JSON"""
        import json
        
        if config_path is None:
            config_path = self.system.CONFIG_FILE
        
        try:
            if os.path.exists(config_path):
                with open(config_path, 'r', encoding='utf-8') as f:
                    user_config = json.load(f)
                    self._apply_user_config(user_config)
                    print(f" Configurações carregadas de: {config_path}")
            else:
                print(f" Arquivo de configuração não encontrado: {config_path}")
                print(" Usando configurações padrão")
        except Exception as e:
            print(f" Erro ao carregar configurações: {e}")
            print(" Usando configurações padrão")
    
    def save_to_file(self, config_path=None):
        """Salva configurações atuais em arquivo JSON"""
        import json
        
        if config_path is None:
            config_path = self.system.CONFIG_FILE
        
        try:
            # Cria diretório se não existir
            os.makedirs(os.path.dirname(config_path), exist_ok=True)
            
            # Converte configurações para dicionário
            config_dict = self._to_dict()
            
            with open(config_path, 'w', encoding='utf-8') as f:
                json.dump(config_dict, f, indent=2, ensure_ascii=False)
                
            print(f"✅ Configurações salvas em: {config_path}")
        except Exception as e:
            print(f"❌ Erro ao salvar configurações: {e}")
    
    def _apply_user_config(self, user_config):
        """Aplica configurações do usuário"""
        for section, values in user_config.items():
            if hasattr(self, section):
                section_obj = getattr(self, section)
                for key, value in values.items():
                    if hasattr(section_obj, key):
                        setattr(section_obj, key, value)
    
    def _to_dict(self):
        """Converte configurações para dicionário"""
        config_dict = {}
        
        for attr_name in dir(self):
            attr = getattr(self, attr_name)
            if not attr_name.startswith('_') and hasattr(attr, '__dict__'):
                section_dict = {}
                for key, value in attr.__dict__.items():
                    if not key.startswith('_') and not callable(value):
                        section_dict[key] = value
                config_dict[attr_name] = section_dict
        
        return config_dict
    
    def print_current_config(self):
        """Imprime configuração atual"""
        print("=" * 50)
        print("CONFIGURAÇÃO ATUAL DO SISTEMA")
        print("=" * 50)
        
        sections = [
            ("Hardware", self.hardware),
            ("Detecção", self.detection),
            ("Estabilização", self.stabilization),
            ("Interface", self.interface),
            ("Palavras", self.words),
            ("Sistema", self.system)
        ]
        
        for section_name, section_obj in sections:
            print(f"\n {section_name.upper()}:")
            for key, value in section_obj.__dict__.items():
                if not key.startswith('_'):
                    print(f"   {key}: {value}")
        
        print("=" * 50)
    
    def reset_to_defaults(self):
        """Restaura configurações padrão"""
        self.__init__()
        print(" Configurações restauradas para os valores padrão")
    
    def validate_config(self):
        """Valida se as configurações estão corretas"""
        errors = []
        warnings = []
        
        # Validação de hardware
        if not all(isinstance(pin, int) and 0 <= pin <= 27 for pin in self.hardware.MOTOR_PINS):
            errors.append("Pinos GPIO do motor devem ser números entre 0 e 27")
        
        if len(set(self.hardware.MOTOR_PINS)) != len(self.hardware.MOTOR_PINS):
            errors.append("Pinos GPIO do motor não podem ser duplicados")
        
        # Validação de câmera
        if self.hardware.CAMERA_WIDTH <= 0 or self.hardware.CAMERA_HEIGHT <= 0:
            errors.append("Resolução da câmera deve ser maior que 0")
        
        if self.hardware.CAMERA_FPS <= 0:
            errors.append("FPS da câmera deve ser maior que 0")
        
        # Validação de detecção
        if self.detection.MIN_HAND_AREA >= self.detection.MAX_HAND_AREA:
            errors.append("Área mínima da mão deve ser menor que a máxima")
        
        # Validação de estabilização
        if not 0 <= self.stabilization.CONFIDENCE_THRESHOLD <= 1:
            errors.append("Threshold de confiança deve estar entre 0 e 1")
        
        # Warnings para performance
        if self.hardware.CAMERA_WIDTH * self.hardware.CAMERA_HEIGHT > 640 * 480:
            warnings.append("Resolução alta pode impactar performance na RPi 3B+")
        
        if self.hardware.CAMERA_FPS > 25:
            warnings.append("FPS alto pode impactar performance na RPi 3B+")
        
        # Resultados
        if errors:
            print(" ERROS DE CONFIGURAÇÃO:")
            for error in errors:
                print(f"   • {error}")
        
        if warnings:
            print(" AVISOS DE CONFIGURAÇÃO:")
            for warning in warnings:
                print(f"   • {warning}")
        
        if not errors and not warnings:
            print(" Configuração validada com sucesso!")
        
        return len(errors) == 0


# ========================================
# INSTÂNCIA GLOBAL DE CONFIGURAÇÃO
# ========================================

# Cria instância global das configurações
config = Config()

# Função de conveniência para carregar configurações
def load_config(config_path=None):
    """Carrega configurações do arquivo"""
    config.load_from_file(config_path)
    return config

# Função de conveniência para salvar configurações  
def save_config(config_path=None):
    """Salva configurações no arquivo"""
    config.save_to_file(config_path)

# Função para imprimir configurações
def print_config():
    """Imprime configuração atual"""
    config.print_current_config()

# Função para validar configurações
def validate_config():
    """Valida configurações"""
    return config.validate_config()


# ========================================
# EXEMPLO DE USO
# ========================================

if __name__ == "__main__":
    # Exemplo de como usar as configurações
    print("🔧 Testando sistema de configuração...")
    
    # Carrega configurações
    cfg = load_config()
    
    # Valida configurações
    is_valid = validate_config()
    
    # Imprime configurações atuais
    print_config()
    
    # Modifica uma configuração
    cfg.words.DEFAULT_TARGET_WORD = "TESTE"
    print(f"✏️ Palavra alvo alterada para: {cfg.words.DEFAULT_TARGET_WORD}")
    
    # Salva configurações
    save_config()
    
    print("✅ Teste de configuração concluído!")