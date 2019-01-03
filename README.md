# RingCentral API - Disable User
Connect to the RingCentral API using PowerShell to search for and disable a user.<br/>



## Installation
Save this file somewhere and call it within a PowerShell console.<br/><br/>

Since this is likely something that would be used programmatically the username and password would need to be made available to the script as needed.<br/>
To accomplish this securely create an AES key using powershell, store it somewhere secure that only the script or trusted users can access.<br/>
Create a password with this key somewhere else.<br/>
Then enter the paths where indicated in the production section.<br/>
<br/>
The credentials for your sandbox are not treated as securely and can be entered as plain text.<br/>
Though you can use the same key method if desired by using the same process.<br/>

## Usage
To use with your production app:

````powershell
Disable-RcUser -UserEmail someone@domain.com
````

To use with your sandbox app:

````powershell
Disable-RcUser -UserEmail someone@domain.com -Sandbox
````
