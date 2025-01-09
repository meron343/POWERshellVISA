
@echo このバッチファイルと同名の.Ps1ファイルを開きます。
@echo %~n0

@echo off
rem 文字コードANSI推奨



powershell -Noprofile -Executionpolicy Bypass .\%~n0.ps1"

pause

rem powershell -Executionpolicy　一覧 
rem Restricted 	すべてのスクリプト実行を禁止。
rem #All Signed 	署名があるスクリプトを許可。
rem #Remote Signed 	端末内に保存されたスクリプト、または、インターネ#ットからダウンロードしたもののうち、署名があるスクリプトは許可。
rem Unrestricted 	署名されていないスクリプトも含めて実行許可。インターネットからダウンロードしたものは明示的な許可が必要。
rem Bypass 	すべてのスクリプトの実行を許可。
