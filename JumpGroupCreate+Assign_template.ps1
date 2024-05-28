# Define the API credentials
$tokenUrl = "https://URL.beyondtrustcloud.com/oauth2/token";
$baseUrl = "https://URL.beyondtrustcloud.com/api/config/v1"
$client_id = "--";
$secret = "--"; 

#Group Policy ID, this is what we are adding the Jump Group to, it will be a number visible in the url when editing a group policy
$GPID = "--"


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


####Create a Jump Group####

$JumpGroupName = Read-Host -Prompt 'Please name the Jump Group you would like to create: '

# Construct the JSON body for the request
$JGAbody = @{
    "name" = $JumpGroupName
    "comments" = "API Generated"
} | ConvertTo-Json

# Output the JSON body for debugging purposes
#Write-Output $JGAbody

# Invoke the REST method to create a Jump Group
$JGAresponse = Invoke-RestMethod -Uri 'https://URL.beyondtrustcloud.com/api/config/v1/jump-group' -Method Post -Headers $headers -Body $JGAbody

# Output the response
Write-Output "This is what was created:"
$JGAresponse | ConvertTo-Json


# need to extract jumpgroup id here and set as variable to pass to the next bit

$JGID = $JGAresponse.id

#Write-Output $id


####Add Jump Group to pre-defined Group Policy, this could be supplied as a variable####

#Write-Output $GPID


# Body for the POST Group policy edit request
# jump item role set as administrator

$GPbody = @{
    "jump_group_id" = $JGID
	"jump_item_role_id" = 6
} | ConvertTo-Json


#Write-Output $GPbody

# Invoke REST Method to add Jump Group to pre-defined Group Policy
$GPEresponse = Invoke-RestMethod -Uri "https://URL.beyondtrustcloud.com/api/config/v1/group-policy/$GPID/jump-group" -Method Post -Headers $headers -Body $GPbody

# Output the response as JSON
Write-Output "This is what was added to your Group Policy:"
$GPEresponse | ConvertTo-Json
