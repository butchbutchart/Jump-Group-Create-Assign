# Define the API credentials
$tokenUrl = "https://URL.beyondtrustcloud.com/oauth2/token";
$baseUrl = "https://URL.beyondtrustcloud.com/api/config/v1"
$client_id = "--";
$secret = "--"; 

#endregion creds
###########################################################################

#region Authent 
###########################################################################

# Step 1. Create a client_id:secret pair
$credPair = "$($client_id):$($secret)"
# Step 2. Encode the pair to Base64 string
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
# Step 3. Form the header and add the Authorization attribute to it
$headersCred = @{ Authorization = "Basic $encodedCredentials"  }
# Step 4. Make the request and get the token
$responsetoken = Invoke-RestMethod -Uri "$tokenUrl" -Method Post -Body "grant_type=client_credentials" -Headers $headersCred;
#return $responsetoken
$token = $responsetoken.access_token;
#Write-Host "DEBUG token $token"
$headersToken = @{ Authorization = "Bearer $token" }
# Step 5. Prepare the header for future request
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", "Bearer $token")
#endregion
###########################################################################

####Ask user for object names, (group policies will use the same name as jump groups with an additional suffix) and their region, this is information that would be passed to the script via your automation solution

$SubmittedGroupName = Read-Host -Prompt 'Please name the object you would like to create, Group Policy and Jump Group will share the same name: '

$Prefix = Read-Host -Prompt 'Please name the region specific prefix that will be used to identify the location of the object: '



$GroupName = ($prefix+'-'+$SubmittedGroupName)

Write-Output -
Write-Output "Root Object Name: $($GroupName)"
Write-Output -

####Create a Jump Group####


# Construct the JSON body for the request
$JGAbody = @{
    "name" = $GroupName
    "comments" = "API Generated"
} | ConvertTo-Json


# Construct the full URL for the jump group request
$jumpGroupUrl = "$baseUrl/jump-group"


# Invoke the REST method to create a Jump Group
try {
    $JGAresponse = Invoke-RestMethod -Uri $jumpGroupUrl -Method Post -Headers $headers -Body $JGAbody
    # Output the response
	Write-Output "Jump Group Created:$($JGAresponse.name)"
	Write-Output -
} catch {
    # Catch and output any errors
    Write-Error "Error occurred: $_"
}



#####get the ID of the new Jump Group so it can be put into the Group Policy

$JGID = $JGAresponse.id

####Create a Group Policy for Administrators of the new Jump Group####
# Construct the JSON body for the request

$AdminJumpGroupName = ($GroupName+'-'+'Administrators')

$AdminGPAddbody = @{
  "name" = $AdminJumpGroupName
  "perm_access_allowed" = $true
  "access_perm_status" = "defined"
  "perm_share_other_team" = $false
  "perm_invite_external_user" = $false
  "perm_session_idle_timeout" = -1
  "perm_extended_availability_mode_allowed" = $false
  "perm_edit_external_key" = $false
  "perm_collaborate" = $false
  "perm_collaborate_control" = $false
  "perm_jump_client" = $false
  "perm_local_jump" = $false
  "perm_remote_jump" = $true
  "perm_remote_vnc" = $false
  "perm_remote_rdp" = $true
  "perm_shell_jump" = $false
  "perm_web_jump" = $false
  "perm_protocol_tunnel" = $false
  "default_jump_item_role_id" = 6
  "private_jump_item_role_id" = 1
  "inferior_jump_item_role_id" = 1
  "unassigned_jump_item_role_id" = 1
} | ConvertTo-Json


# Construct the full URL for the group policy request
$GPAddUrl = "$baseUrl/group-policy"


# Invoke the REST method to create a Group Policy
try {
    $AdminGPAddresponse = Invoke-RestMethod -Uri $GPAddUrl -Method Post -Headers $headers -Body $AdminGPAddbody
	
	
    # Output the response
	Write-Output "Administrative Group Policy Created: $($AdminGPAddresponse.name)"
	Write-Output -
} catch {
    # Catch and output any errors
    Write-Error "Error occurred: $_"
}









####Add Jump Group to Admin Group Policy####
#### Body for the POST Group policy edit request

#get the ID of the new Admin Group Policy to create the url 
$AdminGPID = $AdminGPAddresponse.id

#Add the jump group to the admin group policy. Jump item role is 'User's default' for the admin this is 'Administrator'

$AdGPbody = @{
    "jump_group_id" = $JGID
	"jump_item_role_id" = 0
} | ConvertTo-Json



# Construct the full URL
$fullUrl = "$baseUrl/group-policy/$AdminGPID/jump-group"



# Invoke the REST method to add Jump Group to pre-defined Group Policy
try {
    $GPEresponse = Invoke-RestMethod -Uri $fullUrl -Method Post -Headers $headers -Body $AdGPbody
	
	
    # Output the response
	Write-Output "Added Jump Group: $($JGAresponse.name) to Administrators Group Policy"
	Write-Output -

} catch {
    # Catch and output any errors
    Write-Error "Error occurred: $_"
}


####Create a Group Policy for Standard Users - Start Sessions Only - for the new Jump Group####
# Construct the JSON body for the request

$StanJumpGroupName = ($GroupName+'-'+'Standard Users')

$StanGPAddbody = @{
  "name" = $StanJumpGroupName
  "perm_access_allowed" = $true
  "access_perm_status" = "defined"
  "perm_share_other_team" = $false
  "perm_invite_external_user" = $false
  "perm_session_idle_timeout" = -1
  "perm_extended_availability_mode_allowed" = $false
  "perm_edit_external_key" = $false
  "perm_collaborate" = $false
  "perm_collaborate_control" = $false
  "perm_jump_client" = $false
  "perm_local_jump" = $false
  "perm_remote_jump" = $true
  "perm_remote_vnc" = $false
  "perm_remote_rdp" = $true
  "perm_shell_jump" = $false
  "perm_web_jump" = $false
  "perm_protocol_tunnel" = $false
  "default_jump_item_role_id" = 7
  "private_jump_item_role_id" = 1
  "inferior_jump_item_role_id" = 1
  "unassigned_jump_item_role_id" = 1
} | ConvertTo-Json


# Construct the full URL for the group policy request
$GPAddUrl = "$baseUrl/group-policy"



# Invoke the REST method to create a Group Policy
try {
    $StanGPAddresponse = Invoke-RestMethod -Uri $GPAddUrl -Method Post -Headers $headers -Body $StanGPAddbody
	
	
    # Output the response
	Write-Output "Created Standard User Jump Group: $($StanGPAddresponse.name)"
	Write-Output -
} catch {
    # Catch and output any errors
    Write-Error "Error occurred: $_"
}


##########get the ID of the new Standard Group Policy to create the url 
$StanGPID = $StanGPAddresponse.id

### Body that adds the jump group to the group policy. jump item role is 'User's default' for the Standard user group policy this is 'Start Session only'

$StanGPbody = @{
    "jump_group_id" = $JGID
	"jump_item_role_id" = 0
} | ConvertTo-Json


# Construct the full URL
$fullUrl = "$baseUrl/group-policy/$StanGPID/jump-group"


# Invoke the REST method to add Jump Group to Standard User Group Policy
try {
    $StanGPEresponse = Invoke-RestMethod -Uri $fullUrl -Method Post -Headers $headers -Body $StanGPbody
	
	
    # Output the response
	Write-Output "Added Jump Group: $($JGAresponse.name) to Standard Users Group Policy"
	Write-Output -
} catch {
    # Catch and output any errors
    Write-Error "Error occurred: $_"
}
