function NetworkBlock ([object]$InputObject) {

$network=$inputobject.network.where({$_.cookedvalue -gt 0}).foreach({
    if($_.path -match 'bytes'){$val=[math]::round($_.cookedvalue/125000,2).tostring()+' Mbps'}
    else{$val=[math]::round($_.cookedvalue,2).tostring()+' p/s'}
    [pscustomobject]@{
        Path=($_.path -replace '\\\\').toupper()
        CounterValue=$val
        }
    })

$network|ft -autosize

}