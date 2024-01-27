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
