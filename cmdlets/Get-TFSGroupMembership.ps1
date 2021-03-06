Param([string] [string]$GroupName, $TfsCollectionUrl="http://scmtfs.medassets.com:8080/tfs/SCMTech", [switch]$UserID)

# -------------------------------------------------------------------------------------------------------------------------------------
Add-Type -AssemblyName "Microsoft.TeamFoundation.Client, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
                        "Microsoft.TeamFoundation.Common, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
                        "Microsoft.TeamFoundation, Version=11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
# -------------------------------------------------------------------------------------------------------------------------------------
 
$tfs = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($TfsCollectionUrl)

try
{
    $tfs.EnsureAuthenticated()
}
catch
{
    Write-Error "Error occurred trying to connect to project collection: $_ "
    exit 1
}
 
$cssService = $tfs.GetService("Microsoft.TeamFoundation.Server.ICommonStructureService3")   
$idService = $tfs.GetService("Microsoft.TeamFoundation.Framework.Client.IIdentityManagementService")
$ReadIdentityOptions = [Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::TrueSid

$CatalogName = $tfs.CatalogNode.Resource.DisplayName

$ProjectName = [regex]::Match($GroupName,"\[(.*?)\]").Groups[1].Value
if ($ProjectName -eq "")
{
    Throw "Group Name must contain Project - '[project]\groupname'"
    exit 1
}

try
{
    $GroupIdentity = $idService.ListApplicationGroups($ProjectName, $ReadIdentityOptions) | ?{$_.DisplayName -eq $GroupName}
}
catch
{
    Write-Error ("Error looking up Project '{0}' in Collection '{1}'" -f $ProjectName, $TfsCollectionUrl)
    Throw $_
    exit 1
}

if ($GroupIdentity -eq $null)
{
    Throw ("Group '{0}' in Project '{1}' could not be found" -f $GroupName,$ProjectName)
    exit 1
}
    
function list_identities ($tfsIdentity)
{
    $queryOption = ([Microsoft.TeamFoundation.Framework.Common.MembershipQuery]::Direct)
    $readIdentityOptions = ([Microsoft.TeamFoundation.Framework.Common.ReadIdentityOptions]::TrueSid)

    $identities = $idService.ReadIdentities($tfsIdentity, $queryOption, $readIdentityOptions)
       
    foreach($id in $identities)
    {
        if ($id.IsContainer)
        {
            if ($id.Members.Count -gt 0)
            {
                list_identities $id.Members 
            }
        }
        else
        {
            $id
        } 
    }
}

$ids = list_identities  $GroupIdentity.Descriptor 
if ($UserID)
{
	$ids | sort -Unique UniqueName | %{$_.UniqueName} | ?{$_} 
}
else
{
	$ids | sort -Unique UniqueName | %{$_.GetProperty('Mail')} | ?{$_} | %{$_ + ';'} 
}
