Function Set-ObjectPropertyOrder{
    <#
    .SYNOPSIS
        Sorts the properties of an object.
    .DESCRIPTION
        Sorts the properties of an object.
    .PARAMETER Object
        Required: [object] The object to sort.
    .PARAMETER Property
        Required: [string] The property to sort.
    .PARAMETER IgnoreCaseSensitivity
        Optional: [switch] Ignore casesentive ordering.
    .EXAMPLE
        $json | ConvertFrom-Json | Set-ObjectPropertyOrder -Property metadata
    .LINK
        ConvertTo-OrderObject
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]$Property,

        [switch]$IgnoreCaseSensitivity
    )

    If($IgnoreCaseSensitivity){
        $SortParam = @{CaseSensitive = $false}
        $OrderParam = @{IgnoreCaseSensitivity = $true;SortAlphabetically = $true;Recursive = $true}
    }else{
        $SortParam = @{CaseSensitive = $true}
        $OrderParam = @{IgnoreCaseSensitivity = $false;SortAlphabetically = $true;Recursive = $true}
    }

    ## Get the name of this function
    [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

    Write-Verbose ("{0} :: Object type: {1}" -f ${CmdletName}, $Object.GetType().Name)
    switch($Object.$Property.GetType().Name)
    {
        "String" {
            Write-Verbose ("{0} :: Adding string property: {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $Object.$Property
        }
        "Object[]" {
            If($Object.$Property -is [array]){
                Write-Verbose ("{0} :: Sorting array property: {1}" -f ${CmdletName}, $Property)

                #determine if the first item in the array is an object or string
                $PropertyType = ($object.$property | Get-Member) | Select-Object -ExpandProperty TypeName -Unique

                If( $PropertyType -eq 'System.Management.Automation.PSCustomObject'){
                    $PropertyValue = $Object.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
                }Else{
                    $PropertyValue = $Object.$Property | Sort-Object @SortParam
                }

            }Else{
                Write-Verbose ("{0} :: Sorting object property: {1}" -f ${CmdletName}, $Property)
                $PropertyValue = $Object.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
            }
        }
        'PSCustomObject' {
            Write-Verbose ("{0} :: Sorting custom object property: {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $Object.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
        }
        default {
            Write-Verbose ("{0} :: Adding unknown property type: {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $Object.$Property | Sort-Object @SortParam
        }
    }

    return $PropertyValue

}