# Get-ServerStatus
 
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