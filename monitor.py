#!/usr/bin/env python3
import psutil
import time
import subprocess

def monitor_system():
    print("=== MONITOR DE PERFORMANCE ===")
    print("Pressione Ctrl+C para sair")
    print("")
    
    try:
        while True:
            # CPU e Memória
            cpu = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory().percent
            
            # Temperatura
            try:
                temp_cmd = subprocess.run(['vcgencmd', 'measure_temp'], 
                                         capture_output=True, text=True)
                temp = temp_cmd.stdout.strip().replace('temp=', '').replace("'C", '°C')
            except:
                temp = "N/A"
            
            # GPU Memory
            try:
                gpu_cmd = subprocess.run(['vcgencmd', 'get_mem', 'gpu'], 
                                        capture_output=True, text=True)
                gpu_mem = gpu_cmd.stdout.strip().replace('gpu=', '')
            except:
                gpu_mem = "N/A"
            
            print(f"\rCPU: {cpu:5.1f}% | RAM: {memory:5.1f}% | Temp: {temp:>8} | GPU: {gpu_mem:>8}", 
                  end='', flush=True)
            
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\nMonitoramento finalizado.")

if __name__ == "__main__":
    monitor_system()