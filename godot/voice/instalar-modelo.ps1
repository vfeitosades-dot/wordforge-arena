$ErrorActionPreference='Stop'
$base=Split-Path -Parent $PSScriptRoot
$models=Join-Path $base 'models'
New-Item -ItemType Directory -Force $models | Out-Null
$zip=Join-Path $models 'portugues.zip'
Write-Host 'Baixando o modelo Vosk portugues oficial. Necessario somente na instalacao.'
Invoke-WebRequest 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip' -OutFile $zip
Expand-Archive $zip -DestinationPath $models -Force
Remove-Item $zip
Write-Host 'Modelo instalado. O reconhecimento funciona localmente, sem API ou internet.'
