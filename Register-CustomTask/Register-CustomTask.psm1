<#	
	===========================================================================
	 Created on:   	  	5/18/2016
	 Created by:   	  	TFreedland
	 Last Updated:    	6/29/2016
	 Last Updated by: 	TFreedland
	-------------------------------------------------------------------------
	 Version Number:	1.0.2
	 File Name:			Register-CustomTask.ps1
	 GUID:				11bcd8b0-2ce3-4a26-8bb5-58d899709da6
	===========================================================================
#>

#.EXTERNALHELP Register-CustomTask.psm1-Help.xml
function Register-CustomTask
{
    [CmdletBinding()]
    [Alias('rtas')]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TaskName,
        
        [int]$EventId = 400,
        
        [string]$Subscription = "<QueryList><Query Id='0'><Select Path='Windows PowerShell'>*[System[(EventID=$EventId)]]</Select></Query></QueryList>",
        
        [string]$ActionPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ActionArgs
    )
    Set-StrictMode -Version latest
    #check if event trigger is already in place
    $triggerExists = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -ne $triggerExists)
    {
        Write-Output "INFO: $TaskName event trigger is already registered."
    }
    elseif ($null -eq $triggerExists)
    {
        try
        {
            $Hostname = $env:COMPUTERNAME
            $Service = New-Object -ComObject ("Schedule.Service")
            $Service.Connect($Hostname)
            $RootFolder = $Service.GetFolder("\")
            $TaskDefinition = $Service.NewTask(0)
            
            $regInfo = $TaskDefinition.RegistrationInfo
            $regInfo.Description = "$TaskName"
            $regInfo.Author = "$env:USERNAME"
            
            $settings = $taskDefinition.Settings
            $settings.Enabled = $true
            $settings.StartWhenAvailable = $true
            $settings.Hidden = $false
            
            $Triggers = $TaskDefinition.Triggers
            $Trigger = $Triggers.Create(0)
            $Trigger.Id = $EventId
            $Trigger.Subscription = $Subscription
            $Trigger.Enabled = $true
            
            $Action = $TaskDefinition.Actions.Create(0)
            $Action.Path = $ActionPath
            $Action.Arguments = $ActionArgs
            
            $taskRunAsUser = $env:USERNAME
            $taskRunAsUserPwd = Get-Credential $env:USERNAME
            $rootFolder.RegisterTaskDefinition($TaskName, $TaskDefinition, 6, $taskRunAsUser, $taskRunAsUserPwd.GetNetworkCredential().Password, 1)
            Clear-Variable -Name taskRunAsUserPwd
        }
        catch { Write-Warning "Unable to create Process Monitor." }
    }
}

Export-ModuleMember -Function Register-CustomTask -Alias 'rtas'