$ModuleRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]

$fileList = (Get-ChildItem -Path "$ModuleRoot\Functions" -Filter '*.ps1')

foreach ($file in $fileList  ) {
    Write-Verbose "Loading $($file.FullName)"
    . $file.FullName
}
