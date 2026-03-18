@echo off
setlocal enabledelayedexpansion
echo Creating Firefox extension package...
echo.

REM -----------------------------------------------------
REM CHECK REQUIRED FILES
REM -----------------------------------------------------

if not exist ..\manifest.json (
    echo ERROR: manifest.json not found!
    pause >nul
    goto end
)

if not exist ..\popup.html (
    echo ERROR: popup.html not found!
    pause >nul
    goto end
)

where web-ext >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: web-ext is not installed!
    echo Install it with: npm install -g web-ext
    pause >nul
    goto end
)

REM -----------------------------------------------------
REM SELECT BUILD METHOD
REM -----------------------------------------------------
echo ========================================
echo SELECT BUILD OPTIONS
echo ========================================
echo.
echo 1. Build without signing
echo 2. Build with signing
echo.
set /p build_method="Enter 1 or 2: "

if "%build_method%"=="1" goto ask_obfuscation
if "%build_method%"=="2" goto ask_obfuscation
echo Invalid option!
pause
goto end

:ask_obfuscation
echo.
echo Obfuscate JavaScript code?
echo 1. No  - keep original code
echo 2. Yes - obfuscate with javascript-obfuscator
echo.
set /p obf_method="Enter 1 or 2: "

if "%obf_method%"=="1" goto prepare_files
if "%obf_method%"=="2" goto prepare_files
echo Invalid option!
pause
goto end

REM -----------------------------------------------------
REM TEMP DIR
REM -----------------------------------------------------
:prepare_files
echo.
echo Removing previous temp_build (if exists)...
rmdir /s /q ..\temp_build >nul 2>&1
timeout /t 1 >nul
mkdir ..\temp_build

echo Copying files...
copy ..\manifest.json ..\temp_build\ >nul
copy ..\popup.html    ..\temp_build\ >nul

if exist ..\popup.css  copy ..\popup.css  ..\temp_build\ >nul

if "%obf_method%"=="2" goto do_obfuscate

if exist ..\popup.js      copy ..\popup.js      ..\temp_build\ >nul
if exist ..\background.js copy ..\background.js ..\temp_build\ >nul
goto copy_icons

:do_obfuscate
echo Obfuscating JS files...

if exist ..\popup.js (
    cmd /c "npx javascript-obfuscator ..\popup.js --output ..\temp_build\popup.js"
    if not exist ..\temp_build\popup.js (
        echo ERROR: Obfuscation of popup.js failed!
        pause >nul
        goto cleanup
    )
    echo   popup.js obfuscated.
)

if exist ..\background.js (
    cmd /c "npx javascript-obfuscator ..\background.js --output ..\temp_build\background.js"
    if not exist ..\temp_build\background.js (
        echo ERROR: Obfuscation of background.js failed!
        pause >nul
        goto cleanup
    )
    echo   background.js obfuscated.
)

echo Obfuscation completed successfully!

:copy_icons
if exist ..\icons (
    xcopy ..\icons ..\temp_build\icons\ /E /I /Q >nul
)

if exist ..\web-ext-artifacts-firefox rmdir /s /q ..\web-ext-artifacts-firefox

REM -----------------------------------------------------
REM BUILD WITHOUT SIGNING
REM -----------------------------------------------------
if "%build_method%"=="2" goto do_sign

echo.
echo Building WITHOUT signing...

call web-ext build --source-dir=..\temp_build --artifacts-dir=..\web-ext-artifacts-firefox --overwrite-dest

timeout /t 2 >nul

if !errorlevel! neq 0 (
    echo Build failed!
    goto cleanup
)

echo Build completed successfully!

echo.
echo Renaming output to .xpi...
for %%f in (..\web-ext-artifacts-firefox\*.zip) do (
    ren "%%f" "%%~nf.xpi"
    echo Output: ..\web-ext-artifacts-firefox\%%~nf.xpi
)

goto cleanup

REM -----------------------------------------------------
REM SIGNED BUILD
REM -----------------------------------------------------
:do_sign
echo.
echo Enter Mozilla API Key:
set /p api_key="> "

echo Enter Mozilla API Secret:
set /p api_secret="> "

if "%api_key%"=="" (
    echo API Key is required!
    pause
    goto cleanup
)

if "%api_secret%"=="" (
    echo API Secret is required!
    pause
    goto cleanup
)

echo.
echo Signing extension...

call web-ext sign --source-dir=..\temp_build --api-key=%api_key% --api-secret=%api_secret% --artifacts-dir=..\web-ext-artifacts-firefox --channel=unlisted

timeout /t 2 >nul

if !errorlevel! neq 0 (
    echo Signing failed!
) else (
    echo Signing completed successfully!
    echo Output .xpi is in: ..\web-ext-artifacts-firefox\
)

REM -----------------------------------------------------
REM CLEANUP
REM -----------------------------------------------------
:cleanup
echo.
echo Removing temp_build...
timeout /t 1 >nul
rmdir /s /q ..\temp_build >nul 2>&1
timeout /t 1 >nul

if exist ..\temp_build (
    echo WARNING: temp_build could NOT be deleted.
) else (
    echo temp_build removed successfully.
)

echo.
:end
echo Done.
pause