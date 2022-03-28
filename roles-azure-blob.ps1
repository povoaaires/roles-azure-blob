
# Conexão com o Azure utilizando o On-Premises
#Connect-AzAccount
[CmdletBinding()]

param (
   [Parameter(Mandatory=$false)]
   [string]$ResourceGroupName ="RESOURCE_NAME_GROUP"

)

Begin{
    Write-Output "Connecting on $(Get-Date)"
    
    try{
        #Conexão com o Azure usando um Aplicativo
        $servicePrincipalConnection=Get-AutomationConnection -Name "AzureRunAsConnection"
        Connect-AzAccount  -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    Catch{
        if (!$servicePrincipalConnection){
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        
        }else{
            Write-Output -Message $_.Exception
            throw $_.Exception
        }
    }
    

}
End
{
#Função que retorna o Contexto, um parâmetro que possibilita o acesso e a modificação no BlobStorage
function context_resource {
    $accountKey = "Account Key"
    $account_name = "storage_account_name"
    $context = New-AzStorageContext -StorageAccountName $account_name -StorageAccountKey $accountKey 

    return $context
}

#Armazenando a função do contexto em uma variável

$con = context_resource 

<# Função Principal que transforma o retorno da função Get-AzRoleAssignment em um JSON e armazena no BlobStorage

Get-AzRoleAssignment: Retorna todas as permissões dos usuários da Subscription 

Return:

    "RoleAssignmentName": "zzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
    "RoleAssignmentId": "/providers/Microsoft.Management/managementGroups/XXXXXXXXXX/providers/Microsoft.Authorization/roleAssignments/YYYYYYYYYYY",
    "Scope": "/providers/Microsoft.Management/managementGroups/KKKKKKKKKKKKKKKK",
    "DisplayName": "fulano de tal",
    "SignInName": "email_user",
    "RoleDefinitionName": "User Access Administrator",
    "RoleDefinitionId": "hhhhhhhhhhhhhhhhhhhhhh",
    "ObjectId": "qqqqqqqqqqqqqqqqqqqqqqqq",
    "ObjectType": "User",
    "CanDelegate": false,
    "Description": null,
    "ConditionVersion": null,
    "Condition": null

#>

function main {
    param($get, $account_name, $container_name, $file_name, $blob_name, $context)
    $get_name_convert_json = ConvertTo-Json($get) #Converte em JSON
    $get_name_convert_json | Out-File $file_name # Out-File Transforma o retorno em um arquivo (Out-File 'nome do arquivo')
    Set-AzStorageBlobContent -Container $container_name -File $file_name -Blob $blob_name -Context $context -Force  #Upload do arquivo no Blob

}


$teste = Get-AzRoleAssignment
main $teste 'storage_account_name' 'container_name' 'file_name.json' 'blob_name.json' $con

}






