#!/bin/bash
# ===============================================
# --- НАСТРОЙКИ ---
# ВПИШИТЕ ИМЯ ВАШЕЙ БУТЫЛКИ ЗДЕСЬ
BOTTLE_NAME="Games New"
# ===============================================
# Цвета для вывода
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

PLIST_FILE="$HOME/Library/Preferences/com.codeweavers.CrossOver.plist"
BOTTLE_PATH="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE_NAME"
REG_FILE="$BOTTLE_PATH/system.reg"
# --- ШАГ 1: Закрытие CrossOver (усиленное) ---
echo -e "${YELLOW}Закрытие CrossOver и связанных процессов...${RESET}"
osascript -e 'quit app "CrossOver"' 2>/dev/null
while pgrep -f CrossOver >/dev/null; do
    pkill -9 -f CrossOver 2>/dev/null
    sleep 1
done
echo -e "${GREEN}Все процессы CrossOver завершены.${RESET}"
# --- ШАГ 2: Сброс триала приложения (PLIST) ---
echo -e "${YELLOW}Сброс триала приложения: удаление FirstRunDate и SULastCheckTime...${RESET}"
if [ -f "$PLIST_FILE" ]; then
    # Удаление FirstRunDate с циклом и проверкой
    while defaults read com.codeweavers.CrossOver FirstRunDate >/dev/null 2>&1; do
        defaults delete com.codeweavers.CrossOver FirstRunDate
        plutil -remove FirstRunDate "$PLIST_FILE" >/dev/null 2>&1
        killall cfprefsd 2>/dev/null  # Глобальный kill для всех экземпляров
        sleep 1
    done
    echo -e "${GREEN}FirstRunDate удалён.${RESET}"
    
    # Удаление SULastCheckTime с циклом и проверкой
    while defaults read com.codeweavers.CrossOver SULastCheckTime >/dev/null 2>&1; do
        defaults delete com.codeweavers.CrossOver SULastCheckTime
        plutil -remove SULastCheckTime "$PLIST_FILE" >/dev/null 2>&1
        killall cfprefsd 2>/dev/null
        sleep 1
    done
    echo -e "${GREEN}SULastCheckTime удалён.${RESET}"
    
    # Дополнительный flush кэша
    killall -u $USER cfprefsd 2>/dev/null
    echo -e "${GREEN}Кэш настроек очищен.${RESET}"
    
    # Fallback: Если удаление не сработало, установить текущую дату
    if defaults read com.codeweavers.CrossOver FirstRunDate >/dev/null 2>&1; then
        CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S %z")
        defaults write com.codeweavers.CrossOver FirstRunDate -date "$CURRENT_DATE"
        killall cfprefsd 2>/dev/null
        echo -e "${YELLOW}Удаление не удалось; установлена текущая дата как fallback.${RESET}"
    fi
else
    echo -e "${RED}Предупреждение: Файл настроек CrossOver не найден.${RESET}"
fi
# --- ШАГ 3: Сброс даты создания бутылки (SYSTEM.REG) ---
echo -e "${YELLOW}Сброс даты создания бутылки: очистка system.reg...${RESET}"
if [ -d "$BOTTLE_PATH" ]; then
    rm -f "$BOTTLE_PATH/.version" "$BOTTLE_PATH/.update-timestamp"
    echo -e "${GREEN}Удалены .version и .update-timestamp, если они были.${RESET}"
    if [ -f "$REG_FILE" ]; then
        cp "$REG_FILE" "$REG_FILE.bak"
        echo -e "${GREEN}Создана резервная копия: $REG_FILE.bak${RESET}"
        # Удаление блока с циклом для надежности
        while grep -q "\[Software\\\\CodeWeavers\\\\CrossOver\\\\cxoffice\]" "$REG_FILE"; do
            sed -i '' '/^\[Software\\CodeWeavers\\CrossOver\\cxoffice\]/,/^$/d' "$REG_FILE"
            sed -i '' '/"InstallDate"=dword:/d' "$REG_FILE"
            sleep 1
        done
        echo -e "${GREEN}Метки времени в реестре бутылки удалены.${RESET}"
    else
        echo -e "${RED}Ошибка: Файл реестра бутылки '$REG_FILE' не найден.${RESET}"
    fi
else
    echo -e "${RED}Ошибка: Директория бутылки '$BOTTLE_PATH' не найдена. Проверьте имя бутылки.${RESET}"
fi
echo -e "${GREEN}Операция завершена. Теперь можно запускать CrossOver и проверить с 'defaults read com.codeweavers.CrossOver FirstRunDate'.${RESET}"