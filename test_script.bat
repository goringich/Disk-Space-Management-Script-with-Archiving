@echo off
setlocal

:: Папки и порог
set LOG_DIR=.\log
set BACKUP_DIR=.\backup
set THRESHOLD=10

:: Создание папки логов, если её нет
if not exist "%LOG_DIR%" (
  mkdir "%LOG_DIR%"
  echo Папка для логов создана: %LOG_DIR%
) else (
  echo Папка для логов уже существует: %LOG_DIR%
)

:: Генерация файлов для тестов (создаю минимум 50 GB)
echo Создаю тестовые файлы на 50 GB...
for /l %%i in (1,1,100) do (
  fsutil file createnew "%LOG_DIR%\test_file_%%i.log" 524288000
  echo Файл test_file_%%i.log создан.
)

:: Тест 1: Порог 10%
set THRESHOLD=10
echo Тест 1: Порог в 10%
call script.bat "%LOG_DIR%" "%BACKUP_DIR%" %THRESHOLD%

if exist "%BACKUP_DIR%\test_file_1.log" (
  echo Тест 1 не пройден: Файлы были архивированы при пороге 10%
) else (
  echo Тест 1 пройден: Архивация не выполнялась
)

:: Тест 2: Порог 1%
set THRESHOLD=1
echo Тест 2: Порог в 1%
call script.bat "%LOG_DIR%" "%BACKUP_DIR%" %THRESHOLD%

if exist "%BACKUP_DIR%\test_file_1.log" (
  echo Тест 2 пройден: Файлы были успешно архивированы
) else (
  echo Тест 2 не пройден: Архивация не была выполнена
)

:: Тест 3: Порог 5%
set THRESHOLD=5
echo Тест 3: Порог в 5%
call script.bat "%LOG_DIR%" "%BACKUP_DIR%" %THRESHOLD%

if exist "%BACKUP_DIR%\test_file_10.log" (
  echo Тест 3 пройден: Часть файлов была успешно архивирована
) else (
  echo Тест 3 не пройден: Архивация не была выполнена
)

:: Тест 4: Порог 50%
set THRESHOLD=50
echo Тест 4: Порог в 50%
call script.bat "%LOG_DIR%" "%BACKUP_DIR%" %THRESHOLD%

if exist "%BACKUP_DIR%\test_file_20.log" (
  echo Тест 4 не пройден: Файлы были архивированы при пороге 50%
) else (
  echo Тест 4 пройден: Архивация не выполнялась
)

:: Очистка данных после тестов
rmdir /S /Q "%LOG_DIR%"
@REM rmdir /S /Q "%BACKUP_DIR%"

echo Тестирование завершено.
endlocal
