function lineBreak ([string]$Title){

$len=$title.Length
$line1=45
$line2=1
$break='='*$line1+"| $title |"+'='*$line2
while($break.Length -lt 125){$line2++;$break='='*$line1+"| $title |"+'='*$line2}

return $break
}