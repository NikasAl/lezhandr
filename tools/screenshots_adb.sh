#!/bin/bash
#
# Интерактивный скрипт для создания скриншотов с Android-устройства для RuStore
#
# Использование:
#   bash tools/screenshots_adb.sh
#
# Работа:
#   1. Устанавливает разрешение 1080x1920 (9:16)
#   2. Ждёт ввода имени скриншота
#   3. По Enter делает скриншот
#   4. Введите 'q' для выхода и восстановления разрешения
#

set -e

# Конфигурация
SCREENS_DIR="screens"
TARGET_WIDTH=1080
TARGET_HEIGHT=1920
DEVICE_PATH="/sdcard/lezhandr_screen.png"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

# Предустановленные имена
SCREENSHOT_NAMES=(
    "main_scr"
    "lib_scr"
    "task_scr"
    "solve_scr"
    "my_sol_scr"
    "stat_scr"
    "concepts_map_scr"
)

# Проверка ADB
check_adb() {
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}ADB не найден. Установите:${NC}"
        echo "  Ubuntu/Debian: sudo apt install android-tools-adb"
        exit 1
    fi
}

# Проверка подключения устройства
check_device() {
    local devices=$(adb devices 2>/dev/null | grep -v "List" | grep -c "device" || echo "0")
    if [ "$devices" -eq 0 ]; then
        echo -e "${RED}Устройство не подключено${NC}"
        echo ""
        echo "Проверьте:"
        echo "  1. USB-кабель подключён"
        echo "  2. USB-отладка включена"
        echo "  3. Разрешена отладка на этом компьютере"
        exit 1
    fi
}

# Установить разрешение
setup_resolution() {
    local current=$(adb shell wm size 2>/dev/null | grep -oP '\d+x\d+' || echo "")
    echo "$current" > /tmp/adb_original_resolution.txt
    
    echo -e "${CYAN}Установка разрешения ${TARGET_WIDTH}x${TARGET_HEIGHT} (9:16)...${NC}"
    adb shell wm size ${TARGET_WIDTH}x${TARGET_HEIGHT} 2>/dev/null
    
    local density=$((TARGET_WIDTH * 160 / 360))
    adb shell wm density $density 2>/dev/null
    
    echo -e "${GREEN}✓ Разрешение установлено${NC}"
    echo ""
}

# Восстановить разрешение
restore_resolution() {
    echo ""
    echo -e "${YELLOW}Восстановление разрешения...${NC}"
    adb shell wm size reset 2>/dev/null
    adb shell wm density reset 2>/dev/null
    rm -f /tmp/adb_original_resolution.txt
    echo -e "${GREEN}✓ Разрешение восстановлено${NC}"
}

# Сделать скриншот
take_screenshot() {
    local name="$1"
    name="${name%.png}"
    name="${name%.jpg}"
    
    local output_file="$SCREENS_DIR/${name}.png"
    
    # Если файл существует, добавляем номер
    local counter=1
    while [ -f "$output_file" ]; do
        output_file="$SCREENS_DIR/${name}_${counter}.png"
        ((counter++))
    done
    
    # Делаем скриншот
    adb shell screencap -p "$DEVICE_PATH" 2>/dev/null
    adb pull "$DEVICE_PATH" "$output_file" 2>/dev/null
    adb shell rm "$DEVICE_PATH" 2>/dev/null
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}✓ Сохранено: $output_file${NC}"
        check_aspect_ratio "$output_file"
    else
        echo -e "${RED}✗ Ошибка${NC}"
    fi
}

# Проверка соотношения сторон
check_aspect_ratio() {
    local file="$1"
    
    if ! command -v identify &> /dev/null; then
        return
    fi
    
    local w=$(identify -format "%w" "$file" 2>/dev/null)
    local h=$(identify -format "%h" "$file" 2>/dev/null)
    
    if [ -z "$w" ] || [ -z "$h" ]; then
        return
    fi
    
    local ratio=$(python3 -c "print(f'{$w/$h:.4f}')" 2>/dev/null || echo "?")
    
    if (( $(echo "$ratio > 0.55 && $ratio < 0.58" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${DIM}   ${w}x${h} ratio=${ratio} (9:16 ✓)${NC}"
    else
        echo -e "${YELLOW}   ${w}x${h} ratio=${ratio} (требуется 0.5625)${NC}"
    fi
}

# Показать подсказки
show_hints() {
    echo ""
    echo -e "${DIM}Быстрые имена:${NC}"
    local line="  "
    for name in "${SCREENSHOT_NAMES[@]}"; do
        line+="$name  "
        if [ ${#line} -gt 60 ]; then
            echo -e "${DIM}${line}${NC}"
            line="  "
        fi
    done
    if [ ${#line} -gt 2 ]; then
        echo -e "${DIM}${line}${NC}"
    fi
}

# Главная функция
main() {
    clear
    
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Скриншоты для RuStore (9:16)${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    
    check_adb
    check_device
    
    # Установка разрешения
    setup_resolution
    
    echo -e "${CYAN}Режим скриншотов активен${NC}"
    echo ""
    echo -e "${DIM}• Введите имя скриншота и нажмите Enter${NC}"
    echo -e "${DIM}• Введите ${YELLOW}q${DIM} для выхода${NC}"
    echo -e "${DIM}• Введите ${YELLOW}check${DIM} для проверки скриншотов${NC}"
    
    show_hints
    
    echo ""
    echo -e "${GREEN}────────────────────────────────────────${NC}"
    
    # Создаём папку
    mkdir -p "$SCREENS_DIR"
    
    # Счётчик скриншотов
    local count=0
    
    # Основной цикл
    while true; do
        echo ""
        echo -ne "${CYAN}Имя скриншота > ${NC}"
        read -r input
        
        # Проверка на выход
        if [ "$input" = "q" ] || [ "$input" = "Q" ] || [ "$input" = "quit" ] || [ "$input" = "exit" ]; then
            break
        fi
        
        # Проверка скриншотов
        if [ "$input" = "check" ]; then
            echo ""
            check_screens
            continue
        fi
        
        # Пустой ввод - показать подсказки
        if [ -z "$input" ]; then
            show_hints
            continue
        fi
        
        # Делаем скриншот
        take_screenshot "$input"
        ((count++))
    done
    
    # Восстановление
    restore_resolution
    
    echo ""
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}Создано скриншотов: $count${NC}"
        echo -e "${DIM}Папка: $SCREENS_DIR/${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}До свидания!${NC}"
}

# Проверка скриншотов
check_screens() {
    echo -e "${GREEN}Проверка скриншотов:${NC}"
    echo ""
    
    local found=0
    for f in "$SCREENS_DIR"/*.{png,jpg} 2>/dev/null; do
        if [ -f "$f" ]; then
            found=1
            local name=$(basename "$f")
            
            if command -v identify &> /dev/null; then
                local w=$(identify -format "%w" "$f" 2>/dev/null)
                local h=$(identify -format "%h" "$f" 2>/dev/null)
                local ratio=$(python3 -c "print(f'{$w/$h:.4f}')" 2>/dev/null || echo "?")
                
                if (( $(echo "$ratio > 0.55 && $ratio < 0.58" | bc -l 2>/dev/null || echo "0") )); then
                    echo -e "  ${GREEN}✓${NC} $name ${DIM}(${w}x${h})${NC}"
                else
                    echo -e "  ${YELLOW}✗${NC} $name ${DIM}(${w}x${h} ratio=${ratio})${NC}"
                fi
            else
                echo -e "  ${DIM}?${NC} $name"
            fi
        fi
    done
    
    if [ "$found" = "0" ]; then
        echo -e "${YELLOW}  Скриншотов пока нет${NC}"
    fi
}

# Запуск
main
