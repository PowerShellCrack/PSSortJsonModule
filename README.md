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

## Format-JsonOrder Parameters

- **Json** : _Required_: [String or Object] The JSON text to sort.
- **PropertyStartList** : _Optional_: [Array] The list of properties to put at the start of the json object.
- **PropertyEndList** : _Optional_: [Array] The list of properties to put at the end of the json object.
- **OnlyListedProperties** : _Optional_: [switch] Only list the properties that are in the PropertyStartList and PropertyEndList.
- **SortAlphabetically** : _Optional_: [switch] Sort the properties alphabetically.
- **Recursive** : _Optional_: [switch] Sort the properties that are arrays or objects.

> WARNING: Specifying lists  of properties that do not exist and the _-OnlyListedProperties_ parameter combined will return an empty json

## Function Alias

Sort-Json

## Parameter Alias

|parameter|alias|
|--|--|
**-PropertyStartList** | StartList, First
**-PropertyEndList** | EndList, Last
**-OnlyListedProperties** | OnlyListed
**-SortAlphabetically** | Ascending
**-Recursive** | Recurse

## Example #1

```powershell

$json = @"
{"displayName":"A test of json","policyType":"BuiltIn","mode":"Indexed","description":"A test to see if the json get ordered","metadata":{"version":"1.1.0","category":"Ordering"},"parameters":{"effect":{"type":"String","metadata":"@{displayName=Ordering; description=Order or not order that is the question}","allowedValues":"Yes No","defaultValue":"Yes"}},"policyRule":{"if":{"allOf":" "},"then":{"effect":"[parameters('order')]"}},"scopetag":["order","json","default","unorder"]}
"@

#Original JSON...
$json | ConvertFrom-Json | ConvertTo-Json -Depth 100

#Sorted JSON using pipeline...
$json | Format-JsonOrder -SortAlphabetically -Recursive
```

## Example #2

```powershell

$json = @"
{"displayName":"A test of json","policyType":"BuiltIn","mode":"Indexed","description":"A test to see if the json get ordered","metadata":{"version":"1.1.0","category":"Ordering"},"parameters":{"effect":{"type":"String","metadata":"@{displayName=Ordering; description=Order or not order that is the question}","allowedValues":"Yes No","defaultValue":"Yes"}},"policyRule":{"if":{"allOf":" "},"then":{"effect":"[parameters('order')]"}},"scopetag":["order","json","default","unorder"]}
"@

#Sorted JSON using Alias...
$json | Sort-Json -First @('policyType','displayName') -Last @('policyRule') -Ascending -Recurse
```