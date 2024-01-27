param(
  $bootstrapParams,
  $imfParams,
  $Debug
)
Import-Module $PSScriptRoot/GHAUtil.psm1
Initialize-GhaEnvironment -Debug:$Debug

Write-GhaError

Write-Debug 'Env and Variables'
Write-Debug '================'
Get-ChildItem env: | Format-Table | Out-String | Write-Debug
Write-Debug '================'
Get-Variable | Format-Table | Out-String | Write-Debug
Write-Debug '================'

Write-Debug 'Bootstrapping Modulefast'
#Bootstrap the ModuleFast module
. $PSScriptRoot\ModuleFast.ps1 @bootstrapParams

if ($imfParams.Specification -and $imfParams.Path) {
  throw [ArgumentException]'Cannot specify both a path and a specification. Choose one.'
}

#Process the GHA input string into an array. This is a workaround for the fact that GitHub Actions doesn't support arrays as inputs
if ($imfParams.Specification) {
  $imfParams.Specification = $imfParams.Specification -split '\s+' | Where-Object { $PSItem } | ForEach-Object Trim
}

$imfCommonParams = @{
  OutVariable = 'installedModules'
  PassThru    = $true
  Debug       = $Debug
  Verbose     = $true
}

Install-ModuleFast @imfParams @imfCommonParams @args

if ($installedModules) {
  '### ModuleFast Installed Modules :rocket:' | Write-GhaStepSummary
  $installedModules | Out-GhaTable
}
