@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Установка параметров
set "LOG_DIR=%~1"
set "THRESHOLD=%~2"
set "BACKUP_DIR=%~3"

:: Преобразуем относительный путь в абсолютный
for %%i in (%LOG_DIR%) do set "LOG_DIR=%%~fi"
for %%i in (%BACKUP_DIR%) do set "BACKUP_DIR=%%~fi"

echo Папка для логов: %LOG_DIR%
echo Порог заполненности: %THRESHOLD%%
echo Папка для бэкапов: %BACKUP_DIR%

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

:: Получаем диск, на котором находится LOG_DIR
set "DRIVE_LETTER=%LOG_DIR:~0,2%"
echo Диск: %DRIVE_LETTER%

:: Получаем общий размер диска и сразу конвертируем в GB
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "(Get-PSDrive -Name %DRIVE_LETTER:~0,1%).Used / 1GB + (Get-PSDrive -Name %DRIVE_LETTER:~0,1%).Free / 1GB"`) do (
  set "TOTAL_SPACE_GB=%%a"
)

:: Получаем размер папки LOG_DIR в GB
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "(Get-ChildItem -Path '%LOG_DIR%' -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB"`) do (
  set "FOLDER_SIZE_GB=%%a"
)

:: Проверяем, что TOTAL_SPACE_GB корректен
if "!TOTAL_SPACE_GB!"=="" (
  echo Ошибка: Не удалось получить общий размер диска.
  exit /b 1
)

:: Проверяем, что FOLDER_SIZE_GB корректен
if "!FOLDER_SIZE_GB!"=="" (
  set "FOLDER_SIZE_GB=0"
)

echo Общий размер диска (GB): !TOTAL_SPACE_GB!
echo Размер папки (GB): !FOLDER_SIZE_GB!

:: Вычисляем процент использования вручную (не через PowerShell)
set /a PERCENT_USED=(!FOLDER_SIZE_GB! * 100) / !TOTAL_SPACE_GB!

echo Использование папки: !PERCENT_USED!%%

:: Проверка превышения порога
if !PERCENT_USED! LSS %THRESHOLD% (
  echo Заполнение папки меньше порога. Архивация не требуется.
) else (
  echo Заполнение папки превышает порог. Необходима архивация.

  :: Архивируем N самых старых файлов
  set "N=5"

  for /f "delims=" %%a in ('dir /b /a-d /o:d "%LOG_DIR%"') do (
    if !N! GTR 0 (
      echo Архивируем файл: %%a
      copy "%LOG_DIR%\%%a" "%BACKUP_DIR%\"
      del "%LOG_DIR%\%%a"
      set /a N-=1
    )
  )
)

echo Скрипт выполнен успешно.
endlocal
