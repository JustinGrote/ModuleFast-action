![Logo](https://github.com/JustinGrote/ModuleFast/raw/main/images/logo.gif)

# ModuleFast Github Action

ModuleFast installs PowerShell Modules in a high performance, declarative fashion, and is very useful for CI/CD scenarios for installing prerequisite modules quickly and correctly.

## How to Use


### RequiresSpec
The easiest way to use the action is to define a RequiresSpec in either json or psd1 format at `*.requires.psd1|json|jsonc`) at the root of your project.

Example:
`Modules.requires.psd1`

```powershell
@{
  'ImportExcel'      = 'latest'
  'PrereleaseTest!'  = 'latest' #The ! means prerelease versions are acceptable
  'PnP.PowerShell'   = '2.2.156-nightly'
  'PSScriptAnalyzer' = '<=1.21.0'
  'Pester'           = '=5.4.0'
  'Az.Accounts'      = ':[2.0.0, 2.13.2)'
}
```

Then you can use the ModuleFast action with no additional configuration:

```yaml
- name: ⚡ ModuleFast
  uses: JustinGrote/ModuleFast-action
```

Modulefast will install the latest versions available that meet your specifications, and cache them. By default, ModuleFast will continue to use the cached versions that met the specification at the first time of run and will not look for module updates unless your specification changes to ensure the fastest setup possible. If you want ModuleFast to check every run for newer modules, set `update: true`

### CI Lockfile

If you run Install-ModuleFast -CI locally, it will write a lock file to your repository. If you commit this lockfile, then the ModuleFast action will only install the specific modules specified in the lockfile.
