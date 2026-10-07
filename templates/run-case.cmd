@echo off
rem Runs run-case.cs, which sits next to this file. Same options; see: run-case --help
set DOTNET_NOLOGO=1
dotnet run --file "%~dp0run-case.cs" -- %*
