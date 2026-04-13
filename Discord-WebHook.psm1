<#
.SYNOPSIS
    Discord WebHook module for (Adaxes) PowerShell scripts.
.NOTES
    Author: Eryniox
    Date:   June 2025
.LINK
    https://github.com/EryServers/
#>

#region Classes
class DiscordStringReturn {
    static [string] FixUnicode([string]$text) {
        # Fix unicode characters in the text
        $text = $text -replace "❌", ":x:"
        $text = $text -replace "✅", ":white_check_mark:"
        $text = $text -replace "⚠️", ":warning:"
        $text = $text -replace "ℹ️", ":information_source:"
        $text = $text -replace "(?m)^\\\\", "\\\\"
        $text = $text -replace " \\\\", " \\\\"
        return $text
    }
    static [string] Truncate([string]$text, [int]$maxLength) {
        if ($text.Length -le $maxLength) {
            return $text
        } else {
            return $text.Substring(0, $maxLength)
        }
    }
}

class DiscordEmbedField {
    #field.name	256 characters
    #field.value	1024 characters
    #inline - whether the field should be displayed on the same line as other fields

    # Properties
    hidden [string] $nameFull
    hidden [string] $valueFull
    [bool]   $inline = $false

    # Hidden Property-methods
    hidden $__class_init__ = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'name' -Value { # get
            # Only return the first 256 characters
            if ($this.nameFull) { return [DiscordStringReturn]::Truncate( $this.nameFull, 256 ) }
            return $null
        } -SecondValue { param ( $arg ) 
            $this.nameFull = $arg
        } # set
        $this | Add-Member -MemberType ScriptProperty -Name 'value' -Value { # get
            # Only return the first 1024 characters
            if ($this.valueFull) { return [DiscordStringReturn]::Truncate( $this.valueFull, 1024 ) }
            return $null
        } -SecondValue { param ( $arg ) 
            $this.valueFull = $arg
        } # set
    )

    # Constructor
    DiscordEmbedField() {}
    DiscordEmbedField([string]$name, [string]$value, [bool]$inline) {
        $this.nameFull = $name
        $this.valueFull = $value
        $this.inline = $inline
    }

    # Methods
    [hashtable] ToHashtable() {
        return @{
            name  = $this.name
            value = $this.value
            inline = $this.inline
        }
    }
} #[DiscordEmbedField]::new("Field Name Example", "Field Value Example", $true)

class DiscordEmbed {
    #embeds:
    #Field	Limit
    #title	256 characters
    #description	4096 characters
    # fields	Up to 25 field objects

    # footer.text	2048 characters
    # author.name	256 characters
    # Additionally, the combined sum of characters in all title, description, field.name, field.value, footer.text, and author.name fields across all embeds attached to a message must not exceed 6000 characters. Violating any of these constraints will result in a Bad Request response.

    # Properties
    [string] $titleFull
    [string] $descriptionFull
    [int]    $color
    [string] $footerFull
    [string] $authorFull
    [hashtable] $footer = @{
        text = ""
    }
    [hashtable] $author = @{
        name = ""
    }
    [DiscordEmbedField[]] $fields = @()


    # Hidden Property-methods
    hidden $__class_init__ = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'title' -Value { # get
            # Only return the first 256 characters
            if ($this.titleFull) { return [DiscordStringReturn]::Truncate( $this.titleFull, 256 ) }
            return $null
        } -SecondValue { param ( $arg ) 
            $this.titleFull = $arg
        } # set
        $this | Add-Member -MemberType ScriptProperty -Name 'description' -Value { # get
            # Only return the first 4096 characters - or max 6000 total with other fields
            $Maximum = [Math]::Min(4096, 6000 - $this.GetTotalCharacterCountWithoutDescription())
            if ($this.descriptionFull) { return [DiscordStringReturn]::Truncate( $this.descriptionFull, $Maximum ) }
            return $null
        } -SecondValue { param ( $arg ) 
            $this.descriptionFull = $arg
        } # set
    )   

    # Constructor
    DiscordEmbed() {}
    DiscordEmbed([string]$title, [string]$description, [int]$color) {
        $this.titleFull = $title
        $this.descriptionFull = $description
        $this.color = $color
    }

    # Methods
    [void] TruncateFooterAuthor() {
        if ((-not $this.authorFull) -and ($this.author.name.Length -gt 0)) {
            $this.authorFull = $this.author.name
        }
        if ((-not $this.footerFull) -and ($this.footer.text.Length -gt 0)) {
            $this.footerFull = $this.footer.text
        }

        if ($this.authorFull) {
            $this.author.name = [DiscordStringReturn]::Truncate( $this.authorFull, 256 )
        }
        if ( $this.footerFull ) {
            $this.footer.text = [DiscordStringReturn]::Truncate( $this.footerFull, 2048 )
        }
    }
    
    [void] AddField([DiscordEmbedField]$field) {
        if ($this.fields.Count -lt 25) {
            $this.fields += $field
        } else {
            Write-Warning "Cannot add more than 25 fields to a Discord embed."
        }
    }

    [int] GetTotalCharacterCount() {
        $total = 0
        $total += $this.GetTotalCharacterCountWithoutDescription()
        if ($this.description) { $total += $this.description.Length }
        return $total
    }
    hidden [int] GetTotalCharacterCountWithoutDescription() {
        $total = 0
        if ($this.title) { $total += $this.title.Length }
        foreach ($field in $this.fields) {
            if ($field.name) { $total += $field.name.Length }
            if ($field.value) { $total += $field.value.Length }
        }
        $this.TruncateFooterAuthor()
        if ($this.footer.text) { $total += $this.footer.text.Length }
        if ($this.author.name) { $total += $this.author.name.Length }
        return $total
    }
    [hashtable] ToHashtable() {
        $this.TruncateFooterAuthor()
        $embedHashtable = @{}
        if ($this.title) { $embedHashtable.title = $this.title }
        if ($this.description) { $embedHashtable.description = $this.description }
        if ($this.color) { $embedHashtable.color = $this.color }
        if ($this.footer.text) { $embedHashtable.footer = $this.footer }
        if ($this.author.name) { $embedHashtable.author = $this.author }
        $embedHashtable.fields = @()
        foreach ($field in $this.fields) {
            $embedHashtable.fields += $field.ToHashtable()
        }
        return $embedHashtable
    }
}

class DiscordWebHook {
    # Properties
    [string] $HookUrl
    #^^ HookURL example: https://discord.com/api/webhooks/<ID>/<token>
    [string] $ThreadId
    #^^ Optional ThreadID example: 123456789012345678
    [string] $content
    [DiscordEmbed[]] $Embeds = @()
    [string] $username
    #^^ Examlpe: "WebHook Bot"
    [int]    $CurrentEmbedCharacterCount = 0

    # Hidden Property-methods
    hidden $__class_init__ = $(
        $this | Add-Member -MemberType ScriptProperty -Name 'ThreadURL' -Value { # get
            If ($this.ThreadId) {
                return $this.HookUrl + "?thread_id=" + $this.ThreadId
            } Else {
                return $this.HookUrl
            }
        } -SecondValue { param ( $arg ) } # set . don't care about the set
    )

    # Constructor
    DiscordWebHook() {}
    DiscordWebHook([string]$hookUrl) {
        $this.HookUrl = $hookUrl
    }
    DiscordWebHook([string]$hookUrl, [string]$threadId) {
        $this.HookUrl = $hookUrl
        $this.ThreadId = $threadId
    }
    DiscordWebHook([string]$hookUrl, [string]$threadId, [string]$content) {
        $this.HookUrl = $hookUrl
        $this.ThreadId = $threadId
        $this.Content = $content
    }

    # Methods
    [string] FixUnicode([string]$text) { return ([DiscordStringReturn]::FixUnicode($text)) }

    [void] Send() {
        if (-not $this.HookUrl) {
            # Write-Host "Hook URL not set. Not sending Discord message."
            return
        }
        if ($this.embeds.Count -gt 0) {
            $this.SendEmbed()
            return
        }
        if (-not $this.Content) {
            # Write-Host "Content not set. Not sending Discord message."
            return
        }
         
        # If the content is too long, it will be split into chunks of max 2000 characters.}
        $FixedContent = $this.FixUnicode($this.content)
        $maxLength = 2000
        $chunks = [regex]::Matches($FixedContent, "(.|`r|`n){1,$maxLength}") | ForEach-Object { $_.Value }

        $Payload = @{
            content = ""
        }
        if ($this.username) { $Payload.username = $this.username }

        foreach ($chunk in $chunks) {
            $Payload.content = $chunk
            $this.SendPayload($Payload)
        }
    }

    [void] SendEmbed() {
        if ($this.Embeds.Count -lt 1) {
            # Write-Host "Hook URL or embeds not set. Not sending Discord message."
            return
        }
        $Payload = @{}
        if ($this.content) {
            $Payload.content = [DiscordStringReturn]::Truncate($this.FixUnicode($this.content), 2000)
        }
        if ($this.username) { $Payload.username = $this.username }

        $Payload.embeds = @()
        foreach ($embed in $this.Embeds) {
            $Payload.embeds += $embed.ToHashtable()
        }
        $this.SendPayload($Payload)
    }

    hidden [void] SendPayload([hashtable]$Payload) {
        Write-Host "DEBUG: Invoke-WebRequest -Uri $($this.ThreadURL) -Method Post"
        Write-Host ("DEBUG: -Body `r`n" + ($Payload | ConvertTo-Json -Depth 8))
        #Invoke-WebRequest -Uri $this.ThreadURL -Method Post -Body ($Payload | ConvertTo-Json -Depth 8) -ContentType "application/json"
    }

    [void] AddEmbed([DiscordEmbed]$embed) {
        if ($this.Embeds.Count -ge 10) {
            Write-Warning "Cannot add more than 10 embeds to a Discord WebHook message."
            return
        }
        $embed.TruncateFooterAuthor()
        $NewCharacterCount = $this.CurrentEmbedCharacterCount + $embed.GetTotalCharacterCount()
        if ($NewCharacterCount -le 6000) {
            $this.CurrentEmbedCharacterCount = $NewCharacterCount
            $this.Embeds += $embed
        } else {
            Write-Warning "Cannot add embed: total character count exceeds 6000 characters."
        }
    }

    [DiscordEmbed] NewDiscordEmbed() { return [DiscordEmbed]::new() }
    [DiscordEmbed] NewDiscordEmbed([string]$title, [string]$description, [int]$color) {
        $NewEmbed = [DiscordEmbed]::new()
        $NewEmbed.title = $title
        $NewEmbed.description = $description
        $NewEmbed.color = $color
        return $NewEmbed
    }
    [DiscordEmbedField] NewDiscordEmbedField() { return [DiscordEmbedField]::new() }
    [DiscordEmbedField] NewDiscordEmbedField([string]$name, [string]$value, [bool]$inline) {
        return [DiscordEmbedField]::new($name, $value, $inline)
    }
}

#EndRegion Classes

Function New-DiscordWebHook {
  <#
  .SYNOPSIS
      Creates a new DiscordWebHook object for sending messages to Discord via WebHook.
  .OUTPUTS
      DiscordWebHook
  .EXAMPLE
      $webhook = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/..."
      $webhook.Content = "Hello, Discord!"
      $webhook.Send()
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [string]$HookUrl,
    [Parameter(Mandatory=$false)]
    [string]$ThreadId
  )
  If ($ThreadId) {
      Return [DiscordWebHook]::new($HookUrl, $ThreadId)
  } Else {
      Return [DiscordWebHook]::new($HookUrl)
  }
}

# $Send = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/your_webhook_id/your_webhook_token"
# $Embed = $Send.NewDiscordEmbed("Test Embed Title", "This is a test embed description.", 5814783)
# $Field1 = $Send.NewDiscordEmbedField("Field 1", "This is the value for field 1.", $true)

# $Embed.AddField($Field1)
# $Send.AddEmbed($Embed)

# $Send.ThreadId = "123456789012345678"
# $Send.Send()
# Example Embed JSON Structure:

# {
#   "username": "smtp Ex Bot",
#   "embeds": [
#     {
#       "title": "📨 {{ .Subject }}",
#       "description": {{ printf "%q" .Body }},
#       "color": 5814783,
#       "fields": [
#         {
#           "name": "From",
#           "value": {{ printf "%q" .From }},
#           "inline": true
#         },
#         {
#           "name": "To",
#           "value": {{ printf "%q" .To }},
#           "inline": true
#         },
#         {
#           "name": "Date",
#           "value": {{ printf "%q" .Date }},
#           "inline": false
#         }
#       ],
#       "footer": {
#         "text": "Received on {{ .DateGet }}"
#       }
#     }
#   ]
# }

# embeds:
# Field	Limit
# title	256 characters
# description	4096 characters
# fields	Up to 25 field objects
# field.name	256 characters
# field.value	1024 characters
# footer.text	2048 characters
# author.name	256 characters
# Additionally, the combined sum of characters in all title, description, field.name, field.value, footer.text, and author.name fields across all embeds attached to a message must not exceed 6000 characters. Violating any of these constraints will result in a Bad Request response.
# Field	Description
# content?*	Message contents (up to 2000 characters)
