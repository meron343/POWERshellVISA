$SKIP=$true;iex ((gc $MyInvocation.InvocationName|%{
    if ($SKIP -and ($_ -notmatch "^####FuncDef\s*$")){return}
    $SKIP=$false
    $_
})-join "`r`n")

Write-Host "POWER_VISA 3k2 by#343"
Write-Host "R7．1.23 "

#別のｐｓ１ファイルの内容をここに持ってくるincludeに近い
. ".\SUBFUNC\00_SUB_POWER_COM_1k1"
#. ".\SUBFUNC\01_SUB_FUNC"

<#　EXLIST　ここに書いたものは起動時順次自実行される
DEV_OPN "PWR,SKT,192.168.1.2:5025"    #SOCETDEV OPEN(' 'and','and':'is all delimiter)
DEV_OPN "RERAY COM COM9:9600"        #RS232DEV OPEN

$STR = QUE_CMD "PWR,Q,*IDN?"    #RETUEN_STRING QNLY
$BIN = QUE_CMD "PWR,QB,*IDN?"    #RETUEN_BYNARY ONLY
#>

while($true) {
	#繰り返し実行されるコマンド用
	SUB_KEYINPUT_EXEC #キー入力時に関数実行する関数（デバック用）
	Start-Sleep -Milliseconds 50#CPU負荷上昇防止
}

####FuncDef   
function SUB_KEYINPUT_EXEC{
	if([Console]::KeyAvailable){
		$message = Read-Host "Input a message "
		$BUF= $message.split(' ',2)

		try{
			if($BUF.length -lt 2){
				$ReturnValude = & $BUF[0]
				Write-Host  RTN: "$ReturnValude"
			}else{


			Write-Host $BUF[0] $BUF[1]
	                $FUNC   = $BUF[0]
			$HIKISU = $BUF[1].replace("""","")
				$ReturnValude = & $FUNC $HIKISU
				Write-Host  RTN: "$ReturnValude"
			}

		}catch{
			Write-Host コマンドが違います
			$FUNC_List = Get-ChildItem Function:
			#$#FUNC=$FUNC_List.split(':')
			Write-Host $FUNC
		}
	}
}

function SUB_END{
	#終了時実行コマンド実行位置
}
