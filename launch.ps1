function Get-ScriptDirectory
{
	$Invocation = (Get-Variable MyInvocation -Scope 1).Value
	Split-Path $Invocation.MyCommand.Path
}

$dossierScript = Get-ScriptDirectory #Dossier des scripts
. (Join-Path ($dossierScript) "logFront.ps1") #On charge le script de log synfony
. (Join-Path ($dossierScript) "Logphp.ps1") #On charge le script de log php
$configFile = 	Join-Path ($dossierScript) "Config.xml" #On récupère le fichier de config
[xml] $XmlConfig = gc $configFile #On charge le xml
$phpConf = $XmlConfig.configuration.php_conf #On recupère la config php
$symfConf = $XmlConfig.configuration.symfony_conf 


    # Création d'un fichier Log C:\temp\[SCRIPTNAME]_[YYYY_MM_DD].log
$dateDuJour = Get-Date -uformat %Y_%m_%d_%H
$logName = 'C:\temp\' + ($([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition))).ToUpper() + ".log"

# Démarrage du log
Start-Transcript $logName -Append



	logFront($symfConf)
    $formassembly = [System.AppDomain]::CurrentDomain.GetAssemblies()
    write-host $formassembly.Count    
    foreach($fa in $formassembly)
    {
        write-host $fa
    }
    write-host $ExecutionContext
    write-host $$
    write-host $PWD
	LogPHP($phpConf)


    # Arrêt du log
Stop-Transcript

# On met dans le transcript les retour à la ligne nécessaire à notepad
#Get-Content $logName | Out-File $logName -Append


