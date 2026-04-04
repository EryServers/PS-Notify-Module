<#
.SYNOPSIS
    Function and classes for sending emails and with the result.
.NOTES
    Author: Eryniox
    Date:   June 2025
.LINK
    https://github.com/EryServers/
#>

#region Parameters, Variables, Trap and required snapins


[string[]]$MailRecipients = $Context.GetParameterValue("param-MailRecipients") -split ";"
[string]$MailFrom = $Context.GetParameterValue("param-MailFrom")
[string]$MailsmtpServer = $Context.GetParameterValue("param-MailsmtpServer")
[string]$DiscordHookUrl = $Context.GetParameterValue("param-DiscordHookUrl")
[string]$DiscordThreadId = $Context.GetParameterValue("param-DiscordThreadId")

#EndRegion Parameters, Variables, Trap and required snapins
