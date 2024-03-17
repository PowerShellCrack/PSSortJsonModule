function ConvertTo-OrderObject {
    <#
    .SYNOPSIS
    Convert a object to a new ordered object
    .DESCRIPTION
    Convert a object to a new object with the properties sorted in alphabetical order.
    .PARAMETER Object
    The object to convert
    .PARAMETER PropertyStartList
    The list of properties to put at the start of the object
    .PARAMETER PropertyEndList
    The list of properties to put at the end of the object
    .PARAMETER OnlyListedProperties
    Only include the properties listed in the PropertyStartList and PropertyEndList
    .PARAMETER SortAlphabetically
    Sort the properties in alphabetical order
    .PARAMETER Recursive
    Sort the properties that are arrays or objects
    .EXAMPLE
    ConvertTo-OrderObject -Object $JsonObj -PropertyStartList @("Name","Age") -PropertyEndList @("Address","Phone")
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Object,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertyStartList,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertyEndList,

        [switch]$OnlyListedProperties,

        [switch]$SortAlphabetically,

        [switch]$Recursive
    )

    Begin{
        ## Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        $ObjList = @()
    }
    Process{
        Foreach($JsonObj in $Object)
        {

            #only sort properties that are in the json object
            If($PropertyStartList.Count -gt 0){
                $NewPropertyStartList = @()

                $PropertyStartList | ForEach-Object {
                    If($_ -in $JsonObj.PSObject.Properties.Name){
                        $NewPropertyStartList += $_
                    }
                }

                Write-Verbose ("{0} :: Property Start List: {1}" -f ${CmdletName}, ($NewPropertyStartList -join ", "))
            }
            
            If($PropertyEndList.Count -gt 0){
                $NewPropertyEndList = @()

                $PropertyEndList | ForEach-Object {
                    If($_ -in $JsonObj.PSObject.Properties.Name){
                        $NewPropertyEndList += $_
                    }
                }

                Write-Verbose ("{0} :: Property End List: {1}" -f ${CmdletName}, ($NewPropertyEndList -join ", "))
            }

            If(($NewPropertyStartList.Count + $NewPropertyEndList.Count) -eq 0){
                Write-Verbose ("{0} :: Properties found: {1}" -f ${CmdletName}, ($JsonObj.PSObject.Properties.Name -join ", "))
            }Else{
                $RemainingProperties = ($JsonObj | Select-Object -ExcludeProperty ($NewPropertyStartList + $NewPropertyEndList)).PSObject.Properties.Name
                Write-Verbose ("{0} :: Remaining properties found: {1}" -f ${CmdletName}, ($RemainingProperties -join ", "))
            }
            

            #build a new object in the Sorted we want
            $SortedObj = New-Object PSObject

            #split the json object into 3 parts
            #start properties, middle properties, and end properties

            #add the start properties
            If($NewPropertyStartList.count -gt 0)
            {
                $f=0
                ForEach($Property in $NewPropertyStartList)
                {
                    $f++
                    Write-Verbose ("{0} :: Adding first property set [{1} of {2}]: {3}" -f ${CmdletName}, $f,$NewPropertyEndList.count,$Property)
                    
                    #add the property to the new object
                    $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force

                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Get-ObjectPropertyOrder -Object $JsonObj -Property $Property

                        Write-Verbose ("{0} :: Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                    
                    }Else{
                        Write-Verbose ("{0} :: Adding remaining property: {1}" -f ${CmdletName}, $Property)
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force
                    }
                }
            }

            
            If( $OnlyListedProperties -ne $true )
            {
                #add the properties that are not in the start or end list
                $PropertyMiddleList = $JsonObj | Select-Object -ExcludeProperty ($PropertyStartList + $PropertyEndList)
                
                If($SortAlphabetically -eq $true){
                    $PropertyMiddleList = $PropertyMiddleList.PSObject.Properties.Name | Sort-Object
                }Else{
                    $PropertyMiddleList = $PropertyMiddleList.PSObject.Properties.Name
                }

                ForEach($Property in $PropertyMiddleList)
                {
                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Get-ObjectPropertyOrder -Object $JsonObj -Property $Property

                        Write-Verbose ("{0} :: Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                    
                    }Else{
                        Write-Verbose ("{0} :: Adding remaining property: {1}" -f ${CmdletName}, $Property)
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force
                    }
                }
                
            }
            
            #add the end properties
            If($NewPropertyEndList.count -gt 0)
            {                
                $l=0
                Foreach($Property in $NewPropertyEndList)
                {
                    $l++
                    Write-Verbose ("{0} :: Adding last property set [{1} of {2}]: {3}" -f ${CmdletName}, $l,$NewPropertyEndList.count,$Property)
                    
                    #add the property to the new object
                    $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force

                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Get-ObjectPropertyOrder -Object $JsonObj -Property $Property

                        Write-Verbose ("{0} :: Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                    
                    }Else{
                        Write-Verbose ("{0} :: Adding remaining property: {1}" -f ${CmdletName}, $Property)
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force
                    }
                }
    
            }
        }
        
        #add the sorted json to the list
        #$ObjList += ($SortedObj | ConvertTo-Json) -replace '\\"','"' -replace '\\r\\n','' -replace '"{','{' -replace '}"','}'
        Write-Verbose ("{0} :: Collecting objects..." -f ${CmdletName})
        $ObjList += $SortedObj
        #$ObjList += ($SortedObj | ConvertTo-Json) 
    }
    End{
        Write-Verbose ("{0} :: Returning object..." -f ${CmdletName})
        return $ObjList
    }
    
}