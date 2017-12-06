<#
    >#-----------------------------------------------------------------------------------------------------------------------#<
    ##===================== Este script envia notificação por email no final do deployment ==================================##
    >#-----------------------------------------------------------------------------------------------------------------------#<
    **** Criado:   30-10-2017
    **** Version:  1.0
    **** Autor:    Eduardo Sena
    **** Twitter:  @eduardodsantos      
    **** Blog:     http://www.deploymentinsider.blog.br
    >#-----------------------------------------------------------------------------------------------------------------------#<
#>

##------------------------##
## DEFINIÇÃO DE VARIAVEIS ##
##------------------------##

Write-Progress -Activity "Enviado email" -Status "Obtendo Informações" -PercentComplete 25 -Id 1 
$SmtpServer = 'smtp.office365.com'
$SmtpUser = 'alertas@deploymentinsider.blog.br'
$smtpPwd = '********'
$MailTo = 'alertas@deploymentinsider.blog.br'
$MailFrom = 'alertas@deploymentinsider.blog.br'
$MDTServerName = 'ESN-MDT01'
$MailSubject = "[MDT] Notificação do processo OS Deployment - PC $env:COMPUTERNAME"


##----------------------------------------------------------------------------------------------------------------------------##
##****************************************** Coletando dados do MDT Monitor Data *********************************************##
##*************************************** Usando Função escrita pelo Mikael Nyström ******************************************##
##----------------------------------------------------------------------------------------------------------------------------##

Function Get-MDTOData{
    <# 
    .Synopsis 
        Function for getting MDTOdata 
    .DESCRIPTION 
        Function for getting MDTOdata 
    .EXAMPLE 
        Get-MDTOData -MDTMonitorServer MDTSERVER01 
    .NOTES 
        Created: 2016-03-07 
        Version: 1.0 
 
        Author - Mikael Nystrom 
        Twitter: @mikael_nystrom 
        Blog : http://deploymentbunny.com 
 
    .LINK 
        http://www.deploymentbunny.com 
    #>
    Param(
    $MDTMonitorServer = $MDTServerName
    ) 
    $URL = "http://" + $MDTMonitorServer + ":9801/MDTMonitorData/Computers"
    $Data = Invoke-RestMethod $URL
    foreach($property in ($Data.content.properties) ){
        $Hash =  [ordered]@{ 
            Name = $($property.Name); 
            PercentComplete = $($property.PercentComplete.'#text'); 
            Warnings = $($property.Warnings.'#text'); 
            Errors = $($property.Errors.'#text'); 
            DeploymentStatus = $( 
            Switch($property.DeploymentStatus.'#text'){ 
                1 { "Active/Running"} 
                2 { "Failed"} 
                3 { "Successfully completed"} 
                Default {"Unknown"} 
                }
            );
            StepName = $($property.StepName);
            TotalSteps = $($property.TotalStepS.'#text')
            CurrentStep = $($property.CurrentStep.'#text')
            DartIP = $($property.DartIP);
            DartPort = $($property.DartPort);
            DartTicket = $($property.DartTicket);
            VMHost = $($property.VMHost.'#text');
            VMName = $($property.VMName.'#text');
            LastTime = $($property.LastTime.'#text') -replace "T"," ";
            StartTime = $($property.StartTime.'#text') -replace "T"," "; 
            EndTime = $($property.EndTime.'#text') -replace "T"," "; 
            }
        New-Object PSObject -Property $Hash
    }
} 

$Property = (Get-MDTOData -MDTMonitorServer $MDTServerName) | Where-Object {$_.Name -eq "$env:ComputerName"}

#========================================================================================================##

Write-Progress -Activity "Enviando e-mail" -Status "Criando e-mail" -PercentComplete 50 -Id 1 

$MailBody = @"
Informações MDT OS Deployment.

Deployment do computador $env:COMPUTERNAME foi concluído.
TaskSequence Name: $TSEnv:TASKSEQUENCENAME
Fabricante: $TSEnv:Make
Modelo: $TSEnv:Model
Memoria: $TSEnv:Memory MB
Número de Serie: $TSEnv:SerialNumber
AssetTag: $TSEnv:AssetTag

====== MDT Monitor Info. ======
Alertas: $($property.Warnings)
Erros: $($property.Errors)
Finalizado: $($property.LastTime)
"@

Write-Progress -Activity "Enviando e-mail" -Status "Enviando e-mail para $MailTo" -PercentComplete 75 -Id 1 

$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPwd | ConvertTo-SecureString -AsPlainText -Force) 
Send-MailMessage -To "$MailTo" -from "$MailFrom" -Subject $MailSubject -Body $MailBody -Encoding UTF8 -Attachments "$tsenv:LogPath\BDD.log" -SmtpServer $SmtpServer -port 587 -UseSsl -Credential $Credentials

Write-Progress -Activity "Enviando e-mail" -Status "Enviado com Sucesso" -PercentComplete 100 -Id 1
