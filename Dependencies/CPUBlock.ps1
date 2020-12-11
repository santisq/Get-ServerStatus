function CPUblock ([object]$InputObject) {

$cpu1=$inputobject.cpu1 |
        select DeviceID,Name,@{n='Cores';e='NumberOfCores'},
        @{n='LogicalProcessors';e='NumberOfLogicalProcessors'},@{n='Load';e={($_.loadpercentage/100).tostring('P')}},Status

$cpu2=$inputobject.cpu2 |
            select @{n='Path';e={($_.path -replace '\\\\').toupper()}}, @{n='Instance';e='InstanceName'},
                   @{N='Load';e={($_.cookedvalue/100).tostring('P')}}

$cpu3=($inputobject.cpu3 |sort cookedvalue -descending|
        group instancename).foreach({[pscustomobject]@{
                processCount=$_.count
                processName=$_.name
                usage=($_.group|measure cookedvalue -sum).sum
                }
            })|sort -descending usage|?{$_.usage -gt 0}

$top=($cpu2.count,$cpu3.count|measure -Maximum).Maximum
if(!$top){$top=1}

$cpumerge=for($i=0;$i -lt $top;$i++){

    [pscustomobject]@{
        Instances=$cpu3[$i].processcount
        ProcessName=$cpu3[$i].processname
        Usage=$(if($cpu3[$i].usage){(($cpu3[$i].usage/100)/($cpu1.logicalprocessors|measure -Sum).sum).tostring('p')})
        ' '='|'
        Path=$cpu2[$i].path
        Instance=$cpu2[$i].instance
        Load=$cpu2[$i].load
        }
    }

$cpu1|ft -AutoSize;$cpumerge|ft -AutoSize

}