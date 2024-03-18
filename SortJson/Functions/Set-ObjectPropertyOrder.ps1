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
        [string]$Property
    )

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
                #detemine if the frist item in the array is an object or string
                $PropertyType = ($object.$property | Get-Member) | Select -ExpandProperty TypeName -Unique
                If( $PropertyType -eq 'System.Management.Automation.PSCustomObject'){
                    $PropertyValue = $Object.$Property | ConvertTo-OrderObject -SortAlphabetically -Recursive -Verbose:$VerbosePreference
                }Else{
                    $PropertyValue = $Object.$Property | Sort-Object
                }

            }Else{
                Write-Verbose ("{0} :: Sorting object property: {1}" -f ${CmdletName}, $Property)
                $PropertyValue = $Object.$Property | ConvertTo-OrderObject -SortAlphabetically -Recursive -Verbose:$VerbosePreference
            }
        }
        'PSCustomObject' {
            Write-Verbose ("{0} :: Sorting custom object property: {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $Object.$Property | ConvertTo-OrderObject -SortAlphabetically -Recursive -Verbose:$VerbosePreference
        }
        default {
            Write-Verbose ("{0} :: Adding unknown property type: {1}" -f ${CmdletName}, $Property)
            $PropertyValue = $Object.$Property | Sort-Object
        }
    }

    return $PropertyValue
    
}