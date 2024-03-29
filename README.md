![Logo](https://github.com/JustinGrote/ModuleFast/raw/main/images/logo.gif)

# ModuleFast Github Action

[ModuleFast](https://github.com/JustinGrote/ModuleFast) installs PowerShell Modules in a high performance, declarative fashion, and is very useful for CI/CD scenarios for installing prerequisite modules quickly and correctly. It will install modules based on your specifications, provide you with a report of what was installed, and cache installed modules for future runs.

![alt text](images/README/image-1.png)

## How to Use

### RequiresSpec

The easiest way to use the action is to define a [RequiresSpec](https://github.com/JustinGrote/ModuleFast/blob/1dfe7d67caa45b1fefd3db5ec84d25ad895b94ed/ModuleFast.psm1#L55) in either json or psd1 format at `*.requires.psd1|json|jsonc` at the root of your project.

Example:
`Modules.requires.psd1`

```powershell
@{
  'ImportExcel'      = 'latest'
  'PrereleaseTest!'  = 'latest' #The ! means prerelease versions are acceptable
  'PnP.PowerShell'   = '2.2.156-nightly'
  'PSScriptAnalyzer' = '<=1.21.0'
  'Pester'           = '=5.4.0'
  'Microsoft.PowerShell.PSResourceGet' = ':1.*' #All 1.x versions, will not install a 2.x version
  'Az.Accounts'      = ':[2.0.0, 2.13.2)' #Install versions including 2.0.0 but only up to 2.13.1
}
```

Then you can use the ModuleFast action with no additional configuration:

```yaml
- name: ⚡ Install PowerShell Modules
  uses: JustinGrote/ModuleFast-action
```

Modulefast will install the latest versions available that meet your SpecFile requirements, and cache them. By default, ModuleFast will continue to use the cached versions that met the specification at the first time of run and will not look for module updates unless your specification changes to ensure the fastest setup possible. If you want ModuleFast to check every run for newer modules, set `update: true`.

### Module or Script with Requires

If you have a module manifest with a `RequiredModules` entry or a script with a `#requires -Module modulename` line, you can specify that with the `path` option to install the modules as specified by that requirement.

`MyScript.ps1`

```powershell
#requires -module ImportExcel, @{ModuleName='PowerShellAI'; ModuleVersion='0.9.4'}
dir env: | export-excel TEMP:\envstuff.xlsx
```

```yaml
- name: ⚡ ModuleFast - Install Script Requires
  uses: JustinGrote/ModuleFast-action
  with:
    path: MyScript.ps1
```

### Specification

You can choose to specify your dependencies directly in the github action. Specifications must use the shorthand ModuleFast syntax and be whitespace/line separated. It is recommended to use the YAML block line format to specify modules:

```yaml
- name: ⚡ ModuleFast with Specification
  uses: JustinGrote/ModuleFast-action
  with:
    specification: |
      ImportExcel
      PrereleaseTest! #The ! means prerelease versions are acceptable
      PnP.PowerShell=2.2.156-nightly
      PSScriptAnalyzer<=1.21.0
      Pester=5.4.0
      Az.Accounts:[2.0.0, 2.13.2)
```

### CI Lockfile

If you run Install-ModuleFast -CI locally, it will write a lock file to your repository. If you commit this lockfile, then the ModuleFast action will only install the specific modules specified in the lockfile if it is detected.

### Pinning a ModuleFast Release Version

ModuleFast by default will run with the latest released version on GitHub. It is strongly recommended however that you
pin your ModuleFast to a specific version to avoid breaking changes. The release tag is usually prefixed with a v e.g. "v0.2.0" instead of "0.1.0"

```yaml
- name: ⚡ ModuleFast with Specification
  uses: JustinGrote/ModuleFast-action
  with:
    release: v0.2.0
```

### Using the latest development version

In the other direction, if you need a fix that has not been released yet or otherwise want to test the bleeing edge of
ModuleFast, specify 'main' for the release version to use the latest main commit. You can specify other branches in this
way for feature testing as well.

```yaml
- name: ⚡ ModuleFast with Specification
  uses: JustinGrote/ModuleFast-action
  with:
    release: main
```

### Troubleshooting

Modulefast reports information about what it is doing and its results normally. For highly detailed information, rerun a job with [debug logging enabled](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging) to see more information.

![Enable ModuleFast Debugging](images/README/image.png)
