function OSblock ([object]$InputObject,[switch]$Remote) {

if($Remote.IsPresent){$time=net time \\$($inputobject.osCIMinst.csname)}
else{$time=net time}

$timezone=$inputobject.timezone

$osinfo=$inputobject.osCIMinst| select @{n='OperatingSystem';e='Caption'},LastBootUptime,
            @{n='ServerTime';e={if($time -match 'local'){(($time|sls 'local') -replace '\?' -split 'is ')[1]}
            else{(($time|sls 'current') -replace '\?' -split 'is ')[1]}}},@{n='TimeZone';e={($timezone|select @{n='TimeZone'
            e={@("$($_.DisplayName)`n$($_.StandardName)")}}).timezone}}

$osinfo|ft -AutoSize -Wrap
}