# DeleteUsersFromComputers
A script that accepts csv input of computer names and deletes all user profiles from those computers with specified exceptions.

User running the script must have admin rights on their conmputer as well as rights to run commands on the specified computers.


### Global variables to edit before running:

$inputFilePath - change this to the location of the input CSV file "ComputerList.csv". Do not edit cell A1.

$outputFilePath - change this to where you want the log file to be created/updated

### Function variables to edit before running:

$runWhatIf - leave this set to $true to run -whatIf instead of actually deleting the profiles (check twice, delete once)

$ExcludedUsers - add the username of any accounts to NOT delete. 
