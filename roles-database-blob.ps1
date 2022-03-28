#Conexão com o Azure


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

<# 
    Definindo as funções de armazenamento no Blob Storage

    * A primeira função pega o contexto do blob e a segunda armazena o dado no blob storage

#>
function context_resource {
    $accountKey = "Account Key"
    $account_name = "storage_account_name"
    $context = New-AzStorageContext -StorageAccountName $account_name -StorageAccountKey $accountKey 

    return $context
}


function main {
    param($get, $account_name, $container_name, $file_name, $blob_name, $context)
    $get_name_convert_json = $get
    $get_name_convert_json | Out-File $file_name # Out-File Transforma o retorno em um arquivo (Out-File 'nome do arquivo')
    Set-AzStorageBlobContent -Container $container_name -File $file_name -Blob $blob_name -Context $context -Force  #Upload do arquivo no Blob

}

<#
    Definição de variáveis
#>
$SQLServer = "tcp:name_instance,port","tcp:name_instance,port"    
$SQLDBName = "database name 1","database name 2"

$userName = 'user'
$password = 'pw'
$contador = 0 #Contador para o segundo array


#Primeiro laço para pegar a instância
foreach ($instance in $SQLServer) {
    
    #Variáveis - Nome do arquivo a ser gerado e o nome do database no array
    $name_file = $instance.Substring($instance.IndexOf("sql"), $instance.IndexOf("-prd")) + ".json"
    $database = $SQLDBName[$contador]
    #Teste de Conexão
    try {
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
        $SqlConnection.ConnectionString = "Server = $instance; Database = $database; User ID = $userName; Password = $password;"
        $SqlConnection.Open()
        
        Write-Host "Teste de conexão bem sucedido"
    }
    catch {
        Write-Host "Falha ao se conectar"
    } 
    # Criação do comando a ser executado
    $command = $SqlConnection.CreateCommand()
    $query = "SELECT DISTINCT pr.principal_id, pr.name, pr.type_desc, 
    pr.authentication_type_desc, pe.state_desc, pe.permission_name
    FROM sys.database_principals AS pr
    JOIN sys.database_permissions AS pe
    ON pe.grantee_principal_id = pr.principal_id;"
    $command.CommandText = $query

    #Execução do comando
    try {
        $result = $command.ExecuteReader()
        $table = New-Object System.Data.DataTable
        $table.Load($result)
    }
    catch {
        Write-Host "Falha ao executar o comando"
    }   
    #Armazenamento do resultado em uma variável no Formato JSON
    $table_end = $table | Select-Object $table.Columns.ColumnName |ConvertTo-Json

    #Armazenando no Blob Storage
    $context = context_resource
    main $table_end 'storage_account_name' 'container_name' $name_file  $name_file  $context



    #Fechando a conexão com o Banco
    $SqlConnection.Close()

    
    $contador++  
}

}







