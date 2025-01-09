#連想配列の作成(GLOBAL)
#これにより、$hashtable["PWR"].socketといったような、名前を使用した配列が作成可能となります。
#デバックのための対応です。
$hashtable = @{} 


function OPN_DEV ($str){
	$Buffers = $str.split("[, :]")
	$INDEX= $Buffers[0]
	try{
	    #連想配列にキーを追加可能にします
	    #$hashtable["VH1"] = @{Dev="PWR"; IP="192.168.1.2";PORT=5025}
	    $hashtable[$INDEX]= @{} 

    	if( $Buffers[1] -like "SKT" ){  #socket通信の場合
	        $hashtable[$INDEX].socket   = New-Object System.Net.Sockets.TcpClient($Buffers[2],[int]$Buffers[3])
	        $hashtable[$INDEX].Dev      = $Buffers[1]
	        $hashtable[$INDEX].IP       = $Buffers[2]
	        $hashtable[$INDEX].PORT     = [int]$Buffers[3]

	        $hashtable[$INDEX].stream   = $hashtable[$INDEX].socket.GetStream()
	        $hashtable[$INDEX].writer   = New-Object System.IO.StreamWriter($hashtable[$INDEX].stream)
	        $hashtable[$INDEX].buffer   = New-Object System.Byte[] 1024
	        $hashtable[$INDEX].encoding = New-Object System.Text.AsciiEncoding

   	}
	#OPN_DEV "RERAY COM COM9:9600"
    	if( $Buffers[1] -like "COM" ){#rS232通信の場合
	        #$hashtable["VL1"] = @{Dev="COM"; COM="COM18";BAUD=9600}
	        $hashtable[$INDEX].Dev=$Buffers[1]
	        $hashtable[$INDEX].COM=$Buffers[2]
	        $hashtable[$INDEX].BAUD= [int]$Buffers[3]
	 
	        $hashtable[$INDEX].compt = New-Object System.IO.Ports.SerialPort($Buffers[2], [int]$Buffers[3])
	   	Write-Host 1 $Buffers[0] _ $Buffers[1] _ $Buffers[2] _ $Buffers[3]
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
     }
	}catch{
		Write-Host "ERR" $str
	}

}


function CLS_DEV ($str){
	$Buffers = $str.split("[, :]")
	$INDEX= $Buffers[0]

    	if( $hashtable[$INDEX].Dev -like "SKT" ){
	    	$hashtable[$INDEX].writer.Close()
		$hashtable[$INDEX].stream.Close()
	}
    	if( $hashtable[$INDEX].Dev -like "COM" ){
		$hashtable[$INDEX].compt.Close()
    	}
	Write-Host "CLS_DEV" $str
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
<#　EXLIST
OPN_DEV "PWR SKT 192.168.1.2:5025"
OPN_DEV "RERAY COM COM9:9600"
SND_CMD "PWR,S,VOLT 12"
SND_CMD "RERAY,S,DO1 1"
sleep 3
CLS_DEV "PWR"
CLS_DEV "RERAY"

#>
