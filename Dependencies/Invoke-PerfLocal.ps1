#Requires -RunAsAdministrator

function Invoke-LocalStatus {
[cmdletbinding()]
[Alias('ils')]
param(
    [switch]$DCHealth    
    )

if($DCHealth.IsPresent){
    $DCdiagnostic=start-job {
        C:\Windows\System32\dcdiag.exe /skip:systemlog /skip:crossrefvalidation /skip:checksdrefdom /skip:locatorcheck /skip:intersite
        }
    }

$network=@(
'\network interface(*)\bytes total/sec'
'\network interface(*)\bytes received/sec'
'\network interface(*)\bytes sent/sec'
'\network interface(*)\packets/sec'
'\network interface(*)\packets received/sec'
'\network interface(*)\packets sent/sec'
)

$mempages=@(
'\memory\pages/sec'
'\memory\page reads/sec'
'\memory\page writes/sec'
'\memory\page faults/sec'
)

$collection = @()

try{
$collection+=@{osCIMinst=Get-CimInstance win32_operatingsystem -ea Continue}
$collection+=@{timezone=Get-TimeZone -ea Continue}
$collection+=@{cpu1=Get-CimInstance Win32_processor -ea Continue}
$collection+=@{cpu2=(Get-Counter '\Processor(*)\% Processor Time' -ea Continue).CounterSamples}
$collection+=@{cpu3=(Get-Counter '\Process(*)\% Processor Time' -ea Continue).countersamples}
$collection+=@{mempages=(get-counter $mempages -ea Continue).countersamples}
$collection+=@{memprocs=get-process -ea Continue}
$collection+=@{disk=Get-WmiObject Win32_LogicalDisk -ea Continue}
$collection+=@{storage=get-disk -ea continue|select Number,FriendlyName,OperationalStatus,HealthStatus}
$collection+=@{network=(get-counter $network -ea Continue).countersamples}
$users=((quser|sls 'username|state|id|idle time|logon time|disc' 2>&1) -replace 'sessionname' -replace 'Disc','Disconnected')`
     -replace '\s{2,}',',' |ConvertFrom-Csv
$certificates=gci Cert:\LocalMachine\My|select Issuer,NotBefore,NotAfter,
    @{n='ExpiresIn';e={
        if([datetime]::Now -le $_.NotAfter -and [datetime]::Now -ge $_.NotBefore){
            $time=($_.NotAfter-[datetime]::Now).TotalDays
            if($time -gt 30){
                if($time/30 -gt 12){$t=[math]::Round($time/30/12,0).tostring();if($t -eq '1'){$t+' Year'}else{$t+' Years'}}
                else{$t=[math]::Round($time/30,0).tostring();if($t -eq '1'){$t+' Month'}else{$t+' Months'}
                }
            }
            else{$t=[math]::Round($time,0).tostring();if($t -eq '1'){$t+' Day'}else{$t+' Days'}}
        }
        else{'Expired'}
        }
     }

}catch{Write-Warning "$_"}

if($DCHealth.IsPresent){

try{
    $collection+=@{Queue=repadmin /queue}
    $collection+=@{Replication=repadmin /showreps /repsto}

    $DCdiagnostic|Wait-Job
    $collection+=@{Dcdiag=$DCdiagnostic|Receive-Job}
    $DCdiagnostic|Remove-Job
    }catch{Write-Warning "$_"}
}

$os=OSblock $collection
$cpu=CPUblock $collection
$memory=MemoryBlock $collection
$storage=StorageBlock $collection
$network=NetworkBlock $collection

''

if($os){
linebreak 'OS BLOCK'
$os
}

if($cpu){
linebreak 'CPU BLOCK'
$cpu
}

if($memory){
linebreak 'MEMORY BLOCK'
$memory
}

if($storage){
linebreak 'STORAGE BLOCK'
$storage
}

if($network){
linebreak 'NETWORK BLOCK'
$network
}

if($users){
linebreak 'DISCONNECTED SESSIONS'
$users|ft -AutoSize
}

if($certificates){
linebreak 'LOCAL CERTIFICATES'
$certificates|ft -AutoSize
}

if($healthcheck){
lineBreak 'DC HEALTH BLOCK'
$healthcheck
}

}