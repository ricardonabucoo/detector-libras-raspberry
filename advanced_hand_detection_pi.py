import cv2
import time
import numpy as np
from collections import deque
import RPi.GPIO as GPIO
import threading
import sys
import os

class LibrasDetectorPi:
    def __init__(self):
        # Configuração GPIO para motor stepper
        self.setup_gpio()
        
        # Parâmetros de detecção
        self.min_area = 8000
        self.max_area = 50000
        
        # Sistema de reconhecimento de sequências
        self.detected_letters = deque(maxlen=10)
        self.target_word = "UAU"
        self.last_gesture = ""
        self.gesture_count = 0
        self.stability_threshold = 15
        
        # Buffer para estabilização
        self.gesture_buffer = deque(maxlen=20)
        
        # Estado do sistema
        self.motor_activated = False
        self.last_activation_time = 0
        self.activation_cooldown = 5
        
        # Configuração para terminal
        self.headless_mode = self.check_display()
        
        print("=== DETECTOR LIBRAS RASPBERRY PI ===")
        print(f"✓ Palavra alvo: '{self.target_word}'")
        print(f"✓ Modo: {'Terminal' if self.headless_mode else 'Interface Gráfica'}")
        print("✓ GPIO configurado para motor stepper")
        
    def setup_gpio(self):
        """Configura pinos GPIO para motor stepper"""
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            
            # Pinos do motor stepper (use os pinos que você conectou)
            self.motor_pins = [18, 19, 20, 21]  # GPIO 18, 19, 20, 21
            
            for pin in self.motor_pins:
                GPIO.setup(pin, GPIO.OUT)
                GPIO.output(pin, False)
            
            print("✓ GPIO configurado com sucesso!")
            
        except Exception as e:
            print(f"✗ Erro na configuração GPIO: {e}")
            print("Executando em modo simulação")
            self.motor_pins = None
    
    def check_display(self):
        """Verifica se há display disponível"""
        return os.environ.get('DISPLAY') is None or not os.path.exists('/tmp/.X11-unix')
    
    def motor_off(self):
        """Desliga todas as bobinas do motor"""
        if self.motor_pins:
            for pin in self.motor_pins:
                GPIO.output(pin, False)
    
    def motor_step_sequence(self, steps=500, delay=0.002):
        """Executa sequência de passos do motor stepper"""
        if not self.motor_pins:
            print("🔄 Motor simulado: {} passos executados".format(steps))
            return
            
        # Sequência de passos para motor stepper 28BYJ-48
        step_sequence = [
            [1, 0, 0, 1],
            [1, 1, 0, 0],
            [0, 1, 1, 0],
            [0, 0, 1, 1]
        ]
        
        try:
            print(f"🔄 Executando {steps} passos do motor...")
            
            for step in range(steps):
                for i in range(4):
                    for pin_index, pin in enumerate(self.motor_pins):
                        GPIO.output(pin, step_sequence[i][pin_index])
                    time.sleep(delay)
            
            self.motor_off()
            print("✓ Motor executado com sucesso!")
            
        except Exception as e:
            print(f"✗ Erro no motor: {e}")
            self.motor_off()
    
    def create_skin_mask(self, frame):
        """Cria máscara de pele usando múltiplos espaços de cor"""
        # Converte para HSV e YCrCb
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        ycrcb = cv2.cvtColor(frame, cv2.COLOR_BGR2YCrCb)
        
        # Máscaras HSV
        lower_hsv = np.array([0, 20, 70], dtype=np.uint8)
        upper_hsv = np.array([25, 255, 255], dtype=np.uint8)
        mask_hsv = cv2.inRange(hsv, lower_hsv, upper_hsv)
        
        # Máscaras YCrCb
        lower_ycrcb = np.array([0, 133, 77], dtype=np.uint8)
        upper_ycrcb = np.array([255, 173, 127], dtype=np.uint8)
        mask_ycrcb = cv2.inRange(ycrcb, lower_ycrcb, upper_ycrcb)
        
        # Combina máscaras
        mask = cv2.bitwise_or(mask_hsv, mask_ycrcb)
        
        # Morfologia
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
        mask = cv2.GaussianBlur(mask, (3, 3), 0)
        
        return mask
    
    def analyze_hand_geometry(self, contour):
        """Analisa geometria da mão para classificação LIBRAS"""
        try:
            # Momentos e centro
            M = cv2.moments(contour)
            if M["m00"] == 0:
                return {}
            
            cx = int(M["m10"] / M["m00"])
            cy = int(M["m01"] / M["m00"])
            
            # Características geométricas
            area = cv2.contourArea(contour)
            perimeter = cv2.arcLength(contour, True)
            
            if perimeter == 0:
                return {}
            
            # Bounding rectangle
            x, y, w, h = cv2.boundingRect(contour)
            aspect_ratio = w / h if h > 0 else 0
            
            # Hull convexo
            hull = cv2.convexHull(contour)
            hull_area = cv2.contourArea(hull)
            solidity = area / hull_area if hull_area > 0 else 0
            
            # Compacidade
            compactness = (perimeter * perimeter) / (4 * np.pi * area)
            
            # Defeitos de convexidade
            hull_indices = cv2.convexHull(contour, returnPoints=False)
            if len(hull_indices) > 3:
                defects = cv2.convexityDefects(contour, hull_indices)
                defect_count = len(defects) if defects is not None else 0
            else:
                defect_count = 0
            
            # Extent
            extent = area / (w * h) if (w * h) > 0 else 0
            
            return {
                'center': (cx, cy),
                'area': area,
                'perimeter': perimeter,
                'aspect_ratio': aspect_ratio,
                'solidity': solidity,
                'compactness': compactness,
                'defect_count': defect_count,
                'extent': extent,
                'width': w,
                'height': h
            }
            
        except Exception as e:
            print(f"Erro na análise geométrica: {e}")
            return {}
    
    def count_extended_fingers(self, contour):
        """Conta dedos estendidos usando análise de convexidade"""
        try:
            hull_indices = cv2.convexHull(contour, returnPoints=False)
            if len(hull_indices) < 4:
                return 0
                
            defects = cv2.convexityDefects(contour, hull_indices)
            if defects is None:
                return 0
            
            # Centro da mão
            M = cv2.moments(contour)
            if M["m00"] == 0:
                return 0
            cx = int(M["m10"] / M["m00"])
            cy = int(M["m01"] / M["m00"])
            
            valid_fingers = 0
            
            for i in range(defects.shape[0]):
                s, e, f, d = defects[i, 0]
                start = tuple(contour[s][0])
                end = tuple(contour[e][0])
                far = tuple(contour[f][0])
                
                if d > 6000:
                    a = np.sqrt((end[0] - start[0])**2 + (end[1] - start[1])**2)
                    b = np.sqrt((far[0] - start[0])**2 + (far[1] - start[1])**2)
                    c = np.sqrt((end[0] - far[0])**2 + (end[1] - far[1])**2)
                    
                    if a > 0 and b > 0 and c > 0:
                        angle = np.arccos((b**2 + c**2 - a**2) / (2*b*c))
                        angle_deg = np.degrees(angle)
                        
                        if 30 < angle_deg < 120:
                            valid_fingers += 1
            
            return min(valid_fingers + 1, 5)
            
        except Exception as e:
            return 0
    
    def classify_libras_letter(self, geometry, finger_count):
        """Classifica letra LIBRAS baseada na geometria e dedos"""
        if not geometry:
            return "INDEFINIDO"
        
        area = geometry.get('area', 0)
        aspect_ratio = geometry.get('aspect_ratio', 0)
        solidity = geometry.get('solidity', 0)
        compactness = geometry.get('compactness', 0)
        extent = geometry.get('extent', 0)
        defect_count = geometry.get('defect_count', 0)
        
        # Classificação baseada em características específicas de LIBRAS
        if finger_count <= 1 and solidity > 0.85 and compactness < 8:
            return "A"
        if finger_count >= 4 and solidity > 0.9 and aspect_ratio < 1.3:
            return "B"
        if 1 <= finger_count <= 2 and 0.6 < solidity < 0.8 and compactness > 12:
            return "C"
        if finger_count == 1 and aspect_ratio > 1.5 and extent < 0.6:
            return "D"
        if finger_count == 0 and solidity > 0.9 and compactness < 6:
            return "E"
        if finger_count == 3 and solidity > 0.75:
            return "F"
        if finger_count == 2 and aspect_ratio > 1.2:
            return "G"
        if finger_count == 1 and aspect_ratio < 1.2 and extent > 0.6:
            return "I"
        if finger_count == 2 and aspect_ratio > 1.4 and compactness > 15:
            return "L"
        if finger_count <= 2 and 0.7 < solidity < 0.85 and 8 < compactness < 15:
            return "O"
        if finger_count == 2 and aspect_ratio < 1.3 and solidity > 0.8:
            return "U"
        if finger_count == 2 and defect_count >= 1 and solidity < 0.8:
            return "V"
        
        finger_letters = {0: "E", 1: "D", 2: "V", 3: "F", 4: "B", 5: "ABERTA"}
        return finger_letters.get(finger_count, "INDEFINIDO")
    
    def update_letter_sequence(self, letter):
        """Atualiza sequência de letras detectadas"""
        if letter != "INDEFINIDO" and (not self.detected_letters or letter != self.detected_letters[-1]):
            self.detected_letters.append(letter)
            print(f"📝 Letra detectada: {letter}")
            print(f"📋 Sequência atual: {' '.join(list(self.detected_letters))}")
            
            self.check_target_word()
    
    def check_target_word(self):
        """Verifica se a sequência forma a palavra alvo"""
        if len(self.detected_letters) >= len(self.target_word):
            recent_letters = ''.join(list(self.detected_letters)[-len(self.target_word):])
            
            if recent_letters == self.target_word:
                current_time = time.time()
                if current_time - self.last_activation_time > self.activation_cooldown:
                    self.activate_motor()
                    self.last_activation_time = current_time
                    self.detected_letters.clear()
    
    def activate_motor(self):
        """Ativa o motor stepper"""
        print(f"🎯 PALAVRA '{self.target_word}' DETECTADA! ATIVANDO MOTOR!")
        self.motor_activated = True
        
        # Executa motor em thread separada
        motor_thread = threading.Thread(target=self.motor_step_sequence, args=(500, 0.002))
        motor_thread.start()
        
        # Reset status após 3 segundos
        def reset_motor_status():
            time.sleep(3)
            self.motor_activated = False
        
        reset_thread = threading.Thread(target=reset_motor_status)
        reset_thread.start()
    
    def print_status(self, current_gesture, finger_count, geometry):
        """Imprime status no terminal"""
        os.system('clear')  # Limpa terminal
        
        print("=" * 60)
        print("🤖 DETECTOR LIBRAS - RASPBERRY PI 3B+")
        print("=" * 60)
        print(f"🎯 Palavra alvo: {self.target_word}")
        print(f"📝 Letra atual: {current_gesture}")
        print(f"🖐️  Dedos detectados: {finger_count}")
        
        if geometry:
            print(f"📊 Solidity: {geometry.get('solidity', 0):.2f}")
            print(f"📐 Aspect Ratio: {geometry.get('aspect_ratio', 0):.2f}")
            print(f"🔄 Compactness: {geometry.get('compactness', 0):.1f}")
        
        print("-" * 60)
        sequence_text = ' '.join(list(self.detected_letters)) if self.detected_letters else "Nenhuma"
        print(f"📋 Sequência: {sequence_text}")
        
        motor_status = "🟢 ATIVO" if self.motor_activated else "🔴 INATIVO"
        print(f"⚙️  Motor: {motor_status}")
        
        print("-" * 60)
        print("Controles: Ctrl+C para sair, 'r' + Enter para reset")
        print("=" * 60)
    
    def run(self):
        """Loop principal do detector"""
        cap = cv2.VideoCapture(0)
        
        # Configurações da câmera
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)  # Menor resolução para Pi
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_FPS, 15)  # FPS menor para melhor performance
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Buffer menor
        
        if not cap.isOpened():
            print("❌ Erro: Não foi possível abrir a câmera")
            return
        
        print("🚀 DETECTOR DE LIBRAS ATIVO")
        print(f"🎯 Palavra alvo: '{self.target_word}'")
        print("🔤 Letras suportadas: A, B, C, D, E, F, G, I, L, O, U, V")
        print("📋 Forme a palavra para ativar o motor")
        print("-" * 60)
        
        # ROI para detecção
        roi_x, roi_y, roi_w, roi_h = 200, 100, 300, 300
        
        frame_count = 0
        
        try:
            while True:
                ret, frame = cap.read()
                if not ret:
                    print("⚠️ Falha na captura do frame")
                    continue
                
                frame = cv2.flip(frame, 1)
                frame_count += 1
                
                # Processa a cada 3 frames para melhor performance
                if frame_count % 3 != 0:
                    continue
                
                # ROI
                roi = frame[roi_y:roi_y+roi_h, roi_x:roi_x+roi_w]
                
                # Detecção de mão
                mask = self.create_skin_mask(roi)
                
                # Encontra contornos
                contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                
                current_gesture = "INDEFINIDO"
                finger_count = 0
                geometry = {}
                
                if contours:
                    # Maior contorno
                    hand_contour = max(contours, key=cv2.contourArea)
                    area = cv2.contourArea(hand_contour)
                    
                    if self.min_area < area < self.max_area:
                        # Análise
                        geometry = self.analyze_hand_geometry(hand_contour)
                        finger_count = self.count_extended_fingers(hand_contour)
                        
                        # Classifica letra
                        current_gesture = self.classify_libras_letter(geometry, finger_count)
                        
                        # Adiciona ao buffer para estabilização
                        self.gesture_buffer.append(current_gesture)
                
                # Sistema de estabilização
                if len(self.gesture_buffer) >= 10:
                    gesture_counts = {}
                    for g in list(self.gesture_buffer)[-10:]:
                        gesture_counts[g] = gesture_counts.get(g, 0) + 1
                    
                    most_common = max(gesture_counts, key=gesture_counts.get)
                    confidence = gesture_counts[most_common] / 10
                    
                    if confidence >= 0.7 and most_common != "INDEFINIDO":
                        if most_common != self.last_gesture:
                            self.update_letter_sequence(most_common)
                            self.last_gesture = most_common
                
                # Atualiza status no terminal a cada 15 frames
                if frame_count % 15 == 0:
                    self.print_status(current_gesture, finger_count, geometry)
                
                # Salva frame para debug (opcional)
                if not self.headless_mode and frame_count % 30 == 0:
                    cv2.imwrite('/tmp/debug_frame.jpg', frame)
                
        except KeyboardInterrupt:
            print("\n🛑 Detector interrompido pelo usuário")
        
        finally:
            cap.release()
            GPIO.cleanup()
            print("✓ Recursos liberados")

def main():
    """Função principal"""
    detector = LibrasDetectorPi()
    
    try:
        detector.run()
    except Exception as e:
        print(f"❌ Erro crítico: {e}")
        GPIO.cleanup()

if __name__ == "__main__":
    main()
