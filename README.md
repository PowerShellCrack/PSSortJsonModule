# PSSortJsonModule

A simple module that will reorder a json keys in alphabetical order

## Install

```powershell
Install-Module SortJson -Force
```

## Cmdlets

- **Format-JsonOrder** : Primary caller
- **ConvertTo-OrderObject** : Called when using _Format-JsonOrder_ but can be used separately
- **Set-ObjectPropertyOrder** : Called when using _ConvertTo-OrderObject_ but can be used separately

## Alias

Sort-Json

## Example #1

```powershell

$json = @"
{"displayName":"A test of json","policyType":"BuiltIn","mode":"Indexed","description":"A test to see if the json get ordered","metadata":{"version":"1.1.0","category":"Ordering"},"parameters":{"effect":{"type":"String","metadata":"@{displayName=Ordering; description=Order or not order that is the question}","allowedValues":"Yes No","defaultValue":"Yes"}},"policyRule":{"if":{"allOf":" "},"then":{"effect":"[parameters('order')]"}},"scopetag":["order","json","default","unorder"]}
"@

Write-Host "Original JSON..." -ForegroundColor Green
$json | ConvertFrom-Json | ConvertTo-Json -Depth 100

Write-Host "Sorted JSON using pipeline..." -ForegroundColor Green
$json | Format-JsonOrder -SortAlphabetically -Recursive
```

## Example #2
```powershell

$json = @"
{"displayName":"A test of json","policyType":"BuiltIn","mode":"Indexed","description":"A test to see if the json get ordered","metadata":{"version":"1.1.0","category":"Ordering"},"parameters":{"effect":{"type":"String","metadata":"@{displayName=Ordering; description=Order or not order that is the question}","allowedValues":"Yes No","defaultValue":"Yes"}},"policyRule":{"if":{"allOf":" "},"then":{"effect":"[parameters('order')]"}},"scopetag":["order","json","default","unorder"]}
"@

Write-Host "Sorted JSON using pipeline..." -ForegroundColor Green
$json | Format-JsonOrder -PropertyStartList @('policyType','displayName') -PropertyEndList @('policyRule') -SortAlphabetically -Recursive
```