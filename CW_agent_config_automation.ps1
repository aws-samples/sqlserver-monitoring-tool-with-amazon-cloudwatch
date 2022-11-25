###########################################################################################################
# PRE-REQUSITIES
# 1) Install AWS CLI, you can run this command on Powershell "C:\> msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi" 
# 2) Copy the "cw-agent.json" file to C:\ drive on the RDS Custom EC2 Instance
# 3) Copy the "dashboardconfig.json" file to C:\ drive on the RDS Custom EC2 Instance
# 4) Ensure the EC2 Instance Role can run aws cloudwatch put-dashboard to create the dashboard, aws ec2 describe-volumes to get volume information.
# 5) Copy this "CW_agent_config_automation.ps1" file to C:\ drive on the RDS Custom EC2 Instance
# 6) To execute the ps1 script, using PowerShell terminal run the following command & "C:\CW_agent_config_automation.ps1"
###########################################################################################################

$instanceID = Get-EC2InstanceMetadata -Category InstanceId
$imageID =  Get-EC2InstanceMetadata -Category AmiId
$volumeID = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instanceID Name=attachment.device,Values=xvdg --query 'Volumes[*].Attachments[*].VolumeId' --output text
$volumeLabel = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instanceID Name=attachment.device,Values=xvdg --query 'Volumes[*].Tags[?Key==`Name`].Value' --output text
$region = Get-EC2InstanceMetadata -Category Region | Select-Object -ExpandProperty SystemName
$CWNamespace = "RDSCustom-"+$volumeLabel.replace('do-not-delete-rds-custom-','').replace('-storage','')
$dashboard = Read-Host "Enter the Name of CloudWatch Dashboard (Example - <RDS_Name>_Dashboard)"

write-host ""
write-host "============================================================================================="
write-host *********************************"SUMMARY OF USER INPUTS"*************************************
write-host "============================================================================================="
write-host ""
write-host "RDS Custom EC2 Instance ID : $instanceID"
write-host ""
write-host "RDS Custom EC2 Instance AMI ID : $imageID"
write-host ""
write-host "AWS Region Name: $region"
write-host ""
write-host "RDS Custom EC2 Instance EBS Volume ID : $volumeID"
write-host ""
write-host "RDS Custom EC2 Instance EDB Volume Name : $volumeLabel"
write-host ""
write-host "CloudWatch Dashboard Name : $dashboard"
write-host ""

Start-Sleep -s 5

write-host "============================================================================================="
write-host *******************************"CONFIGURE CLOUDWATCH AGENT"***********************************
write-host "============================================================================================="
write-host ""

write-host "Begin Configuration"
write-host "Copying JSON Config file"
(Get-Content c:\cw-agent.json).replace('RDSCustom', $CWNamespace) | Set-Content c:\cw-agent.json
Copy-Item "c:\cw-agent.json" -Destination "C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json"
write-host "Configuration Completed"
write-host "Begin Restarting Cloudwatch Agent"
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a fetch-config -m ec2 -s -c file:"C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json"
write-host "CloudWatch Agent Restart Completed"

Start-Sleep -s 2

write-host ""
write-host  "Preparing JSON Script dashboardconfig.json"
write-host ""

Start-Sleep -s 2

(Get-Content c:\dashboardconfig.json).replace('rr-rr-rr', $region) | Set-Content c:\dashboardconfig.json
(Get-Content c:\dashboardconfig.json).replace('vol-zzzzzz', $volumeID) | Set-Content c:\dashboardconfig.json
(Get-Content c:\dashboardconfig.json).replace('do-not-delete-rds-custom-rds-custom-2-storage', $volumeLabel) | Set-Content c:\dashboardconfig.json
(Get-Content c:\dashboardconfig.json).replace('i-xxxxxx', $instanceID) | Set-Content c:\dashboardconfig.json
(Get-Content c:\dashboardconfig.json).replace('ami-yyyyyy', $imageID) | Set-Content c:\dashboardconfig.json
(Get-Content c:\dashboardconfig.json).replace('RDSCustom', $CWNamespace) | Set-Content c:\dashboardconfig.json

write-host  "Dashboard JSON Script is ready"
write-host ""
write-host  "Installing the Script in Amazon CloudWatch"
write-host ""

aws cloudwatch put-dashboard --dashboard-name $dashboard --dashboard-body file://C:\dashboardconfig.json --region $region

Start-Sleep -s 5

write-output "Installation Successful. Please login to AWS Console and check the dashboard. The metrics might take few minutes to populate in CloudWatch"