# Change log for SortJson

## 1.0.6 June 26, 2026

- Fixed crash when a property value is `null` (eg. `"setting": null`); `Set-ObjectPropertyOrder` no longer calls `.GetType()` on a null value. Thanks @boozeman
- Preserve genuine `null` values instead of converting them to empty arrays.
- Pass through `null` elements inside arrays (eg. `[ null, {...} ]`) instead of dropping them or erroring.
- Fixed error when using `-PropertyStartList`/`-PropertyEndList` individually (null element passed to `Select-Object -ExcludeProperty`).
- Added Pester 5 test suite (`Tests/SortJson.Tests.ps1`) with sample fixtures covering short, deep, Microsoft Graph, array, null and mixed-case JSON.

## 1.0.5 July 12, 2024

- Fixed issue with null arrays being removed and stops sorting json. Thanks @kaiaschulz
- Updated verbose and debug outputs; cleaned up. 
- Used best practice for object; set params to: inputObject

## 1.0.4 March 18, 2024

- Enforced CaseSensitivity on arrays and objects. Added parameter to Ignore case
- Fixed PSScriptAnalyzer problems. Removed empty spaces.

## 1.0.3 March 18, 2024

- Add the ability to check for objects within array for ordering

## 1.0.2 March 18, 2024

- Added Alias to make function simpler

## 1.0.1 March 17, 2024

- Fixed Get-ObjectPropertyValue to Get-ObjectPropertyValue

## 1.0.0 March 17, 2024

- Initial release
