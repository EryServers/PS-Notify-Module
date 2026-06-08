
<#
.SYNOPSIS
    
.NOTES
    Author: Eryniox
    Date:   June 2025
.LINK
    https://github.com/EryServers/
#>

#region Classes
class EryISOTime {
  static [string] ms() { Return ( [EryISOTime]::Milliseconds() ) }
  static [string] Milliseconds() {
    Return ( ([datetime]::Now).ToString("yyyy-MM-ddTHH:mm:ss.fff", [System.Globalization.CultureInfo]::InvariantCulture) )
  }
  static [string] sec() { Return ( [EryISOTime]::Seconds() ) }
  static [string] Seconds() {
    Return ( ([datetime]::Now).ToString("yyyy-MM-ddTHH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) )
  }
  static [string] min() { Return ( [EryISOTime]::Minutes() ) }
  static [string] Minute() {
    Return ( ([datetime]::Now).ToString("yyyy-MM-ddTHH:mm", [System.Globalization.CultureInfo]::InvariantCulture) )
  }
  static [string] Date() {
    Return ( ([datetime]::Now).ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture) )
  }
} # [EryISOTime]::ms() ; [EryISOTime]::Milliseconds(); [EryISOTime]::sec(); [EryISOTime]::Date()

class EryLog {
  # Properties
  static [version] $Version = [version]"1.2.0"
  [array]  $LogEntries = @()
  [string] $LogStart = [EryISOTime]::ms()
  [bool]   $AddTimeStamp = $true

  # Hidden Property-methods
  hidden $__class_init__ = $(
    $this | Add-Member -MemberType ScriptProperty -Name 'Message' -Value { # get
        return ( $this.GetMessage() )
      } -SecondValue { param ( $arg )
        $this.AddMessage($arg)
      } # set
    $this | Add-Member -MemberType ScriptProperty -Name 'MessageArray' -Value { # get
        return @( $this.LogEntries | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.content } )
      }
  )
  
  # Methods
  [void] AddMessage([string]$message) {
    if ($this.AddTimeStamp) { $message = [EryISOTime]::ms() + " - " + $message }
    $this.LogEntries += @{ type = "text"; content = $message }
  }
  [void] AddTable([object[]]$data) {
    $this.LogEntries += @{ type = "table"; content = $data; properties = @() }
  }
  [void] AddTable([object[]]$data, [string[]]$properties) {
    $this.LogEntries += @{ type = "table"; content = $data; properties = $properties }
  }

  [string] GetMessage() {
    $parts = @()
    foreach ($entry in $this.LogEntries) {
      if ($entry.type -eq "text") {
        $parts += $entry.content
      } elseif ($entry.type -eq "table") {
        if ($entry.properties -and $entry.properties.Count -gt 0) {
          $parts += ($entry.content | Select-Object -Property $entry.properties | Format-Table -AutoSize | Out-String).Trim()
        } else {
          $parts += ($entry.content | Format-Table -AutoSize | Out-String).Trim()
        }
      }
    }
    return ($parts -join "`r`n")
  }

  [void] AddFailedMessage([string]$message)   { $this.AddMessage("❌ - " + $message) }
  [void] AddSuccessMessage([string]$message)  { $this.AddMessage("✅ - " + $message) }

  [void] ReplayToMailLog([object]$mailLog) {
    foreach ($entry in $this.LogEntries) {
      if ($entry.type -eq "text") {
        $mailLog.AddMessage($entry.content)
      } elseif ($entry.type -eq "table") {
        if ($entry.properties -and $entry.properties.Count -gt 0) {
          $mailLog.AddTable($entry.content, $entry.properties)
        } else {
          $mailLog.AddTable($entry.content)
        }
      }
    }
  }

} # $Logging = [EryLog]::new(); $Logging.AddMessage("Test message"); $Logging.Message

#endregion Classes

Function New-EryLog {
  <#
  .SYNOPSIS
      Creates a new EryLog object for logging messages with timestamps.
  .OUTPUTS
      EryLog
  .EXAMPLE
      $log = New-EryLog
      $log.AddMessage("This is a log message.")
  #>
  Param ()
  Return [EryLog]::new()
}

Function Get-EryLogVersion {
  <#
  .SYNOPSIS
      Returns the version of the EryLog class currently loaded in memory.
  .DESCRIPTION
      Reads the version directly from the [EryLog] type, so it reflects the
      actual class definition in the runspace (not just the reloaded module file).
      Useful for verifying which version is running, especially in long-lived
      runspaces where Import-Module -Force does not redefine PowerShell classes.
  .OUTPUTS
      version
  .EXAMPLE
      Get-EryLogVersion
  #>
  Param ()
  Return [EryLog]::Version
}

Function Get-EryISOTime {
  <#
  .SYNOPSIS
    Provides current date and time in ISO 8601 format.
  .OUTPUTS
    string
  .EXAMPLE
    $currentTime = Get-EryISOTime -Format "ms"
  #>
  Param (
    [ValidateSet("ms", "sec", "min", "Date", "Milliseconds", "Seconds", "Minute", IgnoreCase=$true)]
    [string]$Format = "sec"
  )
  Switch ($Format) {
    "ms"   { Return [EryISOTime]::Milliseconds() }
    "sec"  { Return [EryISOTime]::Seconds() }
    "min"  { Return [EryISOTime]::Minute() }
    "Date" { Return [EryISOTime]::Date() }
    "Milliseconds" { Return [EryISOTime]::Milliseconds() }
    "Seconds"      { Return [EryISOTime]::Seconds() }
    "Minute"       { Return [EryISOTime]::Minute() }
  }
}
