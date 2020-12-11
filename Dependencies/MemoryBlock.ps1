function memoryBlock ([object]$InputObject) {

$osCIMinst=$inputobject.osCIMinst

$mempages=$inputobject.mempages.where({$_}).foreach({
    [pscustomobject]@{
        Path=($_.path -replace '\\\\').ToUpper()
        CounterValue=[decimal]::round($_.cookedvalue,2)
        }
    })

$memprocs=($inputobject.memprocs|group name).foreach({[pscustomobject]@{
    Instances=$_.count
    ProcessName=$_.name
    Usage=($_.group|measure workingset -sum).sum
    }
})|sort -descending usage|select Instances,ProcessName,@{n='MemoryUsage';e={[math]::round($_.usage/1mb,2)}}|?{$_.memoryusage -gt 50}

$memavail=@(
[pscustomobject]@{
    MemoryType='Physical'
    Free=[math]::round($osCIMinst.FreePhysicalMemory/1Mb,2).tostring()+' GB'
    Total=[math]::round($osCIMinst.TotalVisibleMemorySize/1Mb,2).tostring()+' GB'
    InUse=(($osCIMinst.TotalVisibleMemorySize-$osCIMinst.FreePhysicalMemory)/$osCIMinst.TotalVisibleMemorySize).tostring('p')
    }
[pscustomobject]@{
    MemoryType='Virtual'
    Free=[math]::round($osCIMinst.FreeSpaceInPagingFiles/1Mb,2).tostring()+' GB'
    Total=[math]::round($osCIMinst.TotalVirtualMemorySize/1Mb,2).tostring()+' GB'
    InUse=(($osCIMinst.TotalVirtualMemorySize-$osCIMinst.FreeSpaceInPagingFiles)/$osCIMinst.TotalVirtualMemorySize).tostring('p')
    }
)

$top=($mempages.Count,$memprocs.Count,$memavail.Count|measure -Maximum).Maximum
if(!$top){$top=1}

$memmerge=for($i=0;$i -lt $top;$i++){

    [pscustomobject]@{
        Instances=$memprocs[$i].instances
        ProcessName=$memprocs[$i].processname
        MemoryUsage=($memprocs[$i].memoryusage).tostring()+' MB'
        ' '='|'
        Path=$mempages[$i].path
        CounterValue=$mempages[$i].countervalue
        MemoryType=$memavail[$i].memorytype
        Free=$memavail[$i].free
        Total=$memavail[$i].total
        InUse=$memavail[$i].inuse
        }
    }


$memmerge|ft -AutoSize

}