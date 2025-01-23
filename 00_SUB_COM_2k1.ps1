#連想配列の作成(GLOBAL)
#これにより、$hashtable["PWR"].socketといったような、名前を使用した配列が作成可能となります。
#デバックのための対応です。
$hashtable = @{} 


function DEV_OPN ($str){
	$Buffers = $str.split("[, :]")
	$INDEX= $Buffers[0]
	try{
	    #連想配列にキー(連想配列)を追加します
	    #$hashtable["VH1"] = @{Dev="PWR"; IP="192.168.1.2";PORT=5025}
	    $hashtable[$INDEX]= @{} 
	    $hashtable[$INDEX].STATUS     ="DISCON"

    	if( $Buffers[1] -like "SKT" ){  #socket通信の場合
	        $hashtable[$INDEX].socket   = New-Object System.Net.Sockets.TcpClient($Buffers[2],[int]$Buffers[3])
	        $hashtable[$INDEX].Dev      = $Buffers[1]
	        $hashtable[$INDEX].IP       = $Buffers[2]
	        $hashtable[$INDEX].PORT     = [int]$Buffers[3]

	        $hashtable[$INDEX].stream   = $hashtable[$INDEX].socket.GetStream()
	        $hashtable[$INDEX].writer   = New-Object System.IO.StreamWriter($hashtable[$INDEX].stream)
	        $hashtable[$INDEX].buffer   = New-Object System.Byte[] 65535
	        $hashtable[$INDEX].encoding = New-Object System.Text.AsciiEncoding
	        $hashtable[$INDEX].STATUS     ="CONECT"

		Write-Host "Dev $INDEX / $Buffers" 
  	}
	#DEV_OPN "RERAY COM COM9:9600"
    	if( $Buffers[1] -like "COM" ){#rS232通信の場合
	        #$hashtable["VL1"] = @{Dev="COM"; COM="COM18";BAUD=9600}
	        $hashtable[$INDEX].Dev=$Buffers[1]
	        $hashtable[$INDEX].COM=$Buffers[2]
	        $hashtable[$INDEX].BAUD= [int]$Buffers[3]
	 
	        $hashtable[$INDEX].compt = New-Object System.IO.Ports.SerialPort($Buffers[2], [int]$Buffers[3])
	   	#Write-Host 1 $Buffers[0] _ $Buffers[1] _ $Buffers[2] _ $Buffers[3]
	        $hashtable[$INDEX].brcv=   New-Object byte[] 256
		$hashtable[$INDEX].ircvLen = 0

		$hashtable[$INDEX].compt.NewLine = "`r" 

	        #default:  compt.DataBits = 8
	        #default:  compt.Parity = [System.IO.Ports.Parity]::None
	        #default:  compt.StopBits = [System.IO.Ports.StopBits]::One
	        #default:  compt.DtrEnable = $false
	        #default:  compt.RtsEnable = $false
	        #default:  compt.NewLine = "" 

		$hashtable[$INDEX].compt.Open()
		Write-Host "Dev $INDEX / $Buffers" 
	        $hashtable[$INDEX].STATUS     ="CONECT"
     }
	}catch{
		Write-Host "ERR DEV_OPN" $str
	}

}


function DEV_CLS ($str){
	$Buffers = $str.split("[, :]")
	$INDEX= $Buffers[0]

    	if( $hashtable[$INDEX].Dev -like "SKT" ){
	    	$hashtable[$INDEX].writer.Close()
		$hashtable[$INDEX].stream.Close()
		$hashtable[$INDEX].STATUS     ="DISCON"
	}
    	if( $hashtable[$INDEX].Dev -like "COM" ){
		$hashtable[$INDEX].compt.Close()
		$hashtable[$INDEX].STATUS     ="DISCON"
    	}
	Write-Host "CLS_DEV" $str
}

function DEV_CLSA($str){
	foreach($entry in $hashtable.GetEnumerator()){
	    $key = $entry.Key;
            CLS_DEV $key
	}
}

function DEV_LIST{
	foreach($entry in $hashtable.GetEnumerator()){
	    $key = $entry.Key;
	    Write-Host  -NoNewline  $key`t
		foreach($entryin in $hashtable[$key].GetEnumerator()){
		    $keyin = $entryin.Key;
		    $keyv = $entryin.Value;

		　　if( $keyin -eq "Dev"){ Write-Host -NoNewline "/$keyv"  }
		　　if( $keyin -eq "IP"){ Write-Host -NoNewline "/$keyv"  }
		　　if( $keyin -eq "PORT"){ Write-Host -NoNewline "/$keyv"  }
		　　if( $keyin -eq "COM"){ Write-Host -NoNewline "/$keyv"  }
		　　if( $keyin -eq "BAUD"){ Write-Host -NoNewline "/$keyv"  }
		　　if( $keyin -eq "STATUS"){ Write-Host -NoNewline "/$keyv"  }

		    	
		}
	    　　Write-Host  "　"

	}
}


#SND_CMD "PWR,S,VOLT 12"
function SND_CMD($str){
	try{
        	$Buffers = $str.split("[, :]",3)
        	$INDEX= $Buffers[0]
        	$QorS= $Buffers[1]
        	$COMAND= $Buffers[2]
    	}catch{
        	write-host "入力形式が違います。ex:PWR,Q,VOLT?"
        	return -1
	}
	try{
	    	if( $hashtable[$INDEX].Dev -like "SKT" ){
		    	$hashtable[$INDEX].writer.WriteLine(   $COMAND   )
		    	$hashtable[$INDEX].writer.Flush()
			write-host 	$hashtable[$INDEX].ip send $COMAND
		 }
		if( $hashtable[$INDEX].Dev -like "COM" ){
			$hashtable[$INDEX].compt.WriteLine($COMAND) 
			Start-Sleep -Milliseconds 50
	    	}
	}catch{
		write-host "クローズに失敗"
        	return -1
	}	
}

#QUE_CMD "PWR,S,VOLT 12"	#
#QUE_CMD "PWR,Q,MEAS:VOLT?"	#NON_reciv
#QUE_CMD "PWR,QC,MEAS:VOLT?"	#NON_reciv
function QUE_CMD($str){
	try{
        	$Buffers = $str.split("[, :]",3)
        	$INDEX= $Buffers[0]
        	$QorS= $Buffers[1]
        	$COMAND= $Buffers[2]
    	}catch{
        	write-host "入力形式が違います。ex:PWR,Q,VOLT?"
        	return -1
	}
	try{
	    	if( $hashtable[$INDEX].Dev -like "SKT" ){

		    	$hashtable[$INDEX].writer.WriteLine(   $COMAND   )
		    	$hashtable[$INDEX].writer.Flush()
			#write-host 	$hashtable[$INDEX].ip send $COMAND
			if( $QorS[0] -like "S" ){ return }
			

			#受信中は待つ(500MS
			$time=0;
			while($hashtable[$INDEX].stream.DataAvailable -ne $true){
				start-sleep -m 500
				write-host -NoNewline　"RCV待`r"
				$time++
				if(10 -le $time ){ 
					write-host "time out 5s`n"
					return $false
				}
			}
			write-host -NoNewline　"          `r"
			$read = 0
			while($hashtable[$INDEX].stream.DataAvailable){
				$read = $hashtable[$INDEX].stream.Read($hashtable[$INDEX].buffer, 0, 65535)
				$ascii_data = $hashtable[$INDEX].encoding.GetString($hashtable[$INDEX].buffer , 0 , $read)
				$hashtable[$INDEX].STR= $ascii_data

			}
			$hashtable[$INDEX].BIN= $hashtable[$INDEX].buffer
			if( $QorS[1] -like "C" ){
				write-host $ascii_data
				return $ascii_data
			}elseif( $QorS[1] -like "B" ){
				#.bufferは\0が大量に含まれている。切り詰める
				$byteBuffer = New-Object System.Byte[] $read
				for($flg=0 ;$flg -lt $read ; $flg++){
					$byteBuffer[ $flg ] = $hashtable[$INDEX].buffer[ $flg  ]
				}
				#バイナリデータを返す
				return $byteBuffer

			}
			#return 1

		 }
		if( $hashtable[$INDEX].Dev -like "COM" ){
			$hashtable[$INDEX].compt.WriteLine($COMAND) 
			Start-Sleep -Milliseconds 50
			if( $QorS[0] -like "S" ){ return }
			
			$date = get-date		#現在時刻取得
			$dateend = $date.Addseconds(+2) #現在時刻取得+2

			while($date -le $dateend){
				$date = get-date
				if ($hashtable[$INDEX].compt.BytesToRead -gt 0){
					$srdt = $hashtable[$INDEX].compt.ReadByte()
					$hashtable[$INDEX].brcv[       $hashtable[$INDEX].ircvLen     ] = $srdt
					$hashtable[$INDEX].ircvLen++

					if ($srdt -eq 0x0a){  #LF
				        	$sr = [System.Text.Encoding]::ASCII.GetString($hashtable[$INDEX].brcv, 0, $hashtable[$INDEX].ircvLen)
				        	#Write-Host $sr
				        	$hashtable[$INDEX].brcv[  $hashtable[$INDEX].ircvLen  ] = 0x0a #LF
				        	$hashtable[$INDEX].ircvLen++
				        	#$compt.Write($brcv, 0, $ircvLen[$dev_sel_com])
				        	$hashtable[$INDEX].ircvLen = 0
						$dateend = $date
				      	}


					if ($srdt -eq 0x0d){  #CR
				        	$sr = [System.Text.Encoding]::ASCII.GetString($hashtable[$INDEX].brcv, 0, $hashtable[$INDEX].ircvLen)
				        	#Write-Host $sr
				        	$hashtable[$INDEX].brcv[  $hashtable[$INDEX].ircvLen  ] = 0x0a #LF
				        	$hashtable[$INDEX].ircvLen++
				        	#$compt.Write($brcv, 0, $ircvLen[$dev_sel_com])
				        	$hashtable[$INDEX].ircvLen = 0
						$dateend = $date
				      	}


				}
			}

			$hashtable[$INDEX].STR= $sr

			if( $QorS[1] -like "C" ){
				write-host $sr
			}else{

			}



	    	}
	}catch{
		write-host "ERR"
        	return -1
	}	
}







<#　EXLIST

QUE_CMD "PWR,S,VOLT 12" SEND_ONLY
QUE_CMD "PWR,QC,*IDN?"  write-host
QUE_CMD "PWR,Q,*IDN?"	NON write-host


DEV_OPN "PWR SKT 192.168.1.2:5025"
DEV_OPN "RERAY COM COM9:9600"
SND_CMD "PWR,Q,VOLT 12"
SND_CMD "RERAY,S,DO1 1"
SND_CMD "RERAY,S,DO1 1"
SND_CMD "RERAY,S,DO1 1"
sleep 3
DEV_CLS "PWR"
DEV_CLS "RERAY"
DEV_LIST
#>
