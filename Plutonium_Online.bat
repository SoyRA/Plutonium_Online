:: ============================================================================
:: @title        Plutonium Online Launcher
:: @description  Permite actualizar Plutonium y acceder directamente a su lanzador.
:: @author       SoyRA
:: @encoding     UTF-8
:: @platform     Windows (CMD / Batch)
:: ============================================================================

:: ============================================================================
:: @section      Configuración Inicial
:: @description  Configura entorno, codificación, color y título de ventana.
:: ============================================================================

@ECHO OFF
CHCP 65001 > NUL
COLOR 07
TITLE Plutonium Online Launcher
SETLOCAL ENABLEEXTENSIONS
CD /D "%~dp0" || PAUSE && EXIT /B

:: ============================================================================
:: @section      Variables internas
:: @description  Variables que el usuario no debe modificar.
:: ============================================================================

SET PLUTONIUM_UPDATER_URL=https://github.com/mxve/plutonium-updater.rs/releases/download/v0.4.5/plutonium-updater-x86_64-pc-windows-msvc.zip
SET PLUTONIUM_UPDATER_ARCHIVE=plutonium-updater.zip
SET PLUTONIUM_UPDATER_FILE=plutonium-updater.exe

SET PLUTONIUM_CDN=https://cdn.plutoniummod.com/updater/prod/info.json
SET PLUTONIUM_PATH=%LOCALAPPDATA%\Plutonium
SET PLUTONIUM_FILE=plutonium-launcher-win32.exe

:: ============================================================================
:: @section      Flujo principal
:: @description  Llama a subrutinas principales en orden lógico.
:: ============================================================================

CALL :show_main_menu
EXIT /B

:: ============================================================================
:: @subroutine   show_main_menu
:: @description  Muestra un menú para seleccionar entre las diferentes opciones.
:: ============================================================================

:show_main_menu
    CLS
    COLOR 07
    ECHO.
    ECHO ////////////////////////////////////////////////////////////////
    ECHO ////                    Plutonium Online                    ////
    ECHO ////////////////////////////////////////////////////////////////
    ECHO.
    ECHO [1] Iniciar el actualizador
    ECHO [2] Iniciar el lanzador
    ECHO [3] Instalar redistribuibles
    ECHO.
    CHOICE /C 123 /N /M "¿Qué querés hacer? "

    IF %ERRORLEVEL% EQU 1 (
        CALL :run_updater
    )

    IF %ERRORLEVEL% EQU 2 (
        CALL :run_launcher
    )

    IF %ERRORLEVEL% EQU 3 (
        CALL :install_redist
    )

    GOTO :EOF

:: ============================================================================
:: @subroutine   run_updater
:: @description  Descarga e inicia el Plutonium CLI Updater.
:: @author       mxve <https://github.com/mxve/plutonium-updater.rs>
:: ============================================================================

:run_updater
    TITLE Plutonium Updater
    CLS
    COLOR 07

    IF NOT EXIST "%PLUTONIUM_PATH%\%PLUTONIUM_UPDATER_FILE%" (
        ECHO Descargando %PLUTONIUM_UPDATER_ARCHIVE% en %PLUTONIUM_PATH%
        MKDIR "%PLUTONIUM_PATH%" > NUL 2>&1
        CALL curl.exe -f -L -o "%PLUTONIUM_PATH%\%PLUTONIUM_UPDATER_ARCHIVE%" -# "%PLUTONIUM_UPDATER_URL%"

        IF %ERRORLEVEL% NEQ 0 (
            COLOR 04
            ECHO.
            ECHO Descarga fallida.
            ECHO Se detendrá la ejecución...
            ECHO.
            PAUSE
            EXIT
        )

        ECHO Extrayendo %PLUTONIUM_UPDATER_ARCHIVE%...
        CALL tar -x -f "%PLUTONIUM_PATH%\%PLUTONIUM_UPDATER_ARCHIVE%" -C "%PLUTONIUM_PATH%"

        IF %ERRORLEVEL% NEQ 0 (
            COLOR 04
            ECHO.
            ECHO Extracción fallida.
            ECHO Se detendrá la ejecución...
            ECHO.
            PAUSE
            EXIT
        )

        ECHO Eliminando %PLUTONIUM_UPDATER_ARCHIVE%...
        DEL /F /Q "%PLUTONIUM_PATH%\%PLUTONIUM_UPDATER_ARCHIVE%"
    )

    ECHO Iniciando %PLUTONIUM_UPDATER_FILE%...
    CALL "%PLUTONIUM_PATH%\%PLUTONIUM_UPDATER_FILE%" -d "%PLUTONIUM_PATH%" -f -l -q --cdn-url "%PLUTONIUM_CDN%"

    IF %ERRORLEVEL% NEQ 0 (
        COLOR 04
        ECHO.
        ECHO Actualización fallida.
        ECHO Se detendrá la ejecución...
        ECHO.
        PAUSE
        EXIT
    )

    ECHO.
    ECHO Actualización exitosa.
    ECHO.
    PAUSE
    CALL :run_launcher
    GOTO :EOF

:: ============================================================================
:: @subroutine   run_launcher
:: @description  Inicia el Plutonium Launcher.
:: ============================================================================

:run_launcher
    TITLE Plutonium Launcher
    CLS

    IF NOT EXIST "%PLUTONIUM_PATH%\bin\%PLUTONIUM_FILE%" (
        COLOR 04
        ECHO.
        ECHO No se encontró %PLUTONIUM_FILE% ¿Cómo querés jugar en Plutonium si nunca lo instalaste?
        ECHO Se detendrá la ejecución...
        ECHO.
        PAUSE
        EXIT
    )

    COLOR 02
    ECHO.
    ECHO Iniciando el lanzador...
    START "Plutonium Launcher" /D "%PLUTONIUM_PATH%" "bin\%PLUTONIUM_FILE%"
    ECHO Ya no necesitás esta ventana, así que se cerrará automáticamente.
    ECHO.
    TIMEOUT /T 15
    GOTO :EOF


:: ============================================================================
:: @subroutine   install_redist
:: @description  Descarga e instala los programas redistribuibles comunes.
:: @author       Chase <https://git.chse.sh/chase/redist-installer>
:: ============================================================================

:install_redist
    TITLE Redist Installer
    CLS
    COLOR 06
    ECHO Se ejecutará una ventana PowerShell la cual descargará y ejecutará el script de Chase.
    ECHO Esto es algo que tenés que hacer una sola vez y sólo reinicia la PC al finalizar (no durante la instalación).
    ECHO.
    CHOICE /C SN /N /M "¿Querés continuar, (S)í o (N)o? "

    IF %ERRORLEVEL% EQU 1 (
        CLS
        COLOR 07
        ECHO Descargando y ejecutando el script de Chase...
        CALL PowerShell.exe -NoLogo -NoProfile -NonInteractive -Command "irm chse.dev/ri | iex"
        PAUSE
    )

    GOTO :EOF
