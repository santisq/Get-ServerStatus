$timeObj=w32tm /monitor

$timeResult=$(

for($i=0;$i -lt $timeObj.count;$i++){
    
    if($timeObj[$i] -match 'NTP:'){
        
        $Source=$timeObj[$i-2].ToUpper()
        $DC=$Source.Split('.')[0].trim()
        $IP=($Source.Split('[')[1] -split ':')[0].trim()
        switch -Wildcard ($timeObj[$i]){
            '*Error*'{$Offset=(($timeObj[$i] -split 'error\s')[1] -split '\s')[0].trim()}
            Default{$Offset=($timeObj[$i].split('\s:')[1] -split '\s')[1].trim()}
        }

        [pscustomobject]@{
            DomainController=$DC
            'IP Address'=$IP
            TimeOffset=$Offset
            }
        }
    }

) | sort TimeOffset