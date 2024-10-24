@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Установка параметров
set "LOG_DIR=%~1"
set "THRESHOLD=%~2"
set "BACKUP_DIR=%~3"

echo Папка для логов: "%LOG_DIR%"
echo Порог заполненности: "%THRESHOLD%%"

:: Преобразуем относительный путь в абсолютный
for %%i in ("%LOG_DIR%") do set "LOG_DIR=%%~fi"
for %%i in ("%BACKUP_DIR%") do set "BACKUP_DIR=%%~fi"

echo Преобразованный путь к папке логов: "%LOG_DIR%"

set "MAX_LOG_SIZE_GB=1"
set /a MAX_LOG_SIZE_MB=%MAX_LOG_SIZE_GB%*1024
echo Максимальный размер папки логов (MB): "%MAX_LOG_SIZE_MB%"

:: Вычисляем пороговый размер в мегабайтах и байтах
set /a "THRESHOLD_MB=MAX_LOG_SIZE_MB * THRESHOLD / 100"
set /a "THRESHOLD_BYTES=THRESHOLD_MB * 1048576"
echo Пороговый размер (MB): "!THRESHOLD_MB!"
echo Пороговый размер (байт): "!THRESHOLD_BYTES!"

:: Проверка существования папки для бэкапов
if not exist "%BACKUP_DIR%" (
    echo Папка для бэкапов не существует. Создаю...
    mkdir "%BACKUP_DIR%"
    if exist "%BACKUP_DIR%" (
        echo Папка для бэкапов успешно создана.
    ) else (
        echo Не удалось создать папку для бэкапов.
        exit /b 1
    )
) else (
    echo Папка для бэкапов уже существует.
)

:: Получаем размер папки LOG_DIR в байтах (рекурсивно)
for /f %%a in ('powershell -NoProfile -Command "(Get-ChildItem -Path '%LOG_DIR%' -Recurse -File | Measure-Object -Property Length -Sum).Sum"') do set "CURRENT_FOLDER_SIZE=%%a"

:: Проверка превышения порога
if !CURRENT_FOLDER_SIZE! LSS !THRESHOLD_BYTES! (
    echo Заполнение папки меньше порога. Архивация не требуется.
    goto :EOF
) else (
    echo Заполнение папки превышает порог. Необходима архивация.

    :: Инициализируем переменные
    set "FILES_TO_KEEP="
    set /a "SIZE_ACCUMULATED=0"

    :: Сортируем файлы по дате изменения (от новых к старым), рекурсивно
    for /f "delims=" %%F in ('dir /s /b /a:-d /o:-d "%LOG_DIR%\*"') do (
        set "FILE=%%F"
        for %%S in ("%%F") do set "FILE_SIZE=%%~zS"

        :: Проверяем, нужно ли продолжать накопление
        if !SIZE_ACCUMULATED! LSS !THRESHOLD_BYTES! (
            :: Добавляем файл в список файлов для сохранения
            set "FILES_TO_KEEP=!FILES_TO_KEEP! "%%F""
            set /a "SIZE_ACCUMULATED+=FILE_SIZE"
        ) else (
            :: Достигли порога, выходим из цикла
            goto :DETERMINE_FILES_TO_ARCHIVE
        )
    )

    :DETERMINE_FILES_TO_ARCHIVE
    :: Получаем список всех файлов в LOG_DIR
    set "ALL_FILES="
    for /f "delims=" %%F in ('dir /s /b /a:-d "%LOG_DIR%\*"') do (
        set "ALL_FILES=!ALL_FILES! "%%F""
    )

    :: Инициализируем список файлов для архивирования
    set "FILES_TO_ARCHIVE="

    :: Сравниваем ALL_FILES и FILES_TO_KEEP, чтобы получить FILES_TO_ARCHIVE
    for %%F in (!ALL_FILES!) do (
        set "FOUND=0"
        for %%K in (!FILES_TO_KEEP!) do (
            if "%%~F"=="%%~K" set "FOUND=1"
        )
        if "!FOUND!"=="0" (
            set "FILES_TO_ARCHIVE=!FILES_TO_ARCHIVE! "%%F""
        )
    )

    if "!FILES_TO_ARCHIVE!"=="" (
        echo Нет файлов для архивирования.
        exit /b 0
    )

    :: Логирование файлов, которые будут архивироваться
    echo Архивируемые файлы:
    for %%a in (!FILES_TO_ARCHIVE!) do echo "%%~a"

    :: Архивирование файлов
    for %%a in (!FILES_TO_ARCHIVE!) do (
        echo Архивируем файл: "%%~a"
        copy "%%~a" "%BACKUP_DIR%\" >nul
        if exist "%%~a" del "%%~a"
    )

    echo Архив успешно создан. Файлы перенесены в "%BACKUP_DIR%"
)

echo Скрипт выполнен успешно.
endlocal
