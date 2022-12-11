# NTLM-Hash-Cracker
A powershell script used for extracting and cracking NTLM hashes from LSASS dump files for a class project.

## Pre-requisites
+ John the Ripper v1.9.0 and mimikatz need to be extracted in the same folder as this script. Leave them in their extracted folders.
+ You must have permission to run this script as Administrator.
+ Running powershell scripts must also be enabled on your system. This can be done from an elevated powershell prompt running the following command.
```ps
Set-ExecutionPolicy RemoteSigned
```

## Usage
The script can be run by double-clicking the file in Explorer, or called from a Powershell terminal. It will search for all LSASS dump files with the *.dmp extension. Mimikatz will read the first username and NTLM hash from each dump for John the Ripper to crack.

If John is not able to crack the hash in a timely manner (likely due to password complexity) you can press Q to stop the cracking.

The successfully cracked hashes for each user will be saved to _cracked-passwords.txt_. John the Ripper will also save cracked hashes to avoid cracking them again on future attempts.
