function StorageBlock ([object]$InputObject) {

$disk=$inputobject.disk|?{$_.driveType -eq 3}|select DeviceID,DriveType,@{n='FreeSpace';e={[math]::round($_.FreeSpace /1Gb,2).tostring()+' GB'}},
        @{n='Size';e={[math]::round($_.Size/1Gb,2).tostring()+' GB'}},@{n='Used';e={(($_.size-$_.freespace)/$_.size).tostring('p')}}

$storage=$inputobject.storage

$top=($disk.Count,$storage.Count|measure -Maximum).Maximum
if(!$top){$top=1}

$diskmerge=for($i=0;$i -lt $top;$i++){
    [pscustomobject]@{
        Number=$storage[$i].number
        FriendlyName=$storage[$i].friendlyname
        OperationalStatus=$storage[$i].OperationalStatus
        HealthStatus=$storage[$i].HealthStatus
        DeviceID=$disk[$i].deviceid
        DriveType=$disk[$i].DriveType
        FreeSpace=$disk[$i].freespace
        Size=$disk[$i].size
        Used=$disk[$i].used
        }
    }

$diskmerge|ft -AutoSize

}