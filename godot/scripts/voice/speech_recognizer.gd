class_name SpeechRecognizer
extends Node
signal status_changed(data: Dictionary)
signal recognized(text: String)
var worker_pid=-1
var folder=""
var sequence=0
var elapsed=0.0
var last_text=""
var state={"state":"disabled","level":0,"error":"Voz offline nao iniciada."}
var device=-1
var model_path=""
func launch(selected_model="") -> void:
 shutdown()
 folder=ProjectSettings.globalize_path("user://voice_session")
 DirAccess.make_dir_recursive_absolute(folder)
 for f in ["status.json","command.json"]:
  if FileAccess.file_exists(folder+"/"+f):DirAccess.remove_absolute(folder+"/"+f)
 var base=OS.get_executable_path().get_base_dir() if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://")
 model_path=selected_model if not selected_model.is_empty() else base+"/models/vosk-model-small-pt-0.3"
 var binary=base+"/voice/recognizer.exe"
 if OS.get_name()=="Windows" and FileAccess.file_exists(binary):
  worker_pid=OS.create_process(binary,["--session",folder,"--model",model_path],false)
 else:
  var script=base+"/voice/recognizer.py"
  worker_pid=OS.create_process("python3",[script,"--session",folder,"--model",model_path],false)
 state={"state":"loading","level":0,"error":"Carregando reconhecimento offline..."}
 status_changed.emit(state)
func command(action: String) -> void:
 if folder.is_empty():return
 sequence+=1
 var temp=folder+"/command.tmp"
 var f=FileAccess.open(temp,FileAccess.WRITE)
 if f:
  f.store_string(JSON.stringify({"seq":sequence,"action":action,"device":device}));f.close()
  DirAccess.rename_absolute(temp,folder+"/command.json")
func _process(dt: float) -> void:
 elapsed+=dt
 if elapsed<.12 or folder.is_empty():return
 elapsed=0
 var path=folder+"/status.json"
 if not FileAccess.file_exists(path):
  if worker_pid>0 and not OS.is_process_running(worker_pid):
   state={"state":"error","level":0,"error":"Backend de voz indisponivel. Instale o modelo e dependencias; texto continua funcionando."};status_changed.emit(state)
  return
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary:return
 state=data;status_changed.emit(state)
 var text=str(data.get("text",""))
 if not text.is_empty() and text!=last_text:
  last_text=text;recognized.emit(text)
 if data.get("state","")=="listening":last_text=""
func shutdown() -> void:
 if worker_pid>0 and OS.is_process_running(worker_pid):OS.kill(worker_pid)
 worker_pid=-1
func _exit_tree() -> void:shutdown()
