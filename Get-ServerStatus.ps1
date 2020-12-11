function Get-ServerStatus {
<#
    .SYNOPSIS
        The Get-ServerStatus function is meant to return a general overview of a remote or local server's hardware performance
        (CPU, Memory, Network, Storage & OS information) as well as Domain Controller diagnostics if needed.
    .EXAMPLE
        Get-ServerStatus ServerName
        Display performance overview without DC health checks.
    .EXAMPLE
        Get-ServerStatus Server1,Server2 -DCHealthCheck
        Display performance overview including DCDiagnostic & Repadmin checks. Accepts multiple servers separeted by a comma (string array).
    .EXAMPLE
        Get-ADDomainController -Filter *|gss -DCHealth
        Get-ServerStatus or 'gss' allows passing arguments from pipeline, in this example it would check all the domain
        controllers on our domain.
    .EXAMPLE
        gss Server3 -Credential usercreds
        If you need to check a remote server with different credentials you can use the -Credential argument followed by your username,
        the script will ask for your credential's password as Secure String and create a new PSCredential object to authenticate with that computer.
    .NOTES
        Author: Santiago Squarzon
#>
[cmdletbinding()]
[Alias('gss')]

param(
    [parameter(parametersetname='Remote',position=0,
    ValueFromPipelinebyPropertyName,ValueFromPipeline)]
    [string[]]$Name,
    [parameter(parametersetname='Remote',position=1)][switch]$Credential,
    [parameter(parametersetname='Local',position=0)][switch]$Local,
    [parameter(mandatory=$false)]
    [switch]$DCHealthCheck
    )

begin{

$ErrorActionPreference = 'Continue'
''

try{
. "$psscriptroot\Dependencies\CPUBlock.ps1"
. "$psscriptroot\Dependencies\Invoke-PerfRemote.ps1"
. "$psscriptroot\Dependencies\LineBreak.ps1"
. "$psscriptroot\Dependencies\MemoryBlock.ps1"
. "$psscriptroot\Dependencies\NetworkBlock.ps1"
. "$psscriptroot\Dependencies\OSBlock.ps1"
. "$psscriptroot\Dependencies\StorageBlock.ps1"
. "$psscriptroot\Dependencies\DCHealthBlock.ps1"
}catch{throw 'Dependencies could not be loaded.'}

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()

} #EOF Begin Block

process {

if($name){
$Name.ForEach({
    linebreak "HOSTNAME: $($_.toupper())"
    if($credential -and $dchealtcheck.ispresent){irs $_ $credential -DCHealth}
    elseif($credential){irs $_ $credential}
    elseif($DCHealthCheck.IsPresent){irs $_ -DCHealth}
    else{irs $_}
    })
}

elseif ($local.IsPresent){

    try{. "$psscriptroot\Dependencies\Invoke-PerfLocal.ps1" -ea stop}catch{write-warning "$_";break}
    if($DCHealthCheck.IsPresent){ils -dchealth}
    else{ils}

}
''
} #EOF Process Block

end{

$elapsed.Stop()
"Execution Time: $($elapsed.elapsed.tostring('mm\:ss'))."

}

}