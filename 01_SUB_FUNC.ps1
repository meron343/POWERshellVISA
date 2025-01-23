Write-Host -NoNewline "INCLUDE:"
$script_name = $myInvocation.MyCommand.name
Write-Host $script_name
function SUB_FCGET{

	$BYTEDATA = QUE_CMD "DX,QB,fc get"
	fcget (QUE_CMD "DX,QB,fc get")
}

function SUB_LIST {

	$str= Get-ChildItem Function:

	$Buffers = $str -split "\n"
	$Buffers = $Buffers -replace "[A-Z]:",""
	$Buffers = $Buffers -ne ""
	#$Buffers = $Buffers -split '[`r`n]'

	for($i=1;$i -lt $Buffers.length;$i++){
		Write-Host $Buffers[$i]
	}


}

function DX200_Rx{
$global:DX_data = @(0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)
$global:DX_unit = @(" "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," ")
try {
	$STR = QUE_CMD "DX,QC,fd0 , 001 ,020"
<#	返答文字列例
	EA
	DATE 25/01/01
	TIME 22:25:58.000
	N 001H   V     +01399E-02	#Hアラーム値にはHがつく
	N 002    A     +00000E-03
	S 005                    	#スキップ項目はS
#>
	#Write-Host VISA_Q_STR  $global:VISA_Q_STR 

	$BUFF= $STR.split('NS')
	#Write-Host 0 : $BUFF[0]

		for($i=1;20 -ge $i;$i++){
			$BUFF2 =$BUFF[ $i ].Trim() -split "\s+"   #\s+ で複数のスペース
			#Write-Host -NoNewline $i :0_ $BUFF2[0] _
			#Write-Host -NoNewline 1_ $BUFF2[1] _
			#Write-Host  2_ $BUFF2[2]
			$global:DX_data[ $i ] =  [double]$BUFF2[2] 
			$global:DX_unit[ $i ] =  $BUFF2[1] 

		}
	}catch{
		Write-Host “例外処理発生”
	}

}



function WAIT_time($str){
	$TIME_SEC =[double]$str
	$d = Get-Date
	$d = $d.AddSeconds( $str )
	$second = Get-Date
		while($second -lt $d){

		        $STEPTIME= $d - $second
			$time= [double]$STEPTIME.seconds +  [double]$STEPTIME.Milliseconds / 1000.0

			$second =  Get-Date

			Write-Host -NoNewline WAIT SEC($TIME_SEC - $time).ToString("0.0")"/"$TIME_SEC.ToString("0.0") "/"$a+$b "`r"
			Start-Sleep -Milliseconds 10
		}
}

#        SWEEP "PWR,1,VOLT,0.0, 14.0 , 6"
#        SWEEP "PWR,S,VOLT,0.0 > 14.0 s6"

function SWEEP($str){
	$Buffers = $str.split("[,>s]")

	#Write-Host Voltsweep $TIME_SEC sec $vol_STAT to $vol_END 
	$dev_id =$Buffers[0]
	$COMMAND =$Buffers[2]

	$vol_STAT =[double]$Buffers[3]
	$vol_END  =[double]$Buffers[4]
	$TIME_SEC =[double]$Buffers[5]


	$a = $vol_END - $vol_STAT
	$b = $vol_STAT

	$d = Get-Date
	$d = $d.AddSeconds( $TIME_SEC )

	$second = Get-Date
	if ($TIME_SEC -lt 1.0){
		while($second -lt $d){
		        $STEPTIME= $d - $second
			$time= [double]$STEPTIME.seconds +  [double]$STEPTIME.Milliseconds / 1000.0
			$send_volt = ($TIME_SEC - $time)/$TIME_SEC *$a   +$b
			$STRTEMP= $dev_id +",S," + $COMMAND +" " + $send_volt.ToString("0.00")
			Write-Host -NoNewline VOLTSWEEP SEC($TIME_SEC - $time).ToString("0.0")"/"$TIME_SEC.ToString("0.0") $STRTEMP"/"$a+$b "`r"			QUE_CMD  $STRTEMP
			Start-Sleep -Milliseconds 1
			$second =  Get-Date
		}


	}else{
		while($second -lt $d){

		        $STEPTIME= $d - $second
			$time= [double]$STEPTIME.seconds +  [double]$STEPTIME.Milliseconds / 1000.0
			if(       ($TIME_SEC - $time) -lt $TIME_SEC      ){
				$send_volt = ($TIME_SEC - $time)/$TIME_SEC *$a   +$b
			}else{
				$send_volt = $a   +$b
			}
		        $STRTEMP= $dev_id +",S," + $COMMAND +" " + $send_volt.ToString("0.00")
		        $RETN = QUE_CMD  $STRTEMP
			$second =  Get-Date
			Start-Sleep -Milliseconds 50
			Write-Host -NoNewline VOLTSWEEP SEC($TIME_SEC - $time).ToString("0.0")"/"$TIME_SEC.ToString("0.0") $STRTEMP"/"$a+$b "`r"
		}
	}

	$STRTEMP= $dev_id +",S," + $COMMAND +" " + $vol_END.ToString("0.00")
	QUE_CMD $STRTEMP
	Write-Host VOLTSWEEP SEC $TIME_SEC.ToString("0.0")"/"$TIME_SEC.ToString("0.0") $STRTEMP"/"$a+$b 
	Write-Host END`a



}




function fcget($byedata ){
	$B_DATA = $byedata
	$read   = $B_DATA.length

	#$B_DATA = QUE_CMD "DX,QB, "
	#$B_DATA = QUE_CMD "DX,QB,fc get"
	#Write-Host $B_DATA
	#$B_DATA | Format-Hex

	Write-Host FCGET DATA SUB
	Write-Host INPUTBYE = $read 

	$delimiter_sense = 0
	for($i = 0; $i -le 65534;$i++){

  			if($B_DATA[ $delimiter_sense   ] -ne  137){
				$delimiter_sense++
			}else{$i= 65535}

	}
	Write-Host DELIM_POS = $delimiter_sense
 
		$byteBuffer = New-Object System.Byte[] $read
		for($flg=$delimiter_sense ;$flg -le ($read ) ; $flg++){
			$byteBuffer[ $flg -  $delimiter_sense] = $B_DATA[ $flg  ]
		}



		#Set-Content -Path "out_sc.png" -Value $byteBuffer -Encoding Byte
		$date = get-date -Format "yyMMddHHmmss"
		$filename = ".\DATA\PNG" + $date + ".png"

		Set-Content -Path $filename -Value $byteBuffer -Encoding Byte
	Write-Host SAVEFILE = $filename
 return 
}

