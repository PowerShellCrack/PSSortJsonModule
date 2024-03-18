Function Format-JsonOrder {
    <#
    .SYNOPSIS
        Sorts JSON output.
    .DESCRIPTION
        Reformats a JSON string so the output looks better than what ConvertTo-Json outputs.
    .PARAMETER Json
        Required: [string] The JSON text to sort.
    .PARAMETER PropertyStartList
        Optional: The list of properties to put at the start of the json object.
    .PARAMETER PropertyEndList
        Optional: The list of properties to put at the end of the json object.
    .PARAMETER OnlyListedProperties
        Optional: Only list the properties that are in the PropertyStartList and PropertyEndList.
    .PARAMETER SortAlphabetically
        Optional: Sort the properties alphabetically.
    .PARAMETER IgnoreCaseSensitivity
        Optional: Ignore casesentive ordering.
    .PARAMETER Recursive
        Optional: Sort the properties that are arrays or objects.
    .EXAMPLE
        $json | ConvertFrom-Json | Format-JsonOrder -PropertyStartList @('policyType','displayName') -PropertyEndList @('policyRule') -SortAlphabetically
    .EXAMPLE
        $json | Format-JsonOrder -PropertyStartList @('policyType','displayName') -PropertyEndList @('policyRule') -SortAlphabetically
    .EXAMPLE
        $json | Format-JsonOrder -SortAlphabetically -Recursive
    .LINK
        ConvertTo-OrderObject
        ConvertTo-Json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Json,

        [Parameter(Mandatory = $false)]
        [Alias('StartList')]
        [string[]]$PropertyStartList,

        [Parameter(Mandatory = $false)]
        [Alias('EndList')]
        [string[]]$PropertyEndList,

        [Parameter(Mandatory = $false)]
        [Alias('OnlyListed')]
        [switch]$OnlyListedProperties,

        [Parameter(Mandatory = $false)]
        [Alias('Ascending')]
        [switch]$SortAlphabetically,

        [Parameter(Mandatory = $false)]
        [Alias('CaseInSensitive')]
        [switch]$IgnoreCaseSensitivity,

        [Parameter(Mandatory = $false)]
        [Alias('Recurse')]
        [switch]$Recursive
    )
    Begin{
        ## Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        $jsonList = @()
    }
    Process{

        Foreach($JsonItem in $Json)
        {
            If($Json -is [string]){
                Write-Verbose ("{0} :: Converting json to object..." -f ${CmdletName})
                $JsonObj = ($JsonItem | ConvertFrom-Json)
            }Else{
                Write-Verbose ("{0} :: Using an object..." -f ${CmdletName})
                $JsonObj = $JsonItem
            }

            $Params = @{
                Object = $JsonObj
            }

            If($PropertyStartList.Count -gt 0){
                $Params.PropertyStartList = $PropertyStartList
            }

            If($PropertyEndList.Count -gt 0){
                $Params.PropertyEndList = $PropertyEndList
            }

            If($OnlyListedProperties -eq $true){
                $Params.OnlyListedProperties = $true
            }

            If($SortAlphabetically -eq $true){
                $Params.SortAlphabetically = $true
            }

            If($IgnoreCaseSensitivity -eq $true){
                $Params.IgnoreCaseSensitivity = $true
            }

            If($Recursive -eq $true){
                $Params.Recursive = $true
            }

            Write-Debug ("{0} :: Params: {1}" -f ${CmdletName}, ($Params | Out-String))
            $jsonList += ConvertTo-OrderObject @Params
        }
    }
    End{
        return $jsonList | ConvertTo-Json -Depth 100
    }
}

Set-Alias -Name Sort-Json -Value Format-JsonOrder