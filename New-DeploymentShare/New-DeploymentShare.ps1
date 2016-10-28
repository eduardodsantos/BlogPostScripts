<#-------------------------------------------------------------------------------------------------
    Criado: 	 27-06-2015
    Version:	 1.0
    Autor:       Eduardo Sena
    Twitter:     @eduardodsantos      
    Blog:        http://www.deploymentinsider.blog.br
                    
    Version:     1.1
    Atualizado:  25-10-2016
    Autor:       Eduardo Sena
    Discription: Modificado comando Set-Item pelo Set-Content na edição dos arquivos BootStrap.in e
    CustomSetting.ini e adicionado variavel $DSUserAccess.

    As conta de usuário necessárias para uso no deployment share deve ser criada no active directory, 
    caso a conta criada tenha outro nome e senha as variáveis $UserID e $UserPassword deve ser alterada.

    Uso:       Copie os aquivos da midia de instalação do Windows para D:\CONTENTLAB\Operating Systems.
               Crie pastas para cada aplicativo a ser importado para o Deployment Share dentro da
               pasta D:\CONTENTLAB\Applications
                     Ex.: D:\CONTENTLAB\Operating Systems\Windows 8.1 Enterprise x64
                          D:\CONTENTLAB\Applications\AdobeDC
                          D:\CONTENTLAB\Applications\Office 2013

-------------------------------------------------------------------------------------------------#>
[CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true,Position=1)] $DSName,
    [Parameter(Position=2)] $DSDescription,
    [Parameter(Mandatory=$True,Position=3)] $DSDrive,
    [Parameter(Position=4)] $DSDir,
    [Parameter(Mandatory=$true,Position=5)] $DSAccessUser,
    [Parameter()] $OSSourcePath,
    [Parameter()] $AppSourcePath,
    [Parameter()] $OSPath,
    [Parameter()] $AppPath,
    [Parameter()] $TSPath,
    [Parameter()] $CustomBG
  )

#Definindo Variaveis
$ScritpPath = Split-Path -Path $PSScriptRoot
$MDTServer = $env:COMPUTERNAME
$UserID = "$DSAccessUser"
$UserPassword = ""
$NetworkPath = "\\$MDTServer\$DSName$"
$UserDomain = (Get-WmiObject -Class Win32_NTDomain).DomainName

#Testando se a unidade defida existe
if ($DSDir -ne $null)
   {
      if (Test-Path "$DSDir\")
      {
        $DSRoot = New-Item -Path "$DSDir\$DSName" -ItemType Directory -Verbose
      }
      else
      {
        Write-Host "Unidade $DSDir não encontrada, redirecionando para $env:HOMEDRIVE"
        Start-Sleep 5
        $DSRoot = New-Item -Path "$env:HOMEDRIVE\$DSName" -ItemType Directory -Verbose
      }
   }
else
      {
        Write-Host "Nenhuma letra de unidade especificada, Redirecionando para $env:HOMEDRIVE\ ..."
        Start-Sleep 5
        $DSRoot = New-Item -Path "$env:HOMEDRIVE\$DSName" -ItemType Directory -Verbose
      }

#Criando Novo DeploymentShare
New-SmbShare -Path $DSRoot -Name $DSName$ -Description "$DSDescription" -FullAccess "$env:COMPUTERNAME\Administrators" -ReadAccess "EveryOne" -ChangeAccess "$DSAccessUser"
Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1" -Verbose
$DSPath = New-PSDrive -Name "$DSDrive" `
          -PSProvider "MDTProvider" `
          -Root "$DSRoot" `
          -Description "$DSDescription" `
          -NetWorkPath "$NetWorkPath" -Verbose | Add-MDTPersistentDrive -Verbose
 
#Criando diretorio para Logs do MDT
New-Item -Path "$DSRoot\MDTLogs" -ItemType Directory -Verbose
New-SmbShare -Path $MDTLogs -Name "MDTLogs$" -Description "MDT Logs" -FullAcces "Administrators" -ChangeAccess "$DSAccessUser" -Verbose

#Criando Pastas em Applications
if ($AppPath -ne $null)
  {
    $AppPath | ForEach-Object { 
    New-Item -Path "$($DSPath):\Applications" -Name $_ -Enable "True" -Comment "" -ItemType "Folder" -Verbose
    }
  }

#Criando Pastas em Operating Systems
if ($OSPath -ne $null)
  {
    $OSPath | ForEach-Object { 
    New-Item -Path "$($DSPath):\Operating Systems" -Name $_ -Enable "True" -Comment "" -ItemType "Folder" -Verbose
    }
  }

#Criando Pastas em TS
if ($TSPath -ne $null)
  {
    $TSPath | ForEach-Object { 
    New-Item -Path "$($DSPath):\Task Sequences" -Name $_ -Enable "True" -Comment "" -ItemType "Folder" -Verbose
    }
  }

#Importando Applications para Deployment Share
#Testando se $AppSoucePath foi definido
if ($AppSourcePath -ne $null)
  {
  #Importando Adobe Reader DC
  Write-Host "Importando Acrobat Reader..."
  Import-MDTApplication `
    -Path "$($DSPath):\Applications\Adobe" `
    -Name "Adobe Reader DC" `
    -ShortName "Adobe Reader DC" `
    -Version "" `
    -Publisher "" `
    -Language "Pt-Br" `
    -ApplicationSourcePath "$AppSourcePath\Adobe\Acrobat Reader DC" `
    -DestinationFolder "Adobe Reader DC" `
    -Enable "True" `
    -CommandLine "AcrobatReaderDC_pt_BR.exe /sALL /rs" `
    -WorkingDirectory ".\Applications\Adobe Reader DC" -Verbose
   
  #Importando Office 2013
  Import-MDTApplication `
    -Path "$($DSPath):\Applications\Microsoft" `
    -Name "Office 2013 Pro Plus x86" `
    -ShortName "Office 2013 Pro Plus x86" `
    -Version "" `
    -Publisher "" `
    -Language "" `
    -ApplicationSourcePath "$AppSourcePath\Microsoft\Microsoft Office 2013" `
    -DestinationFolder "Office 2013 Pro Plus x86" `
    -Enable "True" `
    -CommandLine "setup.exe" `
    -WorkingDirectory ".\Applications\Office 2013 Pro Plus x86" -Verbose
    
  #Importando Microsoft Visual C++
  Write-Host "Importando Microsoft Visual C++..."
  Import-MDTApplication `
    -Path "$($DSPath):\Applications\Microsoft" `
    -Name "Microsoft Visual C++ x86 x64" `
    -ShortName "Microsoft Visual C++ x86 x64" `
    -Version "" `
    -Publisher "" `
    -Language "" `
    -ApplicationSourcePath "$AppSourcePath\Microsoft\MSVSC++" `
    -DestinationFolder "Microsoft Visual C++ x86 x64" `
    -Enable "True" `
    -CommandLine "powershell.exe -executionpolicy Bypass -file .\Install-MicrosoftVisualC++x86x64.ps1 -WindowStyle Minimized" `
    -WorkingDirectory ".\Applications\Microsoft Visual C++ x86x64" -Verbose
  }

#Importando Sistemas Operationais para Deployment Share
#Testando se $OSSourcePath foi definido
if ($OSSourcePath -ne $null)
  {
  #Importando Sistemas Operacionais
  Import-MDTOperatingSystem `
  -Path "$($DSPath):\Operating Systems\Windows 10 Default Image" `
  -SourcePath "$OSSourcePath" `
  -DestinationFolder "Windows 10 Enterprise x64 v1607" -Verbose
      Import-MDTOperatingSystem `  -Path "$($DSPath):\Operating Systems\Windows 10 Custom Image" `  -SourceFile "\\$env:COMPUTERNAME\BuildImageDS$\Captures\.wim" `  -SetupPath "$OSSourcePath\" `  -DestinationFolder "Windows 10 Enterprise x64 v1607 Custom" -Verbose 
  #Renomeando Operating Systems no Deployment Share
  Rename-Item -Path "$($DSPath):\Operating Systems\Windows 10 Default Image\Windows 10 Enterprise in Windows 10 Enterprise x64 v1607 install.wim" -NewName "Windows 10 Enterprise x64 v1607"
  
  #Criando TaskSequence
  Import-MDTTaskSequence `
  -Path "$($DSPath):\Task Sequences\Windows 10 Task Sequence" `
  -Template "Client.xml" `
  -Name "Deploy Custom Image Windows 10 Enterprise x64 v1607" `
  -ID "TSC100001" `
  -Comments "Add more apps as Adobe Software and Microsoft Visual C++" `
  -Version "1.0" `
  -OperatingSystemPath "$($OSSourcePath):\Operating Systems\Windows 10 Custom Image\Windows 10 Enterprise x64 v1607" `
  -FullName "ESENA" `
  -OrgName "ESENA" `
  -AdminPassword "P@ssword"`
  -HomePage "http://deploymentinsider.blog.br" -Verbose
  }
        
#Modificando o arquivo Bootstrap.ini
$BSFile = @"
[Settings]
Priority=Default

[Default]
DeployRoot=$DSRoot
UserID=$UserID
UserPassword=$UserPassword
UserDomain=$UserDomain

SkipBDDWelcome=YES
"@

Set-Content -Path "$DSDir\$DSName\Control\Bootstrap.ini" -Value $BSFile -Force -Verbose

#Modificando o arquivo CustomSettings.ini
$CSFile = @"
[Settings]
Priority=Default
Properties=MyCustomProperty

[Default]
_SMSTSORGNAME=eSena Deployment
_SMSTSPackageName=%TaskSequenceName%
OSInstall=Y

SkipCapture=YES
DoCapture=NO

SkipTimeZone=YES
TimeZoneName=E. South America Standard Time

SkipLocaleSelection=YES
KeyboardLocale=0416:00000416
UILanguage=pt-BR
UserLocale=pt-BR

SkipDomainMembership=YES
JoinDomain=$UserDomain
DomainAdmin=
DomainAdminDomain=
DomainAdminPassword=
MachineObjectOU=

XResolution=1
YResolution=1

SLShare=\\$MDTServer\MDTLogs$\%OSDComputerName%
SLShareDynamicLogging=\\$MDTServer\MDTLogs$\%OSDComputerName%

HideShell=YES

SkipFinalSummary=NO
FinishAction=RESTART

SkipApplications=YES
SkipTaskSequence=NO
SkipAdminPassword=YES
SkipProductKey=YES
SkipComputerBackup=YES
SkipBitLocker=YES
SkipUserData=YES
SkipSummary=YES
SkipRoles=YES
SkipComputerName=NO
"@

Set-Content -Path "$DSDir\$DSName\Control\CustomSettings.ini" -Value $CSFile -Force -Verbose

#Alterando Propriedades do Deployment Share
Set-ItemProperty -Path "$($DSPath):" -Name Supportx86 -Value $false
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.FeaturePacks -Value "winpe-mdac,winpe-powershell,winpe-dismcmdlets,winpe-netfx"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.LiteTouchISOName -Value "$($DSName)_x64.iso"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.LiteTouchWIMDescription -Value "$($DSName) PE (x64)"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.BackgroundFile -Value "$CustomBG"