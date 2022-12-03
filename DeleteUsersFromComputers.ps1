#filepath of the csv that lists which computers to remove profiles from
$inputFilePath = "C:\filepath\ComputerList.csv"

#filepath for the txt file used for logging
$outputFilePath = "C:\filepath\log.txt"

#import the csv
$computers = Import-Csv $inputFilePath

#this function defines the process for writing to the log file
Function Write-LogFile{
Param ([string]$LogString)

    $timeStamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $logEntry = "$timeStamp : $LogString"
    Add-Content $outputFilePath -value $logEntry
}

#this script block is used to run the deletions below in the Invoke-Command section below
Function Delete-Users{

#
##
###
$runWhatIf=$true  #change this to $false to actually delete the users
###
##
#
    #The list of accounts, which profiles must not be deleted
    $ExcludedUsers ="Public",”Default”,”Default User”,"youraccount","super-admin","beepboop"

    #Run actual deletion task
    $LocalProfiles=Get-WMIObject -class Win32_UserProfile | Where {(!$_.Special) -and (!$_.Loaded) }
    foreach ($LocalProfile in $LocalProfiles){
        if (!($ExcludedUsers -like $LocalProfile.LocalPath.Replace("C:\Users\",""))){
            #get profile name for display in log file
            $deletedUser = $LocalProfile.LocalPath.Replace("C:\Users\","")
            if($runWhatIf -eq $true){
                $LocalProfile | Remove-WmiObject -WhatIf
                Write-Output "WhatIf - Profile: $deletedUser”
            }
            elseif($runWhatIf -eq $False){
                $LocalProfile | Remove-WmiObject
                Write-Output "Deleted Profile: $deletedUser”
            }
            else{
                Write-Output "The `$runWhatIf variable is set incorrectly."
            }
        }
    }
}

# Verify the tool is being ran as admin.
$Role = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If ($Role -eq $False) {

    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Please run as admin!",0,"Error",16) | Out-Null   
}
else{
    #cycle through each computer in the csv
    $data=foreach ($computer in $computers){

        #set computer name variable and write start to log
        $ComputerName = $($computer.ComputerName)
        Write-LogFile "Starting process for $ComputerName`:"

        #run other script to actual do the deletions
        $commandOutput = Invoke-Command -ComputerName $ComputerName -ScriptBlock ${function:Delete-Users} -ErrorVariable invokeResult
        Write-LogFile "$commandOutput"

        #small check for offline/inaccessible/nonexistent computers - put it in the log file
        if($invokeResult -like "*WinRM cannot complete the operation*"){
            Write-LogFile "Error connecting to $ComputerName - Device may be offline."
        }
        elseif($invokeResult -like "*WinRM cannot process the request*"){
            Write-LogFile "Error connecting to $ComputerName - Device may not exist. Please check the name."
        }
        #write end to log
        Write-LogFile "Finished process for $ComputerName" 
        Write-LogFile "--------------------------------------------------------------------------------------------------------"
    }
}