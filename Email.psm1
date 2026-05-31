<#
.SYNOPSIS
    Class and functions for composing and sending emails.
.NOTES
    Author: Eryniox
    Date:   April 2026
.LINK
    https://github.com/EryServers/
#>

#region Classes

class EryMailLog {
    # Properties
    [string]   $SmtpServer
    [string[]] $Recipients
    [string]   $From
    [string]   $Subject
    [bool]     $IsHtml   = $true
    [string]   $TableCss = "<style>TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}</style>"

    hidden [array] $BodyParts = @()

    # Constructors
    EryMailLog() {}
    EryMailLog([string]$smtpServer, [string[]]$recipients, [string]$from, [string]$subject) {
        $this.SmtpServer = $smtpServer
        $this.Recipients = $recipients
        $this.From       = $from
        $this.Subject    = $subject
    }

    # Methods
    [void] AddMessage([string]$message) {
        $this.BodyParts += @{ type = "text"; content = $message }
    }

    [void] AddTable([object[]]$data) {
        $this.IsHtml = $true
        $html = $data | ConvertTo-Html -Fragment -PostContent "<br />" | Out-String
        $this.BodyParts += @{ type = "html"; content = $html }
    }
    [void] AddTable([object[]]$data, [string[]]$properties) {
        $this.IsHtml = $true
        $html = $data | Select-Object -Property $properties | ConvertTo-Html -Fragment -PostContent "<br />" | Out-String
        $this.BodyParts += @{ type = "html"; content = $html }
    }

    [string] GetBody() {
        if (-not $this.IsHtml) {
            return ($this.BodyParts | ForEach-Object { $_.content }) -join "`r`n"
        }
        # HTML mode: convert newlines in text parts to <br />, keep html parts as-is
        $parts = @()
        foreach ($part in $this.BodyParts) {
            if ($part.type -eq "html") {
                $parts += $part.content
            } else {
                $parts += ($part.content -replace "`r`n", "<br />" -replace "`n", "<br />")
            }
        }
        return (ConvertTo-Html -Body ($parts -join "`r`n") -Head $this.TableCss | Out-String)
    }

    [void] Send() {
        if (-not ($this.SmtpServer -and $this.Recipients -and $this.From)) { return }
        if ($this.IsHtml) { $this.SendHtml() } else { $this.SendPlain() }
    }

    hidden [void] SendHtml() {
        $Params = @{
            SmtpServer = $this.SmtpServer
            Subject    = $this.Subject
            Body       = $this.GetBody()
            To         = $this.Recipients
            From       = $this.From
        }
        $ServSet = $false
        try { $ServSet = $Global:Context.GetWellKnownContainerPath("ServiceSettings") } catch {}
        if ($ServSet) { Send-adxMail @Params -IsHtml }
        else          { Send-MailMessage @Params -BodyAsHtml }
    }

    hidden [void] SendPlain() {
        $Params = @{
            SmtpServer = $this.SmtpServer
            Subject    = $this.Subject
            Body       = $this.GetBody()
            To         = $this.Recipients
            From       = $this.From
        }
        $ServSet = $false
        try { $ServSet = $Global:Context.GetWellKnownContainerPath("ServiceSettings") } catch {}
        if ($ServSet) { Send-adxMail @Params }
        else          { Send-MailMessage @Params }
    }
}

#EndRegion Classes

function Send-adxMail {
    param (
        [string]   $SmtpServer,
        [string[]] $To,
        [string]   $From,
        [string]   $Subject,
        [string]   $Body,
        [switch]   $IsHtml
    )
    $To = $To -join ", "
    # Bind to the 'ServiceSettings' container
    $wellknownContainerPath = $Global:Context.GetWellKnownContainerPath("ServiceSettings")
    $serviceSettings        = $Global:Context.BindToObject($wellknownContainerPath)
    # Send mail via Adaxes — pass body in correct position: textBody (3) or htmlBody (4)
    if ($IsHtml) {
        $serviceSettings.MailSettings.SendMail($To, $Subject, $Null, $Body, $From, $Null, $Null)
    } else {
        $serviceSettings.MailSettings.SendMail($To, $Subject, $Body, $Null, $From, $Null, $Null)
    }
}

Function New-EryMailLog {
  <#
  .SYNOPSIS
      Creates a new EryMailLog object for composing and sending emails.
  .OUTPUTS
      EryMailLog
  .EXAMPLE
      $mail = New-EryMailLog -SmtpServer "smtp.example.com" -Recipients "user@domain.com" -From "bot@domain.com" -Subject "Backup Report"
      $mail.AddSuccessMessage("Backup completed.")
      $mail.AddTable($WBJob)
      $mail.Send()
  #>
  Param (
    [Parameter(Mandatory=$false)] [string]   $SmtpServer,
    [Parameter(Mandatory=$false)] [string[]] $Recipients,
    [Parameter(Mandatory=$false)] [string]   $From,
    [Parameter(Mandatory=$false)] [string]   $Subject
  )
  If ($SmtpServer -or $Recipients -or $From -or $Subject) {
      Return [EryMailLog]::new($SmtpServer, $Recipients, $From, $Subject)
  } Else {
      Return [EryMailLog]::new()
  }
}

# $mail = New-EryMailLog -SmtpServer "smtp.example.com" -Recipients "user@domain.com" -From "bot@domain.com" -Subject "Backup Report"
# $mail.AddMessage("Moving backups to long-time storage:")
# $mail.AddSuccessMessage("file.bak -> backup/file_2026-04-03.bak")
# $mail.AddFailedMessage("Could not find source: C:\missing.bak")
# $mail.AddTable($WBJob)
# $mail.AddTable($JobItems, @("Name", "BytesProcessed", "TotalBytes"))
# $mail.Send()
#
# Plain text:
# $mail.IsHtml = $false
# $mail.Send()
#
# Custom CSS:
# $mail.TableCss = "<style>TABLE{...}</style>"
