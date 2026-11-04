$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
try {
 Add-Type -AssemblyName System.Speech
 $recognizers = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers()
 $r = $recognizers | Where-Object {$_.Culture.Name -eq 'pt-BR'} | Select-Object -First 1
 if (!$r) { $r = $recognizers | Select-Object -First 1 }
 if (!$r) { throw 'Instale um idioma de reconhecimento de fala nas configuracoes do Windows, ou digite a palavra.' }
 $engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine -ArgumentList $r
 $engine.LoadGrammar((New-Object System.Speech.Recognition.DictationGrammar))
 $engine.SetInputToDefaultAudioDevice()
 $result = $engine.Recognize([TimeSpan]::FromSeconds(7))
 if ($result) { @{text=$result.Text} | ConvertTo-Json -Compress }
 else { @{error='Nao ouvi uma palavra. Tente de novo ou digite.'} | ConvertTo-Json -Compress }
 $engine.Dispose()
} catch { @{error=$_.Exception.Message} | ConvertTo-Json -Compress }
