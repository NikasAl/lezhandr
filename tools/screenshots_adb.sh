#!/bin/bash
#
# Скрипт для создания скриншотов с Android-устройства для RuStore
# Автоматически: устанавливает размер экрана → делает скриншот → копирует → чистит
#
# Требования: adb, подключённое устройство с включённой USB-отладкой
#
# Использование:
#   bash tools/screenshots_adb.sh setup      # установить разрешение 1080x1920
#   bash tools/screenshots_adb.sh main_scr  # сделать скриншот
#   bash tools/screenshots_adb.sh restore   # восстановить оригинальное разрешение
#   bash tools/screenshots_adb.sh check     # проверить все скриншоты
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
NC='\033[0m'

# Проверка ADB
check_adb() {
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}ADB не найден. Установите Android SDK Platform Tools:${NC}"
        echo "  Ubuntu/Debian: sudo apt install android-tools-adb"
        echo "  Arch: sudo pacman -S android-tools"
        echo "  Fedora: sudo dnf install android-tools"
        exit 1
    fi
}

# Проверка подключения устройства
check_device() {
    local devices=$(adb devices | grep -v "List of devices" | grep -c "device" || echo "0")
    if [ "$devices" -eq 0 ]; then
        echo -e "${RED}Устройство не подключено${NC}"
        echo ""
        echo "Проверьте:"
        echo "  1. USB-кабель подключён"
        echo "  2. USB-отладка включена (Настройки → Для разработчиков)"
        echo "  3. Разрешена отладка на этом компьютере"
        exit 1
    fi
}

# Получить текущее разрешение экрана
get_original_resolution() {
    adb shell wm size | grep -oP '\d+x\d+' || echo ""
}

# Установить разрешение для скриншотов (9:16)
setup_resolution() {
    check_adb
    check_device

    local current=$(get_original_resolution)
    
    echo -e "${CYAN}Текущее разрешение: $current${NC}"
    
    # Сохраняем оригинальное разрешение в файл
    echo "$current" > /tmp/adb_original_resolution.txt
    
    echo -e "${YELLOW}Установка разрешения ${TARGET_WIDTH}x${TARGET_HEIGHT} (9:16)...${NC}"
    adb shell wm size ${TARGET_WIDTH}x${TARGET_HEIGHT}
    
    # Плотность пикселей для чёткости
    local density=$((TARGET_WIDTH * 160 / 360))
    adb shell wm density $density
    
    echo -e "${GREEN}✓ Разрешение установлено${NC}"
    echo ""
    echo -e "${YELLOW}Теперь откройте приложение и сделайте скриншоты кнопками:${NC}"
    echo "  bash tools/screenshots_adb.sh main_scr"
    echo "  bash tools/screenshots_adb.sh lib_scr"
    echo "  ..."
    echo ""
    echo -e "${YELLOW}Когда закончите — восстановите разрешение:${NC}"
    echo "  bash tools/screenshots_adb.sh restore"
}

# Восстановить оригинальное разрешение
restore_resolution() {
    check_adb
    check_device

    echo -e "${YELLOW}Восстановление оригинального разрешения...${NC}"
    
    adb shell wm size reset
    adb shell wm density reset
    
    # Удаляем временный файл
    rm -f /tmp/adb_original_resolution.txt
    
    echo -e "${GREEN}✓ Разрешение восстановлено${NC}"
}

# Сделать скриншот и скопировать на ПК
take_screenshot() {
    local name="$1"
    
    check_adb
    check_device

    if [ -z "$name" ]; then
        name=$(interactive_select)
    fi

    # Убираем расширение если есть
    name="${name%.png}"
    name="${name%.jpg}"
    
    local output_file="$SCREENS_DIR/${name}.png"
    
    echo -e "${CYAN}Создание скриншота...${NC}"
    
    # Делаем скриншот на устройстве
    adb shell screencap -p "$DEVICE_PATH"
    
    # Копируем на ПК
    adb pull "$DEVICE_PATH" "$output_file" 2>/dev/null
    
    # Удаляем с устройства
    adb shell rm "$DEVICE_PATH"
    
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}✓ Сохранено: $output_file${NC}"
        check_aspect_ratio "$output_file"
    else
        echo -e "${RED}✗ Ошибка создания скриншота${NC}"
        exit 1
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
    
    local ratio=$(python3 -c "print(f'{$w/$h:.4f}'')" 2>/dev/null || echo "0")
    local target="0.5625"
    local diff=$(python3 -c "print(abs($ratio - $target))" 2>/dev/null || echo "1")
    
    if (( $(echo "$diff < 0.02" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${GREEN}   Соотношение: ${ratio} (9:16 ✓)${NC}"
    else
        echo -e "${YELLOW}   Соотношение: ${ratio} (требуется 0.5625)${NC}"
        echo -e "${YELLOW}   Размер: ${w}x${h}${NC}"
    fi
}

# Проверка всех скриншотов
check_screens() {
    echo -e "${GREEN}Проверка скриншотов в папке $SCREENS_DIR/${NC}"
    echo ""
    printf "%-30s %-15s %s\n" "Файл" "Размер" "Статус"
    echo "-----------------------------------------------------------"
    
    local has_files=0
    
    for f in "$SCREENS_DIR"/*.{png,jpg} 2>/dev/null; do
        if [ -f "$f" ]; then
            has_files=1
            if command -v identify &> /dev/null; then
                local w=$(identify -format "%w" "$f" 2>/dev/null)
                local h=$(identify -format "%h" "$f" 2>/dev/null)
                local size="${w}x${h}"
                
                local ratio=$(python3 -c "print(f'{$w/$h:.4f}'')" 2>/dev/null || echo "?")
                local diff=$(python3 -c "print(abs($ratio - 0.5625))" 2>/dev/null || echo "1")
                
                if (( $(echo "$diff < 0.02" | bc -l 2>/dev/null || echo "0") )); then
                    status="${GREEN}✓ 9:16${NC}"
                else
                    status="${YELLOW}✗ не 9:16${NC}"
                fi
                
                printf "%-30s %-15s %b\n" "$(basename "$f")" "$size" "$status"
            fi
        fi
    done
    
    if [ "$has_files" = "0" ]; then
        echo -e "${YELLOW}Скриншотов пока нет${NC}"
    fi
}

# Интерактивный выбор имени
interactive_select() {
    local names=(
        "main_scr:Главный экран"
        "lib_scr:Библиотека задач"
        "task_scr:Страница задачи"
        "solve_scr:Сессия решения"
        "my_sol_scr:Мои решения"
        "stat_scr:Статистика"
        "concepts_map_scr:Карта концептов"
    )
    
    echo -e "${CYAN}Выберите скриншот:${NC}"
    echo ""
    for i in "${!names[@]}"; do
        local num=$((i+1))
        local name="${names[$i]%%:*}"
        local desc="${names[$i]##*:}"
        echo "  $num) $name — $desc"
    done
    echo "  0) Выход"
    echo ""
    read -p "> " choice
    
    if [ "$choice" = "0" ]; then
        exit 0
    fi
    
    # Если введено число
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#names[@]} ]; then
        local idx=$((choice-1))
        echo "${names[$idx]%%:*}"
    else
        echo "$choice"
    fi
}

# Информация о статусе
status_info() {
    check_adb
    
    local connected=$(adb devices | grep -v "List of devices" | grep -c "device" || echo "0")
    
    echo -e "${GREEN}Статус ADB:${NC}"
    
    if [ "$connected" -gt 0 ]; then
        echo -e "  Устройство: ${GREEN}подключено${NC}"
        local current_res=$(get_original_resolution)
        echo "  Разрешение: $current_res"
        
        local saved_res=""
        if [ -f /tmp/adb_original_resolution.txt ]; then
            saved_res=$(cat /tmp/adb_original_resolution.txt)
            echo "  Оригинал:   $saved_res"
        fi
        
        # Проверка 9:16
        if [ -n "$current_res" ]; then
            local w=$(echo "$current_res" | cut -d'x' -f1)
            local h=$(echo "$current_res" | cut -d'x' -f2)
            local ratio=$(python3 -c "print(f'{$w/$h:.4f}')" 2>/dev/null || echo "?")
            
            if (( $(echo "$ratio > 0.55 && $ratio < 0.58" | bc -l 2>/dev/null || echo "0") )); then
                echo -e "  Режим:      ${GREEN}готов к скриншотам (9:16)${NC}"
            else
                echo -e "  Режим:      ${YELLOW}обычный${NC}"
            fi
        fi
    else
        echo -e "  Устройство: ${RED}не подключено${NC}"
    fi
}

# Создание папки
mkdir -p "$SCREENS_DIR"

# Обработка команд
case "${1:-}" in
    setup)
        setup_resolution
        ;;
    restore)
        restore_resolution
        ;;
    check)
        check_screens
        ;;
    status)
        status_info
        ;;
    "")
        echo -e "${CYAN}Использование:${NC}"
        echo ""
        echo "  bash tools/screenshots_adb.sh setup      # установить 1080x1920"
        echo "  bash tools/screenshots_adb.sh main_scr   # сделать скриншот"
        echo "  bash tools/screenshots_adb.sh restore    # восстановить разрешение"
        echo "  bash tools/screenshots_adb.sh check      # проверить скриншоты"
        echo "  bash tools/screenshots_adb.sh status     # статус устройства"
        echo ""
        echo -e "${YELLOW}Порядок работы:${NC}"
        echo "  1. Подключите телефон по USB"
        echo "  2. bash tools/screenshots_adb.sh setup"
        echo "  3. Откройте приложение на нужном экране"
        echo "  4. bash tools/screenshots_adb.sh main_scr (и т.д.)"
        echo "  5. bash tools/screenshots_adb.sh restore"
        ;;
    *)
        take_screenshot "$1"
        ;;
esac
