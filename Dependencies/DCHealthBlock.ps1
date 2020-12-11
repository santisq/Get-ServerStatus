function DCHealthBlock ([array]$InputObject){

$queue=(($inputobject.Queue|out-string).trim() -replace '(\r\n){2}',';;')-split ';;'
$rep=($inputobject.replication|sls 'Inbound|Outbound|RPC|Last attempt'|out-string).trim()
$dcdiag=$inputobject.dcdiag

$in='==== INBOUND NEIGHBORS ======================================'
$out='==== OUTBOUND NEIGHBORS FOR CHANGE NOTIFICATIONS ============'

$inbound=(($rep -split $in)[1] -split $out)[1]-split '    '|%{$_.trim().where({$_.trim()})}
$outbound=($rep -split $out)[1]-split '    '|%{$_.trim().where({$_.trim()})}
$max=($inbound.count,$outbound.count|measure-object -Maximum).Maximum

$replication=for($i=0;$i -lt $max;$i++){
    [pscustomobject]@{
        'Inbound Partners'=$inbound[$i] -replace 'Last','   Last'
        'Outbound Partners'=$outbound[$i] -replace 'Last','   Last'
        Queue=$queue[$i]
        }
    }

$dcdiag=for($i=0;$i -lt $dcdiag.Count;$i++){
    $line=$dcdiag[$i]
    if($line -match 'passed test'){[pscustomobject]@{Test=$line.Substring($line.lastindexof(' ')).trim();Result='PASSED';'Error Message' = $null}}
    elseif($line -match 'failed test' -and $line){
        $msg=@()
        for($z=$i-2;$z -ge 0;$z--){
            if($dcdiag[$z] -notmatch 'starting'){
                if($dcdiag[$z]){$msg+=$dcdiag[$z].Trim() -replace '\s+',' '}
            }else{[array]::Reverse($msg);break}
        }
    [pscustomobject]@{Test=$line.Substring($line.lastindexof(' ')).trim();Result="FAILED";'Error Message' = $msg -join ' '}
    }
}


$replication|ft -AutoSize
$dcdiag|ft -AutoSize -Wrap

}