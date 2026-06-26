function ConvertTo-OrderObject {
    <#
    .SYNOPSIS
        Sorts JSON output.
    .DESCRIPTION
        Reformats a JSON string so the output looks better than what ConvertTo-Json outputs.
    .PARAMETER InputObject
        Required: [Object] The JSON text to sort.
    .PARAMETER ReSorted
        Optional: ReSorted the json properties to the Sorted specified in the PropertyStartList and PropertyEndList parameters.
    .PARAMETER PropertyStartList
        Required: The list of properties to put at the start of the json object.
    .PARAMETER PropertyEndList
        Required: The list of properties to put at the end of the json object.
    .PARAMETER OnlyListedProperties
        Optional: Only list the properties that are in the PropertyStartList and PropertyEndList.
    .PARAMETER SortAlphabetically
        Optional: Sort the properties alphabetically.
    .EXAMPLE
        $json | ConvertFrom-Json | ConvertTo-OrderObject -PropertyStartList @('displayName','name','description','version','publisher') -PropertyEndList @('settings','assignments') -SortAlphabetically -recursive
    .EXAMPLE
        $PropertyStartList = $script:SortedProperties.firstOrder
        $PropertyEndList = $script:SortedProperties.lastOrder
        $json | ConvertFrom-Json | ConvertTo-OrderObject -PropertyStartList $PropertyStartList -PropertyEndList $PropertyEndList -SortAlphabetically
    .NOTES
        https://stackoverflow.com/questions/56322993/proper-formating-of-json-using-powershell
    .LINK
        Set-ObjectPropertyOrder
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Json','Object')]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertyStartList,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertyEndList,

        [switch]$OnlyListedProperties,

        [switch]$SortAlphabetically,

        [switch]$IgnoreCaseSensitivity,

        [switch]$Recursive
    )

    Begin{
        ## Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        $ObjList = @()
    }
    Process{
        #TEST $JsonObj = $Json | ConvertFrom-Json

        #pass through a null pipeline item (eg. [ null, {...} ]) as-is
        If($null -eq $InputObject){
            Write-Verbose ("{0} ---> Collecting null element" -f ${CmdletName})
            $ObjList += $null
            return
        }

        Foreach($JsonObj in $InputObject)
        {
            #pass through null array elements (eg. [ null, {...} ]) as-is
            If($null -eq $JsonObj){
                Write-Verbose ("{0} ---> Collecting null element" -f ${CmdletName})
                $ObjList += $null
                Continue
            }

            #reset the working lists for each object (avoids null elements and cross-iteration leakage)
            $NewPropertyStartList = @()
            $NewPropertyEndList = @()

            #only sort properties that are in the json object
            If($PropertyStartList.Count -gt 0){
                $NewPropertyStartList = @()

                $PropertyStartList | ForEach-Object {
                    If($_ -in $JsonObj.PSObject.Properties.Name){
                        $NewPropertyStartList += $_
                    }
                }

                Write-Verbose ("{0} ---> Property Start List: {1}" -f ${CmdletName}, ($NewPropertyStartList -join ", "))
            }

            If($PropertyEndList.Count -gt 0){
                $NewPropertyEndList = @()

                $PropertyEndList | ForEach-Object {
                    If($_ -in $JsonObj.PSObject.Properties.Name){
                        $NewPropertyEndList += $_
                    }
                }

                Write-Verbose ("{0} ---> Property End List: {1}" -f ${CmdletName}, ($NewPropertyEndList -join ", "))
            }

            If(($NewPropertyStartList.Count + $NewPropertyEndList.Count) -eq 0){
                Write-Verbose ("{0} ---> Properties found: {1}" -f ${CmdletName}, ($JsonObj.PSObject.Properties.Name -join ", "))
            }Else{
                $RemainingProperties = ($JsonObj | Select-Object -ExcludeProperty ($NewPropertyStartList + $NewPropertyEndList)).PSObject.Properties.Name
                Write-Verbose ("{0} ---> Remaining properties found: {1}" -f ${CmdletName}, ($RemainingProperties -join ", "))
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
                    Write-Verbose ("{0} ---> Adding first property set [{1} of {2}]: {3}" -f ${CmdletName}, $f,$NewPropertyEndList.count,$Property)

                    #add the property to the new object
                    $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force

                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Set-ObjectPropertyOrder -Object $JsonObj -Property $Property -IgnoreCaseSensitivity:$IgnoreCaseSensitivity

                        If($null -eq $JsonProperty){
                            If($null -eq $JsonObj.$Property){
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null value')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $null -Force
                            }Else{
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null array')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value @() -Force
                            }

                        }Else{
                            Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                            $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                        }

                    }Else{
                        Write-Verbose ("{0} ---> Adding remaining property: {1}" -f ${CmdletName}, $Property)
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force
                    }
                }
            }


            If( $OnlyListedProperties -ne $true )
            {
                #add the properties that are not in the start or end list
                $ExcludeList = @($PropertyStartList) + @($PropertyEndList) | Where-Object { $_ }
                If($ExcludeList.Count -gt 0){
                    $PropertyMiddleList = $JsonObj | Select-Object -ExcludeProperty $ExcludeList
                }Else{
                    $PropertyMiddleList = $JsonObj
                }

                If($SortAlphabetically -eq $true){
                    $PropertyMiddleList = $PropertyMiddleList.PSObject.Properties.Name | Sort-Object -CaseSensitive:(!$IgnoreCaseSensitivity)
                }Else{
                    $PropertyMiddleList = $PropertyMiddleList.PSObject.Properties.Name
                }

                
                ForEach($Property in $PropertyMiddleList)
                {
                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Set-ObjectPropertyOrder -Object $JsonObj -Property $Property -IgnoreCaseSensitivity:$IgnoreCaseSensitivity

                        If($null -eq $JsonProperty){
                            If($null -eq $JsonObj.$Property){
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null value')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $null -Force
                            }Else{
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null array')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value @() -Force
                            }

                        }Else{
                            Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                            $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                        }

                    }Else{
                        Write-Verbose ("{0} ---> Adding remaining property: {1}" -f ${CmdletName}, $Property)
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
                    Write-Verbose ("{0} ---> Adding last property set [{1} of {2}]: {3}" -f ${CmdletName}, $l,$NewPropertyEndList.count,$Property)

                    #add the property to the new object
                    $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force

                    #recursivly call the function to sort the properties that are arrays or objects, then update the property
                    If( ($Recursive -eq $true) -and ($SortAlphabetically -eq $true) )
                    {
                        $JsonProperty = Set-ObjectPropertyOrder -Object $JsonObj -Property $Property -IgnoreCaseSensitivity:$IgnoreCaseSensitivity

                        If($null -eq $JsonProperty){
                            If($null -eq $JsonObj.$Property){
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null value')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $null -Force
                            }Else{
                                Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, 'Null array')
                                $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value @() -Force
                            }

                        }Else{
                            Write-Verbose ("{0} ---> Adding property value: {1}" -f ${CmdletName}, $JsonProperty.Tostring())
                            $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonProperty -Force
                        }

                    }Else{
                        Write-Verbose ("{0} ---> Adding remaining property: {1}" -f ${CmdletName}, $Property)
                        $SortedObj | Add-Member -MemberType NoteProperty -Name $Property -Value $JsonObj.$Property -Force
                    }
                }

            }
            
            #add the sorted json to the list
            #$ObjList += ($SortedObj | ConvertTo-Json) -replace '\\"','"' -replace '\\r\\n','' -replace '"{','{' -replace '}"','}'
            Write-Verbose ("{0} ---> Collecting [{1}] objects" -f ${CmdletName},$SortedObj.count)
            $ObjList += $SortedObj
            #$ObjList += ($SortedObj | ConvertTo-Json)
        }        
    }
    End{
        return $ObjList
    }

}