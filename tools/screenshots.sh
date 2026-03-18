#!/bin/bash
#
# Скрипт для создания скриншотов приложения для RuStore
# Выбор окна - кликом мыши, размер автоматически 9:16
#
# Использование:
#   ./tools/screenshots.sh [название_скриншота]
#   ./tools/screenshots.sh run      # запустить Flutter в режиме скриншотов
#   ./tools/screenshots.sh check    # проверить соотношение сторон
#

set -e

# Конфигурация
SCREENS_DIR="screens"
WINDOW_SIZE="1080x1920"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Проверка зависимостей
check_deps() {
    local missing=()

    command -v xdotool &> /dev/null || missing+=("xdotool")
    command -v maim &> /dev/null || missing+=("maim")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Отсутствуют необходимые инструменты:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Установка:"
        echo "  Ubuntu/Debian: sudo apt install xdotool maim"
        echo "  Arch: sudo pacman -S xdotool maim"
        echo "  Fedora: sudo dnf install xdotool maim"
        exit 1
    fi
}

# Выбор окна кликом мыши
select_window() {
    echo -e "${CYAN}Кликните на окно приложения для скриншота...${NC}"

    # Ждём клика и получаем ID окна
    window_id=$(xdotool selectwindow 2>/dev/null)

    if [ -z "$window_id" ]; then
        echo -e "${RED}Окно не выбрано${NC}"
        exit 1
    fi

    # Получаем имя окна для информации
    window_name=$(xdotool getwindowname "$window_id" 2>/dev/null || echo "Unknown")

    echo -e "${GREEN}✓ Выбрано окно: $window_name${NC}"

    echo "$window_id"
}

# Создание скриншота выбранного окна
take_screenshot() {
    local window_id="$1"
    local output_file="$2"

    # Захват выбранного окна
    maim -i "$window_id" "$output_file"
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

    # Проверка 9:16 (0.5625)
    local ratio=$(python3 -c "print(f'{$w/$h:.4f}'')" 2>/dev/null || echo "0")
    local target="0.5625"
    local diff=$(python3 -c "print(abs($ratio - $target))" 2>/dev/null || echo "1")

    if (( $(echo "$diff < 0.02" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${GREEN}   Соотношение: ${ratio} (9:16 ✓)${NC}"
    else
        echo -e "${YELLOW}   Соотношение: ${ratio} (требуется 0.5625 для 9:16)${NC}"
        echo -e "${YELLOW}   Размер: ${w}x${h}${NC}"
    fi
}

# Запуск приложения в режиме скриншотов
run_app() {
    echo -e "${GREEN}Запуск Flutter в режиме скриншотов...${NC}"
    echo "Размер окна: $WINDOW_SIZE (соотношение 9:16)"
    echo ""
    export FLUTTER_SCREENSHOT_MODE=1
    cd "$(dirname "$0")/.."
    flutter run -d linux
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

    echo -e "${CYAN}Выберите скриншот (введите номер или имя):${NC}"
    echo ""
    for i in "${!names[@]}"; do
        local num=$((i+1))
        local name="${names[$i]%%:*}"
        local desc="${names[$i]##*:}"
        echo "  $num) $name — $desc"
    done
    echo ""
    read -p "> " choice

    # Если введено число
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#names[@]} ]; then
        local idx=$((choice-1))
        echo "${names[$idx]%%:*}"
    else
        # Иначе возвращаем как есть
        echo "$choice"
    fi
}

# Создание папки
mkdir -p "$SCREENS_DIR"

# Обработка аргументов
case "$1" in
    run)
        run_app
        exit 0
        ;;
    check)
        check_screens
        exit 0
        ;;
esac

# Основной режим - создание скриншота
check_deps

screenshot_name="${1:-}"

if [ -z "$screenshot_name" ]; then
    screenshot_name=$(interactive_select)
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
echo -e "${YELLOW}Совет: Запустите приложение в режиме скриншотов:${NC}"
echo "   bash tools/screenshots.sh run"
echo ""

# Выбор окна
window_id=$(select_window)

# Создание скриншота
echo "Создание скриншота..."
take_screenshot "$window_id" "$output_file"

if [ -f "$output_file" ]; then
    echo -e "${GREEN}✓ Сохранено: $output_file${NC}"
    check_aspect_ratio "$output_file"
else
    echo -e "${RED}✗ Ошибка создания скриншота${NC}"
    exit 1
fi
