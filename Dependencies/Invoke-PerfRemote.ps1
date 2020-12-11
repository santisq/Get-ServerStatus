function Invoke-RemoteStatus {
[cmdletbinding()]
[Alias('irs')]
param(
    [parameter(mandatory,position=0)][string]$ComputerName,
    [parameter(mandatory=$false,position=1)][string]$Credential,
    [parameter(mandatory=$false)][switch]$DCHealth
    )

$collection=@()

if($DCHealth.IsPresent){
    $DCdiagnostic=start-job {
        C:\Windows\System32\dcdiag.exe /s:$args /skip:systemlog /skip:crossrefvalidation /skip:checksdrefdom /skip:locatorcheck /skip:intersite
    } -ArgumentList $ComputerName
}

if($Credential){

<#
$user=$Credential
$passw=Read-Host -Prompt "Your password for $user here:" -AsSecureString
$cred=New-Object System.Management.Automation.PSCredential ($user,$passw)
#>
$cred=Get-Credential

#if($passw -and $user){
    try{$session = New-PSSession $computername -Credential $cred -ea stop}
    catch{Write-Warning "$_";break}
  #  }
 #   else{break}
}

else{
    try{$session = New-PSSession $computername -ea stop}
    catch{Write-Warning "$_";break}
    }

$collection+=icm $session {

$ErrorActionPreference='Continue'

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

@{osCIMinst=Get-CimInstance win32_operatingsystem}
@{timezone=Get-TimeZone}
@{cpu1=Get-CimInstance Win32_processor}
@{cpu2=(Get-Counter '\Processor(*)\% Processor Time' 2>$null).CounterSamples}
@{cpu3=(Get-Counter '\Process(*)\% Processor Time' 2>$null).countersamples}
@{mempages=(get-counter $mempages 2>$null).countersamples}
@{memprocs=get-process}
@{disk=Get-WmiObject Win32_LogicalDisk}
@{storage=get-disk|select Number,FriendlyName,OperationalStatus,HealthStatus}
@{network=(get-counter $network).countersamples}
@{certificates=gci Cert:\LocalMachine\My|select Issuer,NotBefore,NotAfter}

if($using:DCHealth.IsPresent){

    try{
        @{Queue=repadmin /queue}
        @{Replication=repadmin /showreps /repsto}
    }catch{Write-Warning "$_"}
}

}#EOF ICM

if($dchealth.IsPresent){
    $collection+=@{Dcdiag=$DCdiagnostic|Wait-Job|Receive-Job}
    Remove-Job $DCdiagnostic
    $healthcheck=DCHealthBlock $collection
}

$session|Remove-PSSession

$os=OSblock $collection
$cpu=CPUblock $collection
$memory=MemoryBlock $collection
$storage=StorageBlock $collection
$network=NetworkBlock $collection
$users=((quser /server:$computername 2>&1 |sls 'username|state|id|idle time|logon time|disc') -replace 'sessionname' -replace 'Disc','Disconnected')`
     -replace '\s{2,}',',' |ConvertFrom-Csv
$certificates=$collection.certificates|select Issuer,NotBefore,NotAfter,
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