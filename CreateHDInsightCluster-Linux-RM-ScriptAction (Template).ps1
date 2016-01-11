###################################################################
# Providision a Linux HDInsight cluster in Resource Manager mode. # 
# Includes a script action to install Hue.                        #
# Replace the items between "<>" before executing.                #
###################################################################

# Select the Azure subscription
$subscriptionName = "<Subscription Name>" # (String)
$subscriptionID = (Get-AzureRmSubscription -SubscriptionName $subscriptionName).SubscriptionId
Select-AzureRmSubscription -SubscriptionId $subscriptionID

# Settings to use SQL Azure Database for the Hive and Oozie metastores
$hiveMetaDBName = "<SQL DB for Hive>" # (String)
$oozieMetaDBName = "<SQL DB for Oozie>" # (String)
$dbAdminLogin = "<SQL Admin Login>" # (String)
$dbAdminPassword ="<SQL Admin Password>" # (String)
$sqlServerName = "<SQL Azure Server Name>" # (String)

$dbPass = ConvertTo-SecureString $dbAdminPassword -AsPlainText -Force
$dbCreds = New-Object System.Management.Automation.PSCredential($dbAdminLogin, $dbPass)

# HDI Cluster Settings
$clusterSizeInNodes = "<HDI Cluster Size>" # (Integer) Ex: 1

$azureResourceGroupName = "<Resource Group Name>" # (String)
$azureHDInsightName = "<HDI Cluster Name>" # (String)
$azureHDIStorageAccount = "<Storage Account Name>" # (String)
$azureHDIStorageContainerName = "<Storage Container Name>" # (String)
$hdiUsername = "<HDInsight User Name>" # (String)
$sshUsername = "<SSH User Name>" # (String)
$hdiPassword = "<HDInsight Password>" # (String)

$azureStorageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $azureResourceGroupName -Name $azureHDIStorageAccount).Key1
$azureHDIVersion = "<HDI Version>" # (String) Ex: "3.2"
$azureHDIHeadNodeSize = "<Head Node Size>" # (String) Ex: "Large"
$azureHDIWorkerNodeSize = "<Worker Node Size>" # (String) Ex: "Large"
$azureHDIZookeeperNodeSize = "<Zookeeper Node Size>" # (String) Ex: "Large"
$azureHDIClusterLocation = "<Azure Region>" # (String) Ex: "East US"

$hdiPass = ConvertTo-SecureString $hdiPassword -AsPlainText -Force
$hdiCredential = New-Object System.Management.Automation.PSCredential($sshUsername, $hdiPass)
$sshCredential = New-Object System.Management.Automation.PSCredential($sshUsername, $hdiPass)

# Hue configuration parameters
$hueConfigParams = "-u $sshUsername '$hdiPassword'"

# Create the cluster configuration
$config = New-AzureRmHDInsightClusterConfig -ClusterType Hadoop `
                                            -DefaultStorageAccountKey $azureStorageKey `
                                            -DefaultStorageAccountName "$azureHDIStorageAccount.blob.core.windows.net" `
                                            -HeadNodeSize $azureHDIHeadNodeSize `
                                            -WorkerNodeSize $azureHDIWorkerNodeSize

# Add the Hive metastore configuration
$config = Add-AzureRmHDInsightMetastore -Config $config `
                                        -SqlAzureServerName "$sqlServerName.database.windows.net" `
                                        -DatabaseName $hiveMetaDBName `
                                        -Credential $dbCreds `
                                        -MetastoreType HiveMetastore

# Add the Oozie metastore configuration
$config = Add-AzureRmHDInsightMetastore -Config $config `
                                        -SqlAzureServerName "$sqlServerName.database.windows.net" `
                                        -DatabaseName $oozieMetaDBName `
                                        -Credential $dbCreds `
                                        -MetastoreType OozieMetastore

# Add the Hue script action
$config = Add-AzureRmHDInsightScriptAction -Config $config `
                                           -Name "Install Hue" `
                                           -NodeType HeadNode `
                                           -Uri https://hdiconfigactions.blob.core.windows.net/linuxhueconfigactionv01/install-hue-uber-v01.sh `
                                           -Parameters $hueConfigParams

# Create the cluster
New-AzureRmHDInsightCluster -Config $config `
                            -ResourceGroupName $azureResourceGroupName `
                            -ClusterName $azureHDInsightName `
                            -OSType Linux `
                            -Version $azureHDIVersion `
                            -HttpCredential $hdiCredential `
                            -SshCredential $sshCredential `
                            -DefaultStorageContainer $azureHDIStorageContainerName `
                            -Location $azureHDIClusterLocation `
                            -ClusterSizeInNodes $clusterSizeInNodes

# Get the cluster configuration details
#Get-AzureRmHDInsightCluster -Name $AzureHDInsightName -ResourceGroupName $AzureResourceGroupName

# Tear down the cluster
#Remove-AzureRMHDInsightCluster -ClusterName $AzureHDInsightName -ResourceGroupName $AzureResourceGroupName
