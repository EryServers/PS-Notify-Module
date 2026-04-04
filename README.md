# PS-Notify-Module

PowerShell modules for sending notifications — email and Discord webhooks.
Designed for use both in standalone scripts and inside [Adaxes](https://www.adaxes.com/) server-side scripts.

> **Note:** This repository is maintained only for personal use. Pull Requests are welcome, but bug fixes are not guaranteed.

---

## Modules

### `Email.psm1` — `EryMailLog`

Compose and send emails with plain text or HTML, including styled tables.
Auto-detects Adaxes context and uses the appropriate send method.

**Factory function:**
```powershell
$mail = New-EryMailLog -SmtpServer "smtp.example.com" -Recipients "user@domain.com" -From "bot@domain.com" -Subject "Backup Report"
```

**Key methods:**

| Method | Description |
|--------|-------------|
| `AddMessage(string)` | Append a text block to the body |
| `AddTable(data)` | Append an HTML table (forces `$IsHtml = $true`) |
| `AddTable(data, properties)` | As above, with column selection |
| `GetBody()` | Returns the composed body string |
| `Send()` | Send the email |

**Key properties:**

| Property | Default | Description |
|----------|---------|-------------|
| `IsHtml` | `$true` | HTML or plain text. Forced `$true` by `AddTable()` |
| `TableCss` | Cornflower blue style | Overridable CSS `<style>` block |

**Example:**
```powershell
$mail = New-EryMailLog -SmtpServer "smtp.example.com" -Recipients "user@domain.com" -From "bot@domain.com" -Subject "Backup Report"
$mail.AddMessage("Backup results:")
$mail.AddTable($WBJob)
$mail.AddTable($JobItems, @("Name", "BytesProcessed", "TotalBytes"))
$mail.Send()

# Plain text:
$mail.IsHtml = $false
$mail.Send()
```

---

### `Discord-WebHook.psm1` — `DiscordWebHook`

Send messages and rich embeds to a Discord channel via webhook.
Handles Discord's character limits automatically (content 2000, embed fields 256/1024, total 6000).

**Factory function:**
```powershell
$webhook = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/..." [-ThreadId "123456789"]
```

**Example — plain message:**
```powershell
$webhook = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/..."
$webhook.content = "Hello, Discord!"
$webhook.Send()
```

**Example — embed:**
```powershell
$webhook = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/..."
$embed = $webhook.NewDiscordEmbed("Title", "Description", 5814783)
$embed.AddField($webhook.NewDiscordEmbedField("Field 1", "Value 1", $true))
$webhook.AddEmbed($embed)
$webhook.Send()
```

---

### `Logging.psm1` — `EryLog` / `EryISOTime`

Simple timestamped message log. Pairs well with `EryMailLog` — pass `$log.GetMessage()` directly to `$mail.AddMessage()`.

**Factory function:**
```powershell
$log = New-EryLog
```

**Key methods:**

| Method | Description |
|--------|-------------|
| `AddMessage(string)` | Append message with ISO timestamp |
| `AddSuccessMessage(string)` | Prepends `✅ - ` |
| `AddFailedMessage(string)` | Prepends `❌ - ` |
| `GetMessage()` | Returns all messages joined by `\r\n` |

**`EryISOTime` — static time helpers:**
```powershell
[EryISOTime]::ms()    # 2026-04-04T13:45:00.123
[EryISOTime]::sec()   # 2026-04-04T13:45:00
[EryISOTime]::Date()  # 2026-04-04
# Also available as functions:
Get-EryISOTime -Format ms
```

**Combined example (Log → Mail + Discord):**
```powershell
$log  = New-EryLog
$mail = New-EryMailLog -SmtpServer "smtp.example.com" -Recipients "user@domain.com" -From "bot@domain.com" -Subject "Backup"
$hook = New-DiscordWebHook -HookUrl "https://discord.com/api/webhooks/..."

$log.AddSuccessMessage("File copied OK")
$log.AddFailedMessage("Could not find source")

$mail.AddMessage($log.GetMessage())
$mail.Send()

$hook.content = $log.GetMessage()
$hook.Send()
```
