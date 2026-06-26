#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
<#
.SYNOPSIS
    Pester 5 tests for the SortJson module.
.DESCRIPTION
    Covers multiple JSON variations (short, deep, Microsoft Graph samples, arrays,
    null values, mixed case) and validates sorting, recursion, property ordering,
    null handling, idempotency and round-trip validity.
.EXAMPLE
    Invoke-Pester -Path .\Tests\SortJson.Tests.ps1

    Run the full suite.
.EXAMPLE
    Invoke-Pester -Path .\Tests\SortJson.Tests.ps1 -Output Detailed
#>
[CmdletBinding()]
param()

BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    $script:ManifestPath = Join-Path $script:ModuleRoot 'SortJson\SortJson.psd1'
    $script:SamplesPath = Join-Path $PSScriptRoot 'samples'

    Import-Module $script:ManifestPath -Force -ErrorAction Stop

    # Helper: confirm the output string is valid JSON (can be re-parsed)
    function Test-IsValidJson {
        param([string]$Json)
        try {
            $null = $Json | ConvertFrom-Json -ErrorAction Stop
            return $true
        }
        catch {
            return $false
        }
    }

    # Helper: get property names of a PSCustomObject in their declared order
    function Get-PropertyOrder {
        param($Object)
        return @($Object.PSObject.Properties.Name)
    }
}

Describe 'Module loading' {
    It 'imports the SortJson module' {
        Get-Module SortJson | Should -Not -BeNullOrEmpty
    }

    It 'exports <_>' -ForEach @('Format-JsonOrder', 'ConvertTo-OrderObject', 'Set-ObjectPropertyOrder') {
        (Get-Command -Module SortJson).Name | Should -Contain $_
    }

    It 'exposes the Sort-Json alias' {
        (Get-Alias Sort-Json).ResolvedCommand.Name | Should -Be 'Format-JsonOrder'
    }
}

Describe 'Sample file: <Name>' -ForEach @(
    @{ Name = 'short';                    File = 'short.json' }
    @{ Name = 'deep';                     File = 'deep.json' }
    @{ Name = 'graph-user';               File = 'graph-user.json' }
    @{ Name = 'graph-conditional-access'; File = 'graph-conditional-access.json' }
    @{ Name = 'nulls';                    File = 'nulls.json' }
    @{ Name = 'arrays';                   File = 'arrays.json' }
    @{ Name = 'mixedcase';                File = 'mixedcase.json' }
) {
    BeforeAll {
        $script:Raw = Get-Content (Join-Path $SamplesPath $File) -Raw
    }

    It 'does not throw when sorted recursively' {
        { $Raw | Format-JsonOrder -SortAlphabetically -Recursive } | Should -Not -Throw
    }

    It 'produces valid JSON output' {
        $result = $Raw | Format-JsonOrder -SortAlphabetically -Recursive
        Test-IsValidJson $result | Should -BeTrue
    }

    It 'is idempotent (sorting a sorted result yields the same output)' {
        $first  = $Raw | Format-JsonOrder -SortAlphabetically -Recursive
        $second = $first | Format-JsonOrder -SortAlphabetically -Recursive
        $second | Should -BeExactly $first
    }

    It 'preserves the original set of top-level property names' {
        $original = ($Raw | ConvertFrom-Json).PSObject.Properties.Name | Sort-Object
        $sorted   = ($Raw | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json).PSObject.Properties.Name | Sort-Object
        $sorted | Should -Be $original
    }
}

Describe 'Alphabetical sorting' {
    It 'orders top-level properties alphabetically' {
        $json = '{ "gamma": 3, "alpha": 1, "beta": 2 }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically | ConvertFrom-Json
        Get-PropertyOrder $obj | Should -Be @('alpha', 'beta', 'gamma')
    }

    It 'orders nested object properties alphabetically when -Recursive' {
        $json = '{ "outer": { "zulu": 1, "alpha": 2, "mike": 3 } }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        Get-PropertyOrder $obj.outer | Should -Be @('alpha', 'mike', 'zulu')
    }

    It 'does not reorder nested objects without -Recursive' {
        $json = '{ "outer": { "zulu": 1, "alpha": 2 } }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically | ConvertFrom-Json
        Get-PropertyOrder $obj.outer | Should -Be @('zulu', 'alpha')
    }
}

Describe 'Property start / end lists' {
    BeforeAll {
        $script:Json = '{ "middle": 1, "displayName": 2, "policyRule": 3, "name": 4 }'
    }

    It 'places PropertyStartList properties first in the given order' {
        $obj = $Json | Format-JsonOrder -PropertyStartList @('displayName', 'name') | ConvertFrom-Json
        (Get-PropertyOrder $obj)[0..1] | Should -Be @('displayName', 'name')
    }

    It 'places PropertyEndList properties last in the given order' {
        $obj = $Json | Format-JsonOrder -PropertyEndList @('policyRule') | ConvertFrom-Json
        (Get-PropertyOrder $obj)[-1] | Should -Be 'policyRule'
    }

    It 'returns only the listed properties with -OnlyListedProperties' {
        $obj  = $Json | Format-JsonOrder -PropertyStartList @('displayName') -PropertyEndList @('policyRule') -OnlyListedProperties | ConvertFrom-Json
        Get-PropertyOrder $obj | Should -Be @('displayName', 'policyRule')
    }
}

Describe 'Null handling (regression for issue #2)' {
    It 'does not throw on a null scalar property value' {
        $json = '{ "setting": null, "other": "value" }'
        { $json | Format-JsonOrder -SortAlphabetically -Recursive } | Should -Not -Throw
    }

    It 'preserves a null value as null (not an empty array)' {
        $json = '{ "managementGroupName": null, "environment": "AzureCloud" }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        $obj.managementGroupName | Should -BeNullOrEmpty
        # ensure it is not rendered as an array
        ($json | Format-JsonOrder -SortAlphabetically -Recursive) | Should -Match '"managementGroupName": null'
    }

    It 'handles the full service-endpoint sample with nested nulls' {
        $raw = Get-Content (Join-Path $SamplesPath 'nulls.json') -Raw
        $obj = $raw | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        $obj.serviceEndpointDetails.data.managementGroupName | Should -BeNullOrEmpty
    }

    It 'passes through null elements inside an array' {
        $json = '{ "items": [ null, { "b": 2, "a": 1 } ] }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        $obj.items.Count | Should -Be 2
        $obj.items[0] | Should -BeNullOrEmpty
        Get-PropertyOrder $obj.items[1] | Should -Be @('a', 'b')
    }
}

Describe 'Empty array handling' {
    It 'keeps an empty array as an empty array' {
        $json = '{ "tags": [], "name": "x" }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        , $obj.tags | Should -BeOfType [System.Array]
        $obj.tags.Count | Should -Be 0
    }

    It 'renders an empty array as [] in the output' {
        $json   = '{ "tags": [] }'
        $result = $json | Format-JsonOrder -SortAlphabetically -Recursive
        $result | Should -Match '"tags": \[\s*\]'
    }
}

Describe 'Array sorting' {
    It 'sorts a string array recursively' {
        $json = '{ "values": [ "delta", "alpha", "charlie", "bravo" ] }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        $obj.values | Should -Be @('alpha', 'bravo', 'charlie', 'delta')
    }

    It 'sorts properties of objects inside an array' {
        $json = '{ "values": [ { "name": "z", "id": 1 } ] }'
        $obj  = $json | Format-JsonOrder -SortAlphabetically -Recursive | ConvertFrom-Json
        Get-PropertyOrder $obj.values[0] | Should -Be @('id', 'name')
    }
}

Describe 'Case sensitivity' {
    BeforeAll {
        $script:Raw = Get-Content (Join-Path $SamplesPath 'mixedcase.json') -Raw
    }

    It 'sorts alphabetically (culture-aware) by default' {
        $obj   = $Raw | Format-JsonOrder -SortAlphabetically | ConvertFrom-Json
        $order = Get-PropertyOrder $obj
        # PowerShell Sort-Object is culture-aware, so ordering is alphabetical by
        # letter regardless of case; case only affects tie-breaking of identical words.
        $order | Should -Be @('Apple', 'banana', 'cherry', 'Date')
    }

    It 'ignores case when -IgnoreCaseSensitivity is supplied' {
        $obj   = $Raw | Format-JsonOrder -SortAlphabetically -IgnoreCaseSensitivity | ConvertFrom-Json
        $order = Get-PropertyOrder $obj
        # Case-insensitive: purely alphabetical regardless of case
        $order | Should -Be @('Apple', 'banana', 'cherry', 'Date')
    }
}

Describe 'Input flexibility' {
    BeforeAll {
        $script:Json = '{ "gamma": 3, "alpha": 1, "beta": 2 }'
    }

    It 'accepts a JSON string via the pipeline' {
        { $Json | Format-JsonOrder -SortAlphabetically } | Should -Not -Throw
    }

    It 'accepts a PSCustomObject via the pipeline' {
        $obj = $Json | ConvertFrom-Json
        { $obj | Format-JsonOrder -SortAlphabetically } | Should -Not -Throw
    }

    It 'accepts input via the -InputObject parameter' {
        $obj = $Json | ConvertFrom-Json
        { Format-JsonOrder -InputObject $obj -SortAlphabetically } | Should -Not -Throw
    }

    It 'produces equivalent results for string and object input' {
        $fromString = $Json | Format-JsonOrder -SortAlphabetically -Recursive
        $fromObject = ($Json | ConvertFrom-Json) | Format-JsonOrder -SortAlphabetically -Recursive
        $fromObject | Should -BeExactly $fromString
    }
}
