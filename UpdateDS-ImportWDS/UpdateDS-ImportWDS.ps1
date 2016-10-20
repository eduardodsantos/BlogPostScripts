<#
Created:	 2015-05-07
Version:	 1.0
Author       Eduardo Sena      
Homepage:    http://www.eduardosena.com.br

Updated:     2015-12-07
Version:	 2.0
Author       Eduardo Sena      
Homepage:    http://www.eduardosena.com.br

Updated:     2015-12-07
Version:	 2.1
Description: Inserido a opção do script buscar a descrição da imagem do MDT automaticamente
             usando as prorpiedades do Deployment Share
Author       Eduardo Sena      
Homepage:    http://www.eduardosena.com.br

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and 
is not supported by the author.

Author - Eduardo Sena
    Twitter: @eduardodsantos
    Blog   : http://eduardosena.com.br

Usage:
O script é baseado nos parâmetros DSRoot, DSPath e ImageName.
DSRoot = Caminho local para o DeploymentShare (Ex.: C:\DeploymentShare)
DSPath = Referencia o PSDrive definido na criação do DeploymentShare (Ex.: DS001)
Force = Força a recriação das imagens de boot do MDT
#>

[CmdletBinding()]Param(
    [Parameter(Mandatory=$true,Position=1)]
        $DSRoot,
    [Parameter(Mandatory=$true,Position=2)]
        $DSPath,
    [Parameter(Position=3)]
        $force
)

#Definindo Local para os logs
Try 
    {
        $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
        $logPath = $tsenv.Value("LogPath")
    }
Catch 
    {
        $logPath = $env:windir + "\Logs"
    }
$logFile = "$logPath\$($myinvocation.MyCommand).log"

Start-Transcript $logFile
Write-Output "Logging in $logfile"

#Importa Modulo do MDT para Powershell e Atualiza DS
Add-PSSnapin Microsoft.BDD.PSSnapin -ErrorAction SilentlyContinue
New-PSDrive -Name $DSPath -PSProvider MDTProvider -Root $DSRoot

$MDTProperty = Get-ItemProperty -Path "$($DSPath):"

#Definindo Variavéis
$WDSServer = $env:COMPUTERNAME
$MDTBootx64 = "$($DSRoot)\Boot\LiteTouchPE_x64.wim"                                   #Arquivo .wim gerado pelo MDT
$MDTBootx86 = "$($DSRoot)\Boot\LiteTouchPE_x86.wim"                                   #Arquivo .wim gerado pelo MDT
$MDTImageNamex64 = $MDTProperty.'Boot.x64.LiteTouchWIMDescription'                    #Nome da Imagem de Boot do MDT (wim file)  
$MDTImageNamex86 = $MDTProperty.'Boot.x86.LiteTouchWIMDescription'                    #Nome da Imagem de Boot do MDT (wim file)
$WDSWIMFileNamex64 = ($MDTProperty.Description).Replace(' ','') + "_x64.wim"          #Novo nome do aquivo Wim no WDS Server
$WDSWIMFileNamex86 = ($MDTProperty.Description).Replace(' ','') + "_x86.wim"          #Novo nome do aquivo Wim no WDS Server
$WDSImageNamex64 = $MDTProperty.Description + " (x64)"                                #Nome da imagem de Boot no Servidor WDS
$WDSImageNamex86 = $MDTProperty.Description + " (x86)"                                #Nome da imagem de Boot no Servidor WDS

#Atualiza Deployment Share
if ($force -eq $true)
    {
        Write-Output "Parametro Force definido como True | Recriando imagens de Boot do MDT"
        Update-MDTDeploymentShare -Path "$($DSPath):" -force -Verbose
    }
else
    {
        Write-Output "Atualizando imagens de Boot do MDT"
        Update-MDTDeploymentShare -Path "$($DSPath):" -Verbose
    }

#Testando se a feature WDS está instalada
If (Get-WindowsFeature -Name *WDS* | Where-Object {$_.Installed -eq "$true"})
{
    Write-Output "Feature WDS instalada, Verificando se o serviço está em execução"
    #Verificando se o serviço WDSServer está executando
    if (Get-Service -Name WDSServer | Where-Object {$_.Status -eq "Running"})
        {
            Write-Output "WDS Server Services Executando, Importando imagens"
        }
    else
        {
            Start-Service -Name WDSServer -PassThru -Verbose
        }
}
else
{
    Write-Output "Feature não instalada, importação não pode ser feita..."
    Break 
}

#Importando Imagem de Boot x686
If (Get-WdsBootImage -ImageName $WDSImageNamex86) 
{
    Write-Output "Imagem Encontrada... Iniciando Replace Imagem de Boot x86."
    WDSUTIL /Verbose /replace-image /image:$WDSImageNamex86 /ImageType:Boot /Architecture:x86 /ReplacementImage /ImageFile:$MDTBootx86 /Server:$WDSServer
    Set-WdsBootImage -ImageName $MDTImageNamex86 -NewImageName $WDSImageNamex86 -NewDescription $WDSImageNamex86 -Architecture x86 -Verbose
}
else
{
    If ($MDTProperty.SupportX86 -eq $true)
    {
        Write-Output "Imagem não Encontrada... Importando imagem de boot x86."
        Import-WdsBootImage -Path $MDTBootx86 -NewImageName $WDSImageNamex86 -NewFileName $WDSWIMFileNamex86 -NewDescription $WDSImageNamex86 -Verbose
    }
    else
    {
        Write-Output "MDT Boot Image x86 nao definida"
    }
}

#Importando Imagem de Boot x64
If (Get-WdsBootImage -ImageName $WDSImageNamex64) 
{
    Write-Output "Imagem Encontrada... Iniciando Replace da Imagem de Boot x64."
    WDSUTIL /verbose /replace-image /image:$WDSImageNamex64 /ImageType:Boot /Architecture:x64 /ReplacementImage /ImageFile:$MDTBootx64 /Server:$WDSServer
    Set-WdsBootImage -ImageName $MDTImageNamex64 -NewImageName $WDSImageNamex64 -NewDescription $WDSImageNamex64 -Architecture x64 -Verbose
} 
else
{
If ($MDTProperty.SupportX64 -eq $true)
    {
        Write-Output "Imagem não Encontrada... Importando imagem de boot x64."
        Import-WdsBootImage -Path $MDTBootx64 -NewImageName $WDSImageNamex64 -NewFileName $WDSWIMFileNamex64 -NewDescription $WDSImageNamex64 -Verbose
    }
    else
    {
        Write-Output "MDT Boot Image x86 nao definida"
    } 
}

Stop-Transcript