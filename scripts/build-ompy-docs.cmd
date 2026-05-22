@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

where py >nul 2>&1 && (
  py -3 "%SCRIPT_DIR%\ompy_docs_cli.py" build %*
  exit /b %ERRORLEVEL%
)
where python >nul 2>&1 && (
  python "%SCRIPT_DIR%\ompy_docs_cli.py" build %*
  exit /b %ERRORLEVEL%
)
echo Python 3 is required on PATH.
exit /b 1
