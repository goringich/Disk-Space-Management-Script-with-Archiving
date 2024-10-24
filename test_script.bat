@echo off
setlocal
rmdir /S /Q "%LOG_DIR%"
rmdir /S /Q "%BACKUP_DIR%"
:: Папки и порог
set LOG_DIR=.\log
set BACKUP_DIR=.\backup

:: Создание папки логов, если её нет
if not exist "%LOG_DIR%" (
  mkdir "%LOG_DIR%"
  echo Папка для логов создана: %LOG_DIR%
) else (
  echo Папка для логов уже существует: %LOG_DIR%
)

:: Очистка папки логов перед созданием тестовых файлов
echo Очищаю папку логов от старых файлов...
del /q "%LOG_DIR%\*"

:: Генерация файлов для тестов (создаю минимум 5000 Мб)
echo Создаю тестовые файлы на 5000 Мб
for /l %%i in (1,1,100) do (
  fsutil file createnew "%LOG_DIR%\test_file_%%i.log" 52428800 >nul
  echo Файл test_file_%%i.log создан.
)

:: Тест 1: Порог 10%
set THRESHOLD=10
echo Тест 1: Порог в %THRESHOLD%%
call script.bat "%LOG_DIR%" %THRESHOLD% "%BACKUP_DIR%\10"

if exist "%BACKUP_DIR%\10\" (
  echo Тест 1 не пройден: Файлы были архивированы при пороге %THRESHOLD%%
) else (
  echo Тест 1 пройден: Архивация не выполнялась
)




:: Очистка папки логов перед созданием тестовых файлов
echo Очищаю папку логов от старых файлов...
del /q "%LOG_DIR%\*"

:: Генерация файлов для тестов (создаю минимум 5000 Мб)
echo Создаю тестовые файлы на 5000 Мб
for /l %%i in (1,1,100) do (
  fsutil file createnew "%LOG_DIR%\test_file_%%i.log" 52428800 >nul
  echo Файл test_file_%%i.log создан.
)

:: Тест 2: Порог 1%
set THRESHOLD=1
echo Тест 2: Порог в %THRESHOLD%%
call script.bat "%LOG_DIR%" %THRESHOLD% "%BACKUP_DIR%\1"

if exist "%BACKUP_DIR%\1\" (
  echo Тест 2 пройден: Файлы были успешно архивированы
) else (
  echo Тест 2 не пройден: Архивация не была выполнена
)





:: Очистка папки логов перед созданием тестовых файлов
echo Очищаю папку логов от старых файлов...
del /q "%LOG_DIR%\*"

:: Генерация файлов для тестов (создаю минимум 5000 Мб)
echo Создаю тестовые файлы на 5000 Мб
for /l %%i in (1,1,100) do (
  fsutil file createnew "%LOG_DIR%\test_file_%%i.log" 52428800 >nul
  echo Файл test_file_%%i.log создан.
)

:: Тест 3: Порог 5%
set THRESHOLD=5
echo Тест 3: Порог в %THRESHOLD%%
call script.bat "%LOG_DIR%" %THRESHOLD% "%BACKUP_DIR%\5"

if exist "%BACKUP_DIR%\5\" (
  echo Тест 3 пройден: Файлы были успешно архивированы
) else (
  echo Тест 3 не пройден: Архивация не была выполнена
)



:: Очистка папки логов перед созданием тестовых файлов
echo Очищаю папку логов от старых файлов...
del /q "%LOG_DIR%\*"

:: Генерация файлов для тестов (создаю минимум 5000 Мб)
echo Создаю тестовые файлы на 5000 Мб
for /l %%i in (1,1,100) do (
  fsutil file createnew "%LOG_DIR%\test_file_%%i.log" 52428800 >nul
  echo Файл test_file_%%i.log создан.
)

:: Тест 4: Порог 50%
set THRESHOLD=50
echo Тест 4: Порог в %THRESHOLD%%
call script.bat "%LOG_DIR%" %THRESHOLD% "%BACKUP_DIR%\50"

if exist "%BACKUP_DIR%\50\" (
  echo Тест 4 не пройден: Файлы были архивированы при пороге %THRESHOLD%%
) else (
  echo Тест 4 пройден: Архивация не выполнялась
)

:: Очистка данных после тестов
::rmdir /S /Q "%LOG_DIR%"
::rmdir /S /Q "%BACKUP_DIR%"

echo Тестирование завершено.
endlocal
