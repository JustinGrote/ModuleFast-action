#Version 0.0.1
using namespace System.Collections.Generic
using namespace Microsoft.PowerShell.Commands.Internal.Format

$SCRIPT:StepOutput = $env:GITHUB_STEP_SUMMARY

#Inspired by: https://gist.github.com/aaroncalderon/09a2833831c0f3a3bb57fe2224963942
<#
  .Synopsis
  Converts PowerShell Objects or Format-Table output to Markdown
#>
Function ConvertTo-Markdown {
  [CmdletBinding()]
  [OutputType([string])]
  Param (
    [Parameter(Mandatory, ValueFromPipeline)][PSObject[]]$inputObject
  )
  begin {
    $inputObjects = [List[object]]::new()
  }
  process {
    $inputObjects.Add($inputObject)
  }
  end {
    [Text.StringBuilder]$result = ''
    if ($inputObjects[0].GetType().Name -ne 'FormatStartData') {
      $inputObjects = $inputObjects | Format-Table -AutoSize -GroupBy "$(New-Guid)" # This effectively filters any grouping
    }
    if ($inputObjects.GetType().Name -contains 'GroupStartData') {
      throw [NotSupportedException]'Grouped Tables are not supported'
    }

    [string[]]$stringify = ($inputObjects | Out-String).split([Environment]::NewLine) | Where-Object length

    #We use the dash line because the line above might have spaces in property names
    $headerDashLine = $stringify[1]
    [int[]]$headerIndexes = ($headerDashLine | Select-String -Pattern '-+' -AllMatches).Matches.Index | Where-Object { $_ -ne 0 }

    foreach ($currentLine in $stringify) {
      #Escapes existing pipes that may exist so they don't break the table
      $currentLine = $currentLine -replace '\|', '\|'

      # Insert | into the string at the header indexes
      $i = 0
      foreach ($index in $headerIndexes) {
        $currentLine = $currentLine.Insert(($index + $i), ' | ')
        $i += 3
      }

      [void]$result.AppendLine("| $currentLine |")
      continue
    }
    return $result.ToString()
  }
}

class GhaEnv {
  #Thanks Copilot!
  [string]$AGENT_TOOLSDIRECTORY
  [string]$CI
  [string]$GITHUB_ACTION
  [string]$GITHUB_ACTION_PATH
  [string]$GITHUB_ACTION_REF
  [string]$GITHUB_ACTION_REPOSITORY
  [string]$GITHUB_ACTIONS
  [string]$GITHUB_ACTOR
  [string]$GITHUB_ACTOR_ID
  [string]$GITHUB_API_URL
  [string]$GITHUB_BASE_REF
  [string]$GITHUB_ENV
  [string]$GITHUB_EVENT_NAME
  [string]$GITHUB_EVENT_PATH
  [string]$GITHUB_GRAPHQL_URL
  [string]$GITHUB_HEAD_REF
  [string]$GITHUB_JOB
  [string]$GITHUB_OUTPUT
  [string]$GITHUB_PATH
  [string]$GITHUB_REF
  [string]$GITHUB_REF_NAME
  [string]$GITHUB_REF_PROTECTED
  [string]$GITHUB_REF_TYPE
  [string]$GITHUB_REPOSITORY
  [string]$GITHUB_REPOSITORY_ID
  [string]$GITHUB_REPOSITORY_OWNER
  [string]$GITHUB_REPOSITORY_OWNER_ID
  [string]$GITHUB_RETENTION_DAYS
  [string]$GITHUB_RUN_ATTEMPT
  [string]$GITHUB_RUN_ID
  [string]$GITHUB_RUN_NUMBER
  [string]$GITHUB_SERVER_URL
  [string]$GITHUB_SHA
  [string]$GITHUB_STATE
  [string]$GITHUB_STEP_SUMMARY
  [string]$GITHUB_TRIGGERING_ACTOR
  [string]$GITHUB_WORKFLOW
  [string]$GITHUB_WORKFLOW_REF
  [string]$GITHUB_WORKFLOW_SHA
  [string]$GITHUB_WORKSPACE
  [string]$RUNNER_ARCH
  [string]$RUNNER_DEBUG
  [string]$RUNNER_ENVIRONMENT
  [string]$RUNNER_NAME
  [string]$RUNNER_OS
  [string]$RUNNER_PERFLOG
  [string]$RUNNER_TEMP
  [string]$RUNNER_TOOL_CACHE
  [string]$RUNNER_TRACKING_ID
  [string]$RUNNER_USER
  [string]$RUNNER_WORKSPACE
}

function Get-GhaEnvironment {
  [OutputType([GhaEnv])]
  param()
  throw [System.NotImplementedException]'TODO: Implement this function'
  $ghaEnv = [GhaEnv]::new()
  $ghaEnv.psobject.properties | ForEach-Object {
    $PSItem.Value = Get-GhaEnvironmentVariable -Name $PSItem.Name
  }
}

function Assert-GhaEnvironment {
  if (-not $ENV:GITHUB_ACTIONS) {
    throw [NotSupportedException]'This script is not running in a GitHub Action'
  }
}

function Get-GhaEnvironmentVariable ($Name) {
  try {
    Assert-GhaEnvironment
  } catch {
    $PSItem.ErrorDetails = "To test this function outside a github action, you must first set the value with `$env:$Name = 'value'"
    throw $PSItem
  }
  return ENV:${Name}
}

function Initialize-GhaEnvironment ([switch]$Debug) {
  $GLOBAL:VerbosePreference = 'Continue'
  if ($Debug) {
    $GLOBAL:DebugPreference = 'Continue'
  }

  #Make logs more distinctive
  $GLOBAL:PSStyle.Formatting.Verbose = $PSStyle.Foreground.Cyan
  $GLOBAL:PSStyle.Formatting.Debug = $PSStyle.Foreground.Magenta
  $GLOBAL:ErrorView = 'NormalView'
  $GLOBAL:ErrorActionPreference = 'Stop'
}



filter Out-GhaTable {
  begin {
    [List[Object]]$inputObject = @()
  }
  process {
    $inputObject.Add($PSItem)
  }
  end {
    $inputObject | ConvertTo-Markdown | Write-GHAStepSummary
  }
}

filter Write-GhaStepSummary (
  [Parameter(Mandatory, ValueFromPipeline)]$InputObject,
  [switch]$NoNewLine
) {
  Out-File -InputObject $InputObject -FilePath $SCRIPT:StepOutput -Append:(!$Reset) -NoNewline:$NoNewLine
}

function Clear-GhaStepSummary {
  Remove-Item -Path $SCRIPT:StepOutput -Force -ErrorAction SilentlyContinue
}

function Write-GhaError {
  '::error file=app.js,line=1::Missing semicolon'
}
