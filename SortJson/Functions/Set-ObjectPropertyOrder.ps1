Function Set-ObjectPropertyOrder{
    <#
    .SYNOPSIS
        Sorts the properties of an object.
    .DESCRIPTION
        Sorts the properties of an object.
    .PARAMETER InputObject
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
        [Alias('Json','Object')]
        $InputObject,

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

    #Write-Verbose ("{0} -> Object type: {1}" -f ${CmdletName}, $InputObject.GetType().Name)
    switch($InputObject.$Property.GetType().Name)
    {
        "String" {
            Write-Verbose ("{0} -> Adding property: [string] {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $InputObject.$Property
        }
        "Object[]" {
            If($InputObject.$Property -is [array])
            {
                If($InputObject.$Property.count -eq 0)
                {
                    Write-Verbose ("{0} -> Adding property: [array] {1}" -f ${CmdletName}, $Property)
                    $PropertyValue = $null
                
                }Else{
                    Write-Verbose ("{0} -> Sorting property: [array] {1}" -f ${CmdletName}, $Property)

                    #determine if the first item in the array is an object or string
                    $PropertyType = ($InputObject.$property | Get-Member) | Select-Object -ExpandProperty TypeName -Unique

                    If( $PropertyType -eq 'System.Management.Automation.PSCustomObject'){
                        $PropertyValue = $InputObject.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
                    }Else{
                        $PropertyValue = $InputObject.$Property | Sort-Object @SortParam
                    }
                }
            }Else{
                Write-Verbose ("{0} -> Sorting property: [object] {1}" -f ${CmdletName}, $Property)
                $PropertyValue = $InputObject.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
            }
        }
        'PSCustomObject' {
            Write-Verbose ("{0} -> Sorting property: [custom object] {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $InputObject.$Property | ConvertTo-OrderObject @OrderParam -Verbose:$VerbosePreference
        }
        default {
            Write-Verbose ("{0} -> Adding property: [unknown] {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $InputObject.$Property | Sort-Object @SortParam
        }
    }

    return $PropertyValue

}