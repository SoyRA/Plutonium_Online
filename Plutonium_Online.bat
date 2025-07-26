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
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
CD /D "%~dp0" || PAUSE && EXIT /B

:: ============================================================================
:: @section      Variables internas
:: @description  Variables que el usuario no debe modificar.
:: ============================================================================

SET CLOUDFLARE_WARP_URL=https://1111-releases.cloudflareclient.com/win/latest
SET CLOUDFLARE_WARP_PATH=%PROGRAMFILES%\Cloudflare\Cloudflare WARP
SET CLOUDFLARE_WARP_FILE=Cloudflare_WARP.msi

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

    IF DEFINED CLOUDFLARE_WARP_ENABLED (
        CALL "%CLOUDFLARE_WARP_PATH%\warp-cli.exe" disconnect > NUL
        :: Acá se está tomando el ERRORLEVEL de Plutonium y no de Cloudflare.
        IF %ERRORLEVEL% NEQ 0 (
            COLOR 04
            ECHO.
            ECHO Actualización fallida.
            ECHO Se detendrá la ejecución...
            ECHO.
            PAUSE
            EXIT
        )
    )

    IF %ERRORLEVEL% NEQ 0 (
        COLOR 04
        ECHO.
        ECHO Actualización fallida, es posible que seas de las personas que necesita Cloudflare WARP para poder actualizar Plutonium.
        ECHO.
        CHOICE /C SN /N /M "¿Querés intentarlo de nuevo usando Cloudflare WARP, (S)í o (N)o? "

        IF !ERRORLEVEL! EQU 1 (
            CALL :enable_cloudflare_warp
            GOTO :EOF
        )

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
:: @subroutine   enable_cloudflare_warp
:: @description  Descarga, instala e inicia Cloudflare WARP.
:: @returns      CLOUDFLARE_WARP_ENABLED
:: ============================================================================

:enable_cloudflare_warp
    TITLE Cloudflare WARP
    CLS
    COLOR 07

    CALL "%CLOUDFLARE_WARP_PATH%\warp-cli.exe" status > NUL 2>&1

    IF %ERRORLEVEL% NEQ 0 (
        ECHO Descargando Cloudflare WARP...
        CALL curl.exe -f -L -o "%TEMP%\%CLOUDFLARE_WARP_FILE%" -# "%CLOUDFLARE_WARP_URL%"

        IF !ERRORLEVEL! NEQ 0 (
            COLOR 04
            ECHO.
            ECHO Descarga fallida.
            ECHO Se detendrá la ejecución...
            ECHO.
            PAUSE
            EXIT
        )

        ECHO Instalando Cloudflare WARP...
        START "Cloudflare WARP" /D "%WINDIR%\System32" /WAIT msiexec.exe /i "%TEMP%\%CLOUDFLARE_WARP_FILE%" /passive

        IF !ERRORLEVEL! NEQ 0 (
            COLOR 04
            ECHO.
            ECHO Instalación fallida.
            ECHO Se detendrá la ejecución...
            ECHO.
            PAUSE
            EXIT
        )

        ECHO Instalación exitosa.
        ECHO.
        ECHO 1. Seguí las instrucciones en pantalla porque es la primera vez que se inicia Cloudflare WARP.
        ECHO 2. Cuando te salga que podes conectarte, no necesitás hacerlo y ahí podes cerrarlo para continuar con este script.
        ECHO 3. Cloudflare WARP se ejecuta en cada inicio, podes desactivarlo en cualquier momento desde la pestaña Inicia del Administrador de tareas.
        ECHO.
        PAUSE
        CLS
    )

    ECHO Conectando a Cloudflare WARP...
    CALL "%CLOUDFLARE_WARP_PATH%\warp-cli.exe" connect > NUL
    TIMEOUT /T 5 /NOBREAK > NUL
    SET CLOUDFLARE_WARP_ENABLED=1

    ECHO.
    ECHO No tengo ganas de programar más comprobaciones, si lo siguiente dice algo de conectado pues está todo bien. :P
    ECHO.
    CALL "%CLOUDFLARE_WARP_PATH%\warp-cli.exe" status
    ECHO.
    ECHO Asumiendo que todo bien, ahora se volverá a repetir el proceso de actualización de Plutonium usando Cloudflare WARP.
    ECHO Y desactivando el mismo cuando el proceso finalice.
    ECHO.
    PAUSE

    CALL :run_updater
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
