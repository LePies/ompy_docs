@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "REPO_ROOT=%SCRIPT_DIR%\.."
set "BIN_DIR=%USERPROFILE%\bin"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

call :mk_init "%BIN_DIR%\init-ompy-docs.cmd"
call :mk_build "%BIN_DIR%\build-ompy-docs.cmd"
call :mk_ompy "%BIN_DIR%\ompy-docs.cmd"

echo.
echo Installed ompy_docs wrappers to:
echo   %BIN_DIR%
echo.
echo Add %%USERPROFILE%%\bin to PATH if needed, then:
echo   init-ompy-docs --project-path . --package-name mypkg
echo   build-ompy-docs
echo.
echo Repo: %REPO_ROOT%
exit /b 0

:mk_init
> "%~1" (
  echo @echo off
  echo setlocal EnableExtensions
  echo set "OMPY_DOCS_ROOT=%REPO_ROOT%"
  echo call "%SCRIPT_DIR%\init-ompy-docs.cmd" %%*
)
exit /b 0

:mk_build
> "%~1" (
  echo @echo off
  echo setlocal EnableExtensions
  echo set "OMPY_DOCS_ROOT=%REPO_ROOT%"
  echo call "%SCRIPT_DIR%\build-ompy-docs.cmd" %%*
)
exit /b 0

:mk_ompy
> "%~1" (
  echo @echo off
  echo setlocal EnableExtensions
  echo set "OMPY_DOCS_ROOT=%REPO_ROOT%"
  echo where py ^>nul 2^>^&1 ^&^& py -3 "%SCRIPT_DIR%\ompy_docs_cli.py" %%* ^&^& exit /b %%ERRORLEVEL%%
  echo where python ^>nul 2^>^&1 ^&^& python "%SCRIPT_DIR%\ompy_docs_cli.py" %%* ^&^& exit /b %%ERRORLEVEL%%
  echo echo Python 3 required. ^&^& exit /b 1
)
exit /b 0
