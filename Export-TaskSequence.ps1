 <#-------------------------------------------------------------------------------------------------
    Criado: 	 27-06-2015
    Atualizado:  
    Version:	 1.0
    Autor:       Eduardo Sena  
    Twitter:     @eduardodsantos      
    Blog:        http://www.deploymentinsider.blog.br

    Discription: Exporta MDT Task Sequence com Template
#>
[CmdletBinding()]
Param (
    [Parameter (Mandatory=$True)]
        $DSPath,
    [Parameter (Mandatory=$True)]
        $TSID,
    [Parameter (Mandatory=$True)]
        $NewTemplateName,
    [Parameter (Mandatory=$true)]
        $Description
)

Copy-Item -Path "$DSPath\Control\$TSID\ts.xml" -Destination "$DSPath\Templates\$($NewTemplateName).xml"
   
$fileName = "$DSPath\Templates\$($NewTemplateName).xml"

$xmlfile = [System.Xml.XmlDocument](Get-Content $fileName)
$XMLAtt = $xmlfile.sequence
$XMLAtt.SetAttribute("name","$NewTemplateName")
$XMLAtt.SetAttribute("description","$Description")
$xmlfile.Save($fileName)