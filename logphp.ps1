function logPHP
{
	param($pc)
	
$path_log_php = $pc.path_log_php #Dossier des logs d'erreurs php
$path_log_cache = $pc.path_log_cache_php #Dossier du cache des erreurs php
$file_log_cache = $pc.file_log_cache_php #dernier fichier de log php copier dans le cache

$mailto = ""
	if($pc.mail_to.mail.Count -gt 1)
	{
	 	$ci = 1
		foreach($m in $pc.mail_to.mail)
		{
			if($ci -eq 1)
			{
				$mailto = $m 
				$ci = $ci + 1
			}
			else
			{
				$mailto += "," + $m
			}
			
		}
	}

#tableau de parametre pour l'envoi d'e-mail
$MailParam = @{
    From = $pc.mail_from #e-mail expediteur
    To = $mailto #e-mail destinataire
    Subject = ($pc.text_object_php) -f (gc env:computername) #objet du mail
    Body = ($pc.text_content_php) -f (gc env:computername)  #corps du mail
    Attachment= $NULL #piece jointe
    SmtpServer = $pc.serveur #serveur SMTP
    Priority = "High" #priorité
    BodyAsHtml = $true #corps du mail en html
    Encoding = New-Object System.Text.utf8encoding #encodage UTF8
}
       

	 	Write-Host  -ForegroundColor BLUE "--------DEBUT CHECK LOG PHP--------"

    $res = Test-Path $file_log_cache   #On vérifie qu'il y a un fichier de log dans le cache
    
    if($False -eq $res) #Si ce fichier n'existe pas 
    {
    		Write-Host  -ForegroundColor GREEN "INFO: Le fichier n'est présent dans le cache"
		
        $file = Get-ChildItem -Path $path_log_php -recurse -include *.log | Sort-Object -Property LastWriteTime | Select-Object -Last 1 #on recupere le dernier fichier de log modifié dans le dossier de log

        Copy-Item -Path $file -destination $path_log_cache #on copie le fichier dans le cache
        
        $MailParam['Attachment'] = $file_log_cache #le fichier existe dans le cache on peut l'affecter en piece jointe
    
    }
    else #Si le fichier existe
    {   
        	Write-Host  -ForegroundColor BLUE "INFO: Le fichier est présent dans le cache"
		
        $fileCache = Get-ChildItem -Path $file_log_cache   #On recupere le dernier fichier de log dans le cache
        
        $fContent = Get-Content($fileCache) #on recupere son contenu
        
        if($fcontent.Length -eq $NULL) #Si le fichier est vide
        {
            $nbLigneCache = 0; #alors 0 ligne
        }
        else
        {
            $nbLigneCache = $fcontent.Length #sinon on recupere son nombre de lignes
        }
        
			 Write-Host -ForegroundColor GREEN "INFO:" $nbLigneCache " lignes en cache"
         
        $fileLog = Get-ChildItem -Path $path_log_php -recurse -include *.log | Sort-Object -Property LastWriteTime | Select-Object -Last 1 #on recupere le dernier fichier de log modifié dans le dossier de log
        $FLContent = Get-Content($fileLog) #on recupere son contenu
        $nbLigneLog = $FLContent.Length #sinon on recupere son nombre de lignes
        
		Write-Host -ForegroundColor GREEN "INFO:" $nbLigneLog  " lignes loggées"
        Write-Host  -ForegroundColor GREEN "INFO:" ($nbLigneLog - $nbLigneCache) " lignes de difference" 
        
        if($nbLigneLog -gt $nbLigneCache) #si le nombre de ligne du fichier log est superieur au nombre de ligne dans le fichier de cache
        {
			Write-Host  -ForegroundColor BLUE "INFO: lignes en log superieures aux lignes en cache" 
		
            $tab = @() #tableau des dernieres lignes de log
            $i = $nbLigneCache #iterateur initialisé a partir du nombre de ligne dans le cache
            $dat = Get-Date -Format 'ddMMyyhhmmss' #date de l'instant t
            
            
            $dest = $path_log_cache + $dat + '.log' #nom du fichier à attacher en piece jointe
			
				Write-Host -ForegroundColor BLUE "INFO: creation de la pièce-jointe en cache: " $dest
			
            Copy-Item -Path $fileLog -destination $dest #on créé ce fichier dans le cache
            
            
            While($i -lt $nbLigneLog) #tant que l'iterateur est inferieur au nombre de lignes dans le fichier de log
            {
                $tab += $FLContent[$i++]         #on ajoute la ligne dans le tableau       
            }
			
			Write-Host  -ForegroundColor YELLOW "INFO:" $tab.Count "lignes à mettre en cache et envoyer"
			
            Set-Content -Path $dest -Value $tab #on ajoute les lignes recuperer dans le fichier instant<t>.log du cache
            Copy-Item -Path $fileLog -destination $path_log_cache #on copie dans le cache le dernier fichier de log
            
            $MailParam['Attachment'] = $dest #on affecte le fichier du cache en piece jointe
        }
        else
        {
        
            if($nbLigneLog -lt $nbLigneCache)
            {
			
				Write-Host  -ForegroundColor GREEN "INFO: lignes en log inferieures aux lignes en cache, mise en cache du dernier fichier de log"
				
                $file = Get-ChildItem -Path $path_log_php -recurse -include *.log | Sort-Object -Property LastWriteTime | Select-Object -Last 1 #on recupere le dernier fichier de log modifié dans le dossier de log

                Copy-Item -Path $file -destination $path_log_cache #on copie le fichier dans le cache
                
                $MailParam['Attachment'] = $file_log_cache #le fichier existe dans le cache on peut l'affecter en piece jointe 
            } 
			else
			{
				if($nbLigneLog -eq $nbLigneCache)
				{
					Write-Host  -ForegroundColor GREEN "INFO: lignes en log égales aux lignes en cache pas de nouvelle erreur"
					$MailParam['Attachment'] = $null 
				}
			}
        }
        
    }
    if($MailParam['Attachment'] -ne $NULL) #Si la piece jointe est définie
    {	
		Write-Host  -ForegroundColor BLUE "INFO: envoi du mail:" @MailParam
       
        	$message = new-object System.Net.Mail.MailMessage
        	$message.From = $Mailparam['From']
			$message.To.add($Mailparam['To'])
			$message.Subject = $Mailparam['Subject']
			$message.Body = $Mailparam['Body']
			$message.IsBodyHtml = $Mailparam['BodyAsHtml'] 
        	$message.BodyEncoding  = $Mailparam['Encoding'] 
        	$message.Priority = $Mailparam['Priority']
        	$attachment = new-object System.Net.Mail.Attachment $Mailparam['Attachment']
        	$message.Attachments.Add($attachment)
        	$SMTPclient = new-object System.Net.Mail.SmtpClient $Mailparam['SmtpServer']
        	$SMTPclient.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials 

        	$SMTPclient.Send($message)
			
			Start-Sleep -s 30
    }
	else
	{
		Write-Host  -ForegroundColor GREEN "INFO: Pas de mail envoyé."
	}

	Write-Host -ForegroundColor BLUE "--------FIN CHECK LOG PHP--------"

}


