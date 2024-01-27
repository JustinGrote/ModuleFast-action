![Logo](https://github.com/JustinGrote/ModuleFast/raw/main/images/logo.gif)

# ModuleFast Github Action

ModuleFast installs PowerShell Modules in a high performance, declarative fashion, and is very useful for CI/CD scenarios for installing prerequisite modules quickly and correctly.

## How to Use

The easiest way to use the action is to define a `*.requires.psd1` (Example: `Modules.requires.psd1`) at the root of your project.

Example:

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

Modulefast will install the latest versions available that meet your specifications, and cache them. By default, ModuleFast will continue to use the cached versions that met the specification at the first time of run.
