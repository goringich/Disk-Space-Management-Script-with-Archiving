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

:: Получаем размер папки LOG_DIR в MB с корректным форматированием
for /f %%a in ('powershell -NoProfile -Command "$sizeMB = (Get-ChildItem -Path """"%LOG_DIR%"""" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB; [math]::Round($sizeMB, 2)"') do set "LOG_SIZE_MB=%%a"

:: Удаляем возможные нечисловые символы
::for /f "tokens=* delims=" %%a in ("!LOG_SIZE_MB!") do set "LOG_SIZE_MB=%%a"

echo Размер папки логов (MB): "!LOG_SIZE_MB!"

:: Вычисляем процент использования с помощью PowerShell
for /f %%a in ('powershell -NoProfile -Command "[System.Globalization.CultureInfo]::InvariantCulture; [math]::Round((%LOG_SIZE_MB% / %MAX_LOG_SIZE_MB%) * 100, 2)"') do set "PERCENT_USED=%%a"
echo Использование папки логов: "!PERCENT_USED!%%"

:: Извлекаем целую часть процента для сравнения
for /f "delims=.," %%a in ("!PERCENT_USED!") do set "PERCENT_INT=%%a"

echo Целая часть использования: "!PERCENT_INT!%%"


:: Проверка превышения порога
if !PERCENT_INT! LSS %THRESHOLD% (
    echo Заполнение папки меньше порога. Архивация не требуется.
) else (
    echo Заполнение папки превышает порог. Необходима архивация.

    :: Создаем метку времени для имени архива
    for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TIMESTAMP=%%a"
    set "ARCHIVE_NAME=%BACKUP_DIR%\backup_%TIMESTAMP%.tar.gz"

    echo Создание архива: "%ARCHIVE_NAME%"

    :: Путь к 7z.exe (проверьте, что путь корректен)
    set "SEVEN_ZIP_PATH=C:\Program Files\7-Zip\7z.exe"

    :: Проверяем, что 7z.exe существует
    ::if not exist "%SEVEN_ZIP_PATH%" (
    ::     echo Ошибка: 7z.exe не найден по пути "%SEVEN_ZIP_PATH%".
    ::     echo Проверьте правильность пути к 7z.exe и измените переменную SEVEN_ZIP_PATH в скрипте.
    ::     exit /b 1
    :: )

    :: Создаем tar архив
    "%SEVEN_ZIP_PATH%" a -ttar "%BACKUP_DIR%\backup_%TIMESTAMP%.tar" "%LOG_DIR%\*"

    :: Сжимаем tar архив в gz
    "%SEVEN_ZIP_PATH%" a -tgzip "%ARCHIVE_NAME%" "%BACKUP_DIR%\backup_%TIMESTAMP%.tar"

    :: Удаляем временный tar файл
    del "%BACKUP_DIR%\backup_%TIMESTAMP%.tar"

    :: Проверяем, что архив создан
    if exist "%ARCHIVE_NAME%" (
        echo Архив успешно создан. Удаление файлов из "%LOG_DIR%"
        del /q "%LOG_DIR%\*"
    ) else (
        echo Не удалось создать архив.
        exit /b 1
    )
)

echo Скрипт выполнен успешно.
endlocal
