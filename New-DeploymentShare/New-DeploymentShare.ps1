<#-------------------------------------------------------------------------------------------------
    Criado: 	 27-06-2015
    Atualizado:  31-05-2016
    Version:	 1.0
    Autor        Eduardo Sena
    Twitter:     @eduardodsantos      
    Blog:        http://www.deploymentinsider.blog.br


    As conta de usuário necessárias para uso no deployment share deve ser criada no active directory, 
    caso a conta criada tenha outro nome e senha as variáveis $UserID e $UserPassword deve ser alterada.

    Uso:           Copie os aquivos da midia de instalação do Windows para D:\CONTENTLAB\Operating Systems.
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
    [Parameter(Position=4)] $DSDir = "",
    [Parameter()] $OSPath = "",
    [Parameter()] $AppPath = ""
  )

#Definindo Variaveis
$ScritpPath = Split-Path -Path $PSScriptRoot
$MDTServer = $env:COMPUTERNAME
$UserID = "mdt.dsa"
$UserPassword = "P@ssword"
$NetworkPath = "\\$MDTServer\$DSName$"
$UserDomain = (Get-WmiObject -Class Win32_NTDomain).DomainName


    #Testando se a unidade defida existe
    if ($DSDir -ne "")
    {
      if (Test-Path "$DSDir\")
      {
        $DSRoot = New-Item -Path "$DSDir\$DSName" -ItemType Directory
      }
      else
      {
        Write-Host "Unidade $DSDir não encontrada, redirecionando para $env:HOMEDRIVE"
        Start-Sleep 5
        $DSRoot = New-Item -Path "$env:HOMEDRIVE\$DSName" -ItemType Directory
      }
    }
    else
      {
        Write-Host "Nenhuma letra de unidade especificada, Redirecionando para $env:HOMEDRIVE\ ..."
        Sleep 5
        $DSRoot = New-Item -Path "$env:HOMEDRIVE\$DSName" -ItemType Directory
      }
    New-SmbShare -Path $DSRoot -Name $DSName$ -Description "$DSDescription" -ReadAccess "EveryOne" -ChangeAccess "MDT.DSSA"
    Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1" -Verbose
    $DSPath = New-PSDrive -Name "$DSDrive" `
                -PSProvider "MDTProvider" `
                -Root "$DSRoot" `
                -Description "$DSDescription" `
                -NetWorkPath "$NetWorkPath" -Verbose | Add-MDTPersistentDrive -Verbose

#Criando Pastas em Applications
New-Item -Path "$($DSPath):\Applications" -Name "Microsoft" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Applications" -Name "Adobe" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Applications" -Name "Bundles" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Applications" -Name "Oracle" -Enable "True" -Comment "" -ItemType "Folder"

#Criando Pastas em Operating Systems
New-Item -Path "$($DSPath):\Operating Systems" -Name "Windows 10 Custom Image" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Operating Systems" -Name "Windows 10 Default Image" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Operating Systems" -Name "Windows 8.1 Default Image" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Operating Systems" -Name "Windows 8.1 Custom Image" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Operating Systems" -Name "Windows Server 2012 R2" -Enable "True" -Comment "" -ItemType "Folder"

#Criando Pastas em TS
New-Item -Path "$($DSPath):\Task Sequences" -Name "Windows 10 Task Sequence" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Task Sequences" -Name "Windows 8.1 Task Sequence" -Enable "True" -Comment "" -ItemType "Folder"
New-Item -Path "$($DSPath):\Task Sequences" -Name "Windows Server 2012 R2 Task Sequence" -Enable "True" -Comment "" -ItemType "Folder"


    #Importando Adobe Reader DC
    Write-Host "Importando Acrobat Reader..."
    Import-MDTApplication `
        -Path "$($DSPath):\Applications\Adobe" `
        -Name "Adobe Reader DC" `
        -ShortName "Adobe Reader DC" `
        -Version "" `
        -Publisher "" `
        -Language "Pt-Br" `
        -ApplicationSourcePath "$AppPath\Adobe\Acrobat Reader DC" `
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
        -ApplicationSourcePath "$AppPath\Microsoft\Microsoft Office 2013" `
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
        -ApplicationSourcePath "$AppPath\Microsoft\MSVSC++" `
        -DestinationFolder "Microsoft Visual C++ x86 x64" `
        -Enable "True" `
        -CommandLine "powershell.exe -executionpolicy Bypass -file .\Install-MicrosoftVisualC++x86x64.ps1 -WindowStyle Minimized" `
        -WorkingDirectory ".\Applications\Microsoft Visual C++ x86x64" -Verbose

    #Importando Sistemas Operacionais
    Import-MDTOperatingSystem `
        -Path "$($DSPath):\Operating Systems\Windows 10 Default Image" `
        -SourcePath "$OSPath" `
        -DestinationFolder "Windows 10 Enterprise x64 v1607" -Verbose

   <# Import-MDTOperatingSystem `        -Path "$($DSPath):\Operating Systems\Windows 10 Custom Image" `        -SourceFile "\\$env:COMPUTERNAME\BuildImageDS$\Captures\.wim" `        -SetupPath "$OSPath\" `        -DestinationFolder "Windows 10 Enterprise x64 v1607 Custom" -Verbose #> 

    #Renomeando Operating Systems no Deployment Share
    Rename-Item -Path "$($DSPath):\Operating Systems\Windows 10 Default Image\Windows 10 Enterprise in Windows 10 Enterprise x64 v1607 install.wim" -NewName "Windows 10 Enterprise x64 v1607"

    <#Criando TaskSequence
    Import-MDTTaskSequence `
        -Path "$($DSPath):\Task Sequences\Windows 10 Task Sequence" `
        -Template "Client.xml" `
        -Name "Deploy Custom Image Windows 10 Enterprise x64 v1607" `
        -ID "TSC100001" `
        -Comments "Add more apps as Adobe Software and Microsoft Visual C++" `
        -Version "1.0" `
        -OperatingSystemPath "$($OSPath):\Operating Systems\Windows 10 Custom Image\Windows 10 Enterprise x64 v1607" `
        -FullName "ESENA" `
        -OrgName "ESENA" `
        -AdminPassword "P@ssword"`
        -HomePage "http://deploymentinsider.blog.br" -Verbose #>
        Import-MDTTaskSequence `        -Path "$($DSPath):\Task Sequences\Windows 10 Task Sequence" `        -Template "ClientUpgrade.xml" `        -Name "In-place Upgrade for Windows 10 Enterprise x64 v1607" `
        -ID "TSC100002" `
        -Comments "" `        -Version "1.0" `        -OperatingSystemPath "$($DSPath):\Operating Systems\Windows 10 Default Image\Windows 10 Enterprise x64 v1607" `        -FullName "ESENA" `
        -OrgName "ESENA" `        -AdminPassword "P@ssword" `        -HomePage "http://deploymentinsider.blog.br"
        

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

New-Item -Path "$DSDir\$DSName\Control\Bootstrap.ini" -ItemType "File" -Value $BSFile -Force -Verbose

#Modificando o arquivo CustomSettings.ini
$CSFile = @"
[Settings]
Priority=Default
Properties=MyCustomProperty

[Default]
_SMSTSORGNAME=eSena Image Build Lab
OSInstall=Y
DoCapture=YES
TimeZoneName=E. South America Standard Time
KeyboardLocale=0416:00000416
UILanguage=pt-BR
UserLocale=pt-BR
SLShare=\\$MDTServer\MDTLogs$\%OSDComputerName%
SLShareDynamicLogging=\\$MDTServer\MDTLogs$\%OSDComputerName%
HideShell=YES
FinishAction=SHUTDOWN

SkipApplications=YES
SkipTaskSequence=NO
SkipTimeZone=YES
SkipTaskSequence=YES
SkipCapture=YES
SkipAdminPassword=YES
SkipProductKey=YES
SkipComputerBackup=YES
SkipBitLocker=YES
SkipUserData=YES
SkipSummary=YES
SkipFinalSummary=NO
SkipRoles=YES
SkipLocaleSelection=YES
SkipComputerName=YES
SkipDomainMembership=YES
"@

New-Item -Path "$DSDir\$DSName\Control\CustomSettings.ini" -ItemType "File" -Value $CSFile -Force -Verbose

#Alterando Propriedades do Deployment Share
Set-ItemProperty -Path "$($DSPath):" -Name Supportx86 -Value $false
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.FeaturePacks -Value "winpe-mdac,winpe-powershell,winpe-dismcmdlets,winpe-netfx"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.LiteTouchISOName -Value "$($DSName)_x64.iso"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.LiteTouchWIMDescription -Value "$($DSName) PE (x64)"
Set-ItemProperty -Path "$($DSPath):" -Name Boot.x64.BackgroundFile -Value "E:\Wallpapers\DInsider_BG.bmp"