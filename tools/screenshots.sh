#!/bin/bash
#
# Скрипт для создания скриншотов приложения для RuStore
# Требования: maim (или flameshot/gnome-screenshot)
#
# Использование:
#   ./tools/screenshots.sh [название_скриншота]
#
# Примеры:
#   ./tools/screenshots.sh main_scr     # создаст screens/main_scr.png
#   ./tools/screenshots.sh              # интерактивный выбор имени
#

set -e

# Конфигурация
SCREENS_DIR="screens"
WINDOW_SIZE="1080x1920"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка инструментов
check_tools() {
    if command -v maim &> /dev/null; then
        SCREENSHOT_CMD="maim"
    elif command -v flameshot &> /dev/null; then
        SCREENSHOT_CMD="flameshot"
    elif command -v gnome-screenshot &> /dev/null; then
        SCREENSHOT_CMD="gnome-screenshot"
    else
        echo -e "${RED}Ошибка: Не найден инструмент для скриншотов${NC}"
        echo ""
        echo "Установите один из:"
        echo "  Ubuntu/Debian: sudo apt install maim"
        echo "  Ubuntu/Debian: sudo apt install flameshot"
        echo "  Ubuntu/Debian: sudo apt install gnome-screenshot"
        echo "  Arch: sudo pacman -S maim"
        echo "  Fedora: sudo dnf install maim"
        exit 1
    fi
    echo -e "${GREEN}Использую: $SCREENSHOT_CMD${NC}"
}

# Создание скриншота активного окна
take_screenshot() {
    local output_file="$1"

    case $SCREENSHOT_CMD in
        maim)
            # Захват активного окна
            maim -i "$(xdotool getactivewindow)" "$output_file"
            ;;
        flameshot)
            # flameshot GUI - пользователь выбирает область
            flameshot gui -p "$SCREENS_DIR"
            ;;
        gnome-screenshot)
            # Захват активного окна
            gnome-screenshot -w -f "$output_file"
            ;;
    esac
}

# Проверка соотношения сторон
check_aspect_ratio() {
    local file="$1"
    if command -v identify &> /dev/null; then
        local size=$(identify -format "%wx%h" "$file")
        local w=$(identify -format "%w" "$file")
        local h=$(identify -format "%h" "$file")

        # Проверка 9:16 (0.5625)
        local ratio=$(echo "scale=4; $w/$h" | bc 2>/dev/null || echo "0")
        local target="0.5625"
        local diff=$(echo "scale=4; $ratio - $target" | bc 2>/dev/null || echo "1")

        if [ "$(echo "$diff < 0.02 && $diff > -0.02" | bc)" -eq 1 ]; then
            echo -e "${GREEN}   Соотношение: $ratio (9:16 ✓)${NC}"
        else
            echo -e "${YELLOW}   Соотношение: $ratio (требуется 0.5625 для 9:16)${NC}"
            echo -e "${YELLOW}   Текущий размер: ${size}${NC}"
        fi
    fi
}

# Запуск приложения в режиме скриншотов
run_app() {
    echo "Запуск приложения в режиме скриншотов..."
    echo "Размер окна: $WINDOW_SIZE (9:16)"
    export FLUTTER_SCREENSHOT_MODE=1
    flutter run -d linux
}

# Создание папки
mkdir -p "$SCREENS_DIR"

# Проверка аргументов
if [ "$1" = "run" ]; then
    run_app
    exit 0
fi

if [ "$1" = "check" ]; then
    echo "Проверка скриншотов в папке $SCREENS_DIR/"
    echo ""
    for f in "$SCREENS_DIR"/*.{png,jpg} 2>/dev/null; do
        if [ -f "$f" ]; then
            if command -v identify &> /dev/null; then
                size=$(identify -format "%wx%h" "$f")
                w=$(identify -format "%w" "$f")
                h=$(identify -format "%h" "$f")
                ratio=$(echo "scale=4; $w/$h" | bc 2>/dev/null || echo "?")
                target="0.5625"

                if [ "$(echo "$ratio < 0.58 && $ratio > 0.54" | bc 2>/dev/null || echo "0")" -eq 1 ]; then
                    status="✓"
                else
                    status="✗"
                fi

                printf "%-30s %s  ratio=%s %s\n" "$(basename "$f")" "$size" "$ratio" "$status"
            fi
        fi
    done
    exit 0
fi

# Основной режим - создание скриншота
check_tools

screenshot_name="${1:-}"

if [ -z "$screenshot_name" ]; then
    echo "Доступные имена скриншотов:"
    echo "  main_scr       - Главный экран"
    echo "  lib_scr        - Библиотека"
    echo "  task_scr       - Задача"
    echo "  solve_scr      - Сессия решения"
    echo "  my_sol_scr     - Мои решения"
    echo "  stat_scr       - Статистика"
    echo "  concepts_map_scr - Карта концептов"
    echo ""
    read -p "Введите имя скриншота: " screenshot_name
fi

if [ -z "$screenshot_name" ]; then
    echo -e "${RED}Ошибка: не указано имя скриншота${NC}"
    exit 1
fi

# Убираем расширение если есть
screenshot_name="${screenshot_name%.png}"
screenshot_name="${screenshot_name%.jpg}"

output_file="$SCREENS_DIR/${screenshot_name}.png"

echo ""
echo -e "${YELLOW}Инструкция:${NC}"
echo "1. Приложение должно быть запущено в режиме скриншотов:"
echo "   ./tools/screenshots.sh run"
echo "   или: FLUTTER_SCREENSHOT_MODE=1 flutter run -d linux"
echo ""
echo "2. Активируйте окно приложения (кликните на него)"
echo "3. Нажмите Enter для создания скриншота..."
read -r

echo "Делаю скриншот..."
take_screenshot "$output_file"

if [ -f "$output_file" ]; then
    echo -e "${GREEN}✓ Скриншот сохранён: $output_file${NC}"
    check_aspect_ratio "$output_file"
else
    echo -e "${RED}✗ Ошибка создания скриншота${NC}"
    exit 1
fi
