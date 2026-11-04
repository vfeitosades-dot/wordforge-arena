extends Node3D
const WorldScript=preload("res://scripts/voxel/voxel_world.gd")
const PlayerScript=preload("res://scripts/gameplay/player.gd")
const EntityScript=preload("res://scripts/gameplay/creation_entity.gd")
const Parser=preload("res://scripts/creation/intent_parser.gd")
const Graph=preload("res://scripts/creation/composition_graph.gd")
const Bounds=preload("res://scripts/physics/physics_binder.gd")
const Cost=preload("res://scripts/creation/cost_calculator.gd")
const Validator=preload("res://scripts/creation/creation_validator.gd")
const Speech=preload("res://scripts/voice/speech_recognizer.gd")
const Factory=preload("res://scripts/creation/object_factory.gd")
var world
var players={}
var entities={}
var player_names={}
var inputs={}
var input_times={}
var portal_cooldowns={}
var extract_progress={}
var next_entity=0
var running=false
var net_mode="solo"
var local_id=1
var menu: PanelContainer
var hud: Label
var feedback: Label
var command_box: LineEdit
var name_box: LineEdit
var ip_box: LineEdit
var mic_label: Label
var model_box: LineEdit
var device_box: OptionButton
var help_label: Label
var speech
var yaw=0.0
var pitch=0.0
var sensitivity=.0025
var extraction=true
var voice_pressed=-1.0
var voice_started=false
var voice_ready=false
var status_text=""
var snapshot_clock=0.0
var input_clock=0.0
var fx=[]
var projectiles=[]
var bot_enabled=false
var bot_clock=0.0
var bot_state="collect"
var round_time=0.0
var third_person=false
var menu_status: Label
func _ready() -> void:
 _lighting()
 world=WorldScript.new();world.name="VoxelWorld";add_child(world);world.generate()
 _interface()
 speech=Speech.new();add_child(speech);speech.status_changed.connect(_voice_status);speech.recognized.connect(_voice_text)
 multiplayer.peer_connected.connect(_peer_connected)
 multiplayer.peer_disconnected.connect(_peer_disconnected)
 multiplayer.connected_to_server.connect(_connected)
 multiplayer.connection_failed.connect(func():menu_status.text="Falha de conexao. Confira IP, porta UDP 26077 e firewall.")
 multiplayer.server_disconnected.connect(func():_leave();menu_status.text="Servidor desconectado.")
 if "--smoke" in OS.get_cmdline_user_args():
  _start_solo(false)
  get_tree().create_timer(2).timeout.connect(func():print("VOXMATERIA_EXE_SMOKE_OK");get_tree().quit())
func _lighting() -> void:
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("9ebfe5");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("e3eeff");e.ambient_light_energy=.65;env.environment=e;add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-30,0);sun.light_color=Color("fff1d9");sun.light_energy=1.4;sun.shadow_enabled=true;add_child(sun)
func _button(text: String,callable: Callable,parent: Node) -> Button:
 var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,38);b.pressed.connect(callable);parent.add_child(b);return b
func _interface() -> void:
 var layer=CanvasLayer.new();add_child(layer)
 var root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
 menu=PanelContainer.new();menu.position=Vector2(28,24);menu.custom_minimum_size=Vector2(530,0);root.add_child(menu)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",7);menu.add_child(col)
 var title=Label.new();title.text="VOXMATERIA\nImagine. Extraia. Construa.";title.add_theme_font_size_override("font_size",26);col.add_child(title)
 name_box=LineEdit.new();name_box.text="Criador";name_box.placeholder_text="Seu nome";col.add_child(name_box)
 var row=HBoxContainer.new();col.add_child(row)
 _button("Jogar solo",func():_start_solo(false),row)
 _button("Solo + bot",func():_start_solo(true),row)
 _button("Criar sala",_host,row)
 ip_box=LineEdit.new();ip_box.text="127.0.0.1";ip_box.placeholder_text="IP do anfitriao";col.add_child(ip_box)
 _button("Entrar na sala por IP · UDP 26077",_join,col)
 var desc=Label.new();desc.text="PTT: segure V para falar · toque V: extracao\nT: digitar · WASD: mover · espaco: pular · Shift: correr\nC: agachar · E: jetpack proximo · F5: camera · Esc: menu";col.add_child(desc)
 _button("Como jogar / catalogo",_show_help,col)
 model_box=LineEdit.new();model_box.placeholder_text="Pasta do modelo Vosk (vazio = models/vosk-model-small-pt-0.3)";col.add_child(model_box)
 device_box=OptionButton.new();device_box.add_item("Microfone padrao",-1);device_box.item_selected.connect(func(i):speech.device=device_box.get_item_id(i));col.add_child(device_box)
 _button("Iniciar / diagnosticar voz offline",func():speech.launch(model_box.text),col)
 mic_label=Label.new();mic_label.text="Voz: nao iniciada. O texto funciona sem modelo.";col.add_child(mic_label)
 _button("Voltar ao jogo",_resume,col)
 _button("Sair do aplicativo",func():get_tree().quit(),col)
 menu_status=Label.new();menu_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;menu_status.custom_minimum_size=Vector2(500,0);col.add_child(menu_status)
 hud=Label.new();hud.position=Vector2(22,18);hud.add_theme_font_size_override("font_size",18);root.add_child(hud)
 feedback=Label.new();feedback.position=Vector2(22,100);feedback.custom_minimum_size=Vector2(1000,70);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(feedback)
 var cross=Label.new();cross.text="+";cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cross.add_theme_font_size_override("font_size",27);root.add_child(cross)
 command_box=LineEdit.new();command_box.position=Vector2(180,600);command_box.custom_minimum_size=Vector2(860,42);command_box.placeholder_text="Ex.: tres patos gigantes orbitando que lancam bolas de tinta";command_box.max_length=350;command_box.visible=false;command_box.text_submitted.connect(_submit_text);command_box.text_changed.connect(_estimate);root.add_child(command_box)
 help_label=Label.new();help_label.position=Vector2(580,32);help_label.custom_minimum_size=Vector2(650,0);help_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;help_label.visible=false;root.add_child(help_label)
 hud.visible=false;feedback.visible=false
func _show_help() -> void:
 help_label.visible=not help_label.visible
 help_label.text="CICLO DE JOGO\n1. Mire em blocos e segure o clique em EXTRACAO.\n2. Colete materia (5 por bloco).\n3. Segure V e fale, ou use T para digitar.\n4. O servidor interpreta, calcula custo e cria.\n5. Use o equipamento com clique; toque V alterna o modo.\n\nCATALOGO COMBINAVEL\nrobo, pato, pombo, cachorro, gato, drone, aranha, gelatina, golem, fantasma; cubo, bola, parede, plataforma, torre, carro, lancador, escudo, portal, buraco negro, jetpack, arvore.\nModificadores: gigante, pequeno, rapido, lento, voador, seguidor, orbitante, saltitante, giratorio, luminoso.\nEmissores: 'lanca cubos', 'dispara bolas de tinta', 'lanca passaros'.\nHabilidades: 'quero voar', 'quero pular mais alto', 'quero correr rapido', 'quero ficar invisivel'.\n\nExemplos:\ncinco cubos\num robo voador que lanca bolas de tinta\ntres patos orbitando\num cubo que lanca passaros\num passaro que lanca cubos\num portal (cria um par)\n\nVoz precisa do modelo local instalado; nenhuma API paga. Pedidos fora do catalogo nao sao apresentados como sucesso."
func _resume() -> void:
 if not running:return
 if DisplayServer.get_name()!="headless" and speech.worker_pid<0:speech.launch(model_box.text)
 menu.visible=false;help_label.visible=false;hud.visible=true;feedback.visible=true;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _leave() -> void:
 running=false;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;multiplayer.multiplayer_peer=null
 for p in players.values():p.queue_free()
 for e in entities.values():e.queue_free()
 players.clear();entities.clear();inputs.clear();player_names.clear();projectiles.clear();portal_cooldowns.clear()
 menu.visible=true;hud.visible=false;feedback.visible=false
func _start_solo(bot: bool) -> void:
 if running:_leave()
 local_id=1;net_mode="solo";bot_enabled=bot;_add_player(1,name_box.text);running=true
 if bot:_add_player(99,"Eco · bot");players[99].position=Vector3(7,1,0)
 _resume();_notice("Comece extraindo blocos. Voce inicia com 0 materia. T abre o pedido.")
func _host() -> void:
 if running:_leave()
 var peer=ENetMultiplayerPeer.new();var err=peer.create_server(26077,3)
 if err!=OK:menu_status.text="Nao foi possivel abrir UDP 26077.";return
 multiplayer.multiplayer_peer=peer;local_id=1;net_mode="host";bot_enabled=false;_add_player(1,name_box.text);running=true;_resume();_notice("Sala criada: UDP 26077. Compartilhe o IP da sua rede.")
func _join() -> void:
 if running:_leave()
 var peer=ENetMultiplayerPeer.new();var err=peer.create_client(ip_box.text.strip_edges(),26077)
 if err!=OK:menu_status.text="IP ou conexao invalidos.";return
 multiplayer.multiplayer_peer=peer;net_mode="client";menu_status.text="Conectando...";bot_enabled=false
func _connected() -> void:
 local_id=multiplayer.get_unique_id();running=true;_request_join.rpc_id(1,name_box.text);_resume()
func _peer_connected(_id: int) -> void:pass
func _peer_disconnected(id: int) -> void:
 if players.has(id):players[id].queue_free();players.erase(id)
 player_names.erase(id);inputs.erase(id)
 if multiplayer.is_server():_player_left.rpc(id)
@rpc("authority","call_remote","reliable")
func _player_left(id: int) -> void:
 if players.has(id):players[id].queue_free();players.erase(id)
func _add_player(id: int,label: String) -> void:
 if players.has(id):return
 var p=PlayerScript.new();p.setup(id,id==local_id);add_child(p);p.position=Vector3(-3+players.size()*2.0,2,8);players[id]=p;player_names[id]=label.left(18)
@rpc("any_peer","call_remote","reliable")
func _request_join(label: String) -> void:
 if not multiplayer.is_server():return
 var id=multiplayer.get_remote_sender_id()
 if players.size()>=4:return
 _add_player(id,label)
 var existing=[]
 for e in entities.values():existing.append({"id":e.entity_id,"owner":e.owner_id,"g":e.graph,"p":[e.position.x,e.position.y,e.position.z],"yaw":e.rotation.y})
 _initial_state.rpc_id(id,world.encoded_changes(),player_names,existing)
 _player_joined.rpc(id,label)
@rpc("authority","call_remote","reliable")
func _initial_state(changes: Array,names: Dictionary,creations: Array) -> void:
 world.apply_changes(changes);world.rebuild_all()
 for id in names:_add_player(int(id),str(names[id]))
 for e in creations:_spawn_entity(e.id,e.owner,e.g,e.p,e.yaw)
@rpc("authority","call_remote","reliable")
func _player_joined(id: int,label: String) -> void:_add_player(id,label)
func _notice(message: String) -> void:
 status_text=message;feedback.text=message
@rpc("authority","call_remote","reliable")
func _feedback_message(message: String) -> void:_notice(message)
func notify(id: int,message: String) -> void:
 if id==local_id:_notice(message)
 elif net_mode!="solo":_feedback_message.rpc_id(id,message)
func _submit_text(text: String) -> void:
 command_box.visible=false;command_box.release_focus();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 if not running:return
 if net_mode=="client":_request_creation.rpc_id(1,text)
 else:_create_for(local_id,text)
func _estimate(text: String) -> void:
 var g=Parser.parse(text)
 if g.ok:_notice("Custo estimado: %d materia · %d entidade(s)" % [Cost.calculate(g),g.quantity])
 else:_notice(g.error)
func _voice_text(text: String) -> void:
 if running:_submit_text(text)
 else:menu_status.text="Reconhecido: "+text
func _voice_status(data: Dictionary) -> void:
 voice_ready=data.get("state","")=="ready"
 var level=int(float(data.get("level",0))*20)
 mic_label.text="Voz: %s  %s\n%s" % [data.get("state",""),"|".repeat(level),data.get("error",data.get("partial",""))]
 if data.get("state","")=="listening":_notice("OUVINDO · "+str(data.get("partial",""))+"  "+"|".repeat(level))
 if data.has("devices") and device_box.item_count==1:
  for d in data.devices:device_box.add_item(d.name,int(d.id))
@rpc("any_peer","call_remote","reliable")
func _request_creation(text: String) -> void:
 if not multiplayer.is_server():return
 _create_for(multiplayer.get_remote_sender_id(),text)
func _create_for(id: int,text: String) -> void:
 if not players.has(id):return
 var g=Graph.from_text(text)
 if not g.ok:notify(id,g.error);return
 if g.kind=="portal":g.quantity=2
 g.cost=Cost.calculate(g)
 var error=Validator.validate(g,players[id].matter,entities.size())
 if not error.is_empty():notify(id,error);return
 var p=players[id]
 if g.kind=="ability" or g.kind=="jetpack":
  p.matter-=g.cost;p.ability=g.ability;p.ability_time=g.duration;notify(id,"Habilidade ativa: %s · %ds · custo %d" % [g.ability,g.duration,g.cost]);return
 if g.kind=="launcher":
  p.matter-=g.cost;p.equipped=g;extraction=false if id==local_id else extraction
  if id==local_id:_equipped(g)
  elif net_mode!="solo" and id!=99:_equipped.rpc_id(id,g)
  notify(id,"Equipado: %s · custo %d. Toque V para alternar extracao/uso." % [text,g.cost]);return
 var positions=[]
 var forward=-p.transform.basis.z
 for i in int(g.quantity):
  var pos=p.position+forward*(5+float(i)*1.8)+Vector3.RIGHT*(float(i)-float(g.quantity-1)/2)*2.5
  if g.kind=="portal":pos=p.position+forward*(5+i*8)+p.transform.basis.x*i*4
  if "fly" in g.mods or "orbit" in g.mods:pos.y+=2
  var query=PhysicsShapeQueryParameters3D.new();var shape=BoxShape3D.new();shape.size=Bounds.bounds(g)*.94;query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,p.yaw),pos+Vector3.UP*shape.size.y*.5+Vector3.UP*.08);query.exclude=[p.get_rid()]
  var overlaps=get_world_3d().direct_space_state.intersect_shape(query,4)
  if not overlaps.is_empty():
   print("PLACEMENT_DENIED ",id," player=",p.position," target=",pos," collider=",overlaps[0].collider.name)
   notify(id,"Local ocupado. Mire para um espaco livre e tente novamente.");return
  positions.append(pos)
 p.matter-=g.cost
 var pair=[]
 for pos in positions:
  next_entity+=1;pair.append(next_entity)
  var point=[pos.x,pos.y,pos.z]
  if net_mode!="solo":_spawn_entity.rpc(next_entity,id,g,point,p.yaw)
  else:_spawn_entity(next_entity,id,g,point,p.yaw)
 if g.kind=="portal" and pair.size()==2:
  entities[pair[0]].paired_id=pair[1];entities[pair[1]].paired_id=pair[0]
 notify(id,"Criacao concluida: %s · %d entidade(s) · custo %d" % [text,g.quantity,g.cost])
@rpc("authority","call_remote","reliable")
func _equipped(g: Dictionary) -> void:
 if not players.has(local_id):return
 var p=players[local_id];p.equipped=g;extraction=false
 if p.camera.has_node("Equipped"):p.camera.get_node("Equipped").queue_free()
 var body=StaticBody3D.new();body.name="Equipped";body.collision_layer=0;body.collision_mask=0;Factory.build(body,g);body.position=Vector3(.3,-.25,-.65);body.scale=Vector3.ONE*.4;p.camera.add_child(body)
@rpc("authority","call_local","reliable")
func _spawn_entity(id: int,owner: int,g: Dictionary,point: Array,angle: float) -> void:
 if entities.has(id):return
 var e=EntityScript.new();e.configure(g,id,owner,self,net_mode!="client");add_child(e);e.position=Vector3(point[0],point[1],point[2]);e.rotation.y=angle;e.original_y=e.position.y;entities[id]=e;_burst(e.position+Vector3.UP,Color(g.color),12)
func remove_entity(id: int) -> void:
 if net_mode!="solo":_remove_entity.rpc(id)
 else:_remove_entity(id)
@rpc("authority","call_local","reliable")
func _remove_entity(id: int) -> void:
 if entities.has(id):entities[id].queue_free();entities.erase(id)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and running and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  yaw-=event.relative.x*sensitivity;pitch=clampf(pitch-event.relative.y*sensitivity,-1.4,1.4)
 if event is InputEventKey and not event.echo:
  if event.keycode==KEY_ESCAPE and event.pressed:
   if running:
    menu.visible=not menu.visible;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if menu.visible else Input.MOUSE_MODE_CAPTURED
   speech.command("cancel")
  if not running or menu.visible:return
  if event.keycode==KEY_T and event.pressed:
   command_box.visible=true;command_box.grab_focus();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  if event.keycode==KEY_F5 and event.pressed:
   third_person=not third_person
   if players.has(local_id):players[local_id].camera.position.z=4 if third_person else 0;players[local_id].third_person=third_person;players[local_id].body_mesh.visible=third_person
  if event.keycode==KEY_V:
   if event.pressed:voice_pressed=Time.get_ticks_msec()/1000.0;voice_started=false
   elif voice_pressed>=0:
    if voice_started:speech.command("stop");_notice("Interpretando comando...")
    else:extraction=not extraction
    voice_pressed=-1
func _controls() -> Dictionary:
 var enabled=running and not menu.visible and not command_box.visible
 return {"x":(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))) if enabled else 0.0,"z":(float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))) if enabled else 0.0,"yaw":yaw,"pitch":pitch,"jump":enabled and Input.is_physical_key_pressed(KEY_SPACE),"run":enabled and Input.is_physical_key_pressed(KEY_SHIFT),"down":enabled and Input.is_physical_key_pressed(KEY_CTRL),"crouch":enabled and Input.is_physical_key_pressed(KEY_C),"use":enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),"extract":extraction}
@rpc("any_peer","call_remote","unreliable")
func _send_input(data: Dictionary) -> void:
 if not multiplayer.is_server():return
 var id=multiplayer.get_remote_sender_id()
 if not players.has(id):return
 var safe={}
 for k in ["x","z","yaw","pitch"]:
  var value=float(data.get(k,0));safe[k]=clampf(value,-1000,1000) if is_finite(value) else 0
 safe.x=clampf(safe.x,-1,1);safe.z=clampf(safe.z,-1,1)
 for k in ["jump","run","down","crouch","use","extract"]:safe[k]=bool(data.get(k,false))
 inputs[id]=safe;input_times[id]=Time.get_ticks_msec()
func _physics_process(dt: float) -> void:
 if not running:return
 var controls=_controls()
 if net_mode=="client":
  if players.has(local_id):players[local_id].simulate(dt,controls)
  input_clock+=dt
  if input_clock>.035:_send_input.rpc_id(1,controls);input_clock=0
 else:
  inputs[local_id]=controls
  if bot_enabled:_bot(dt)
  for id in players:
   var data=inputs.get(id,{})
   if id!=local_id and id!=99 and Time.get_ticks_msec()-int(input_times.get(id,0))>600:data={}
   players[id].simulate(dt,data)
   if data.get("use",false):_use(id,dt,data.get("extract",true))
   else:extract_progress[id]=0.0
  _projectile_step(dt)
  snapshot_clock+=dt
  if net_mode=="host" and snapshot_clock>.06:
   snapshot_clock=0;var ps=[];var es=[]
   for p in players.values():
    var data=p.snapshot();data["extract"]=extract_progress.get(p.peer_id,0);ps.append(data)
   for e in entities.values():es.append(e.snapshot())
   _snapshot.rpc(ps,es)
  for id in portal_cooldowns.keys():
   portal_cooldowns[id]-=dt
   if portal_cooldowns[id]<=0:portal_cooldowns.erase(id)
 if voice_pressed>=0 and not voice_started and Time.get_ticks_msec()/1000.0-voice_pressed>.22:
  voice_started=true
  if voice_ready:speech.command("start")
  else:_notice("Voz offline indisponivel. Abra Esc > diagnostico ou use T.")
 _update_hud()
@rpc("authority","call_remote","unreliable")
func _snapshot(ps: Array,es: Array) -> void:
 for data in ps:
  if players.has(data.id):players[data.id].apply_snapshot(data)
  if data.id==local_id:extract_progress[local_id]=data.get("extract",0)
 for data in es:
  if entities.has(data.id):
   var e=entities[data.id];e.position=e.position.lerp(Vector3(data.p[0],data.p[1],data.p[2]),.65);e.rotation=Vector3(data.r[0],data.r[1],data.r[2])
func _use(id: int,dt: float,extract: bool) -> void:
 var p=players[id]
 if not extract and not p.equipped.is_empty():
  if p.cooldown<=0:p.cooldown=.4;_shoot(p.camera.global_position,p.look_direction(),p.equipped.emitter,id)
  return
 var from=p.camera.global_position
 var query=PhysicsRayQueryParameters3D.create(from,from+p.look_direction()*7);query.exclude=[p.get_rid()]
 var hit=get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty() or not hit.collider.has_meta("voxel"):extract_progress[id]=0;return
 extract_progress[id]=float(extract_progress.get(id,0))+dt
 if extract_progress[id]<.3:return
 extract_progress[id]=0
 var cell=Vector3i((hit.position-hit.normal*.04).floor())
 if not world.blocks.has(cell):return
 var edits=[[cell.x,cell.y,cell.z,-1]];world.set_block(cell,-1);edits.append_array(world.collapse_above(cell));p.matter+=5
 if net_mode=="host":_terrain_edit.rpc(edits)
 _burst(Vector3(cell)+Vector3.ONE*.5,Color("d5be87"),6)
@rpc("authority","call_remote","reliable")
func _terrain_edit(edits: Array) -> void:world.apply_changes(edits)
func entity_fire(entity: Node) -> void:
 var target=null
 for p in players.values():
  if p.peer_id!=entity.owner_id and (target==null or p.position.distance_to(entity.position)<target.position.distance_to(entity.position)):target=p
 var direction=-entity.global_transform.basis.z
 if target:direction=(target.position+Vector3.UP-entity.position-Vector3.UP*1.2).normalized()
 _shoot(entity.position+Vector3.UP*1.3,direction,entity.graph.emitter,entity.owner_id)
func _shoot(origin: Vector3,direction: Vector3,emitter: Dictionary,owner: int) -> void:
 if projectiles.size()>90:return
 for i in int(emitter.get("count",1)):
  var dir=direction.rotated(Vector3.UP,(i-(float(emitter.get("count",1))-1)/2)*.09)
  var visual=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3.ONE*.22;visual.mesh=mesh;var mat=StandardMaterial3D.new();mat.albedo_color=Color(emitter.get("color","#efb978"));mat.emission_enabled=true;mat.emission=mat.albedo_color*.2;visual.material_override=mat;add_child(visual);visual.position=origin+dir*.8
  if emitter.get("kind","") in ["duck","pigeon"]:
   var beak=MeshInstance3D.new();var b=BoxMesh.new();b.size=Vector3(.15,.08,.18);beak.mesh=b;beak.position=Vector3(0,0,-.18);visual.add_child(beak)
  projectiles.append({"node":visual,"v":dir*22,"life":3.0,"owner":owner,"emitter":emitter,"bounces":0})
 if net_mode=="host":_shot_visual.rpc([origin.x,origin.y,origin.z],[direction.x,direction.y,direction.z],emitter,owner)
@rpc("authority","call_remote","unreliable")
func _shot_visual(origin: Array,direction: Array,emitter: Dictionary,owner: int) -> void:
 _shoot(Vector3(origin[0],origin[1],origin[2]),Vector3(direction[0],direction[1],direction[2]),emitter,owner)
func _projectile_step(dt: float) -> void:
 for shot in projectiles.duplicate():
  shot.life-=dt
  var old=shot.node.position;var end=old+shot.v*dt
  var query=PhysicsRayQueryParameters3D.create(old,end)
  if players.has(shot.owner):query.exclude=[players[shot.owner].get_rid()]
  var hit=get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():
   if shot.emitter.get("elastic",false) and shot.bounces<3:shot.v=shot.v.bounce(hit.normal);shot.bounces+=1;end=hit.position+hit.normal*.15
   else:
    shot.life=0;_burst(hit.position,Color(shot.emitter.get("color","#eaa1cc")),5)
    if net_mode!="client":
     if hit.collider.has_meta("voxel"):
      var cell=Vector3i((hit.position-hit.normal*.04).floor());world.set_block(cell,-1)
      if net_mode=="host":_terrain_edit.rpc([[cell.x,cell.y,cell.z,-1]])
     elif hit.collider is PlayerScript:
      var victim=hit.collider;victim.hp-=15
      if victim.hp<=0:
       victim.hp=100;victim.position=Vector3(5,3,8)
       if players.has(shot.owner):players[shot.owner].score+=1
     elif hit.collider is EntityScript:hit.collider.hp-=25
  shot.node.position=end
  if shot.life<=0:shot.node.queue_free();projectiles.erase(shot)
func _burst(pos: Vector3,color: Color,count: int) -> void:
 for i in mini(count,80-fx.size()):
  var mesh=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3.ONE*.12;mesh.mesh=box;mesh.position=pos;var m=StandardMaterial3D.new();m.albedo_color=color;mesh.material_override=m;add_child(mesh);fx.append({"node":mesh,"v":Vector3(randf_range(-2,2),randf_range(1,4),randf_range(-2,2)),"life":.6})
func _process(dt: float) -> void:
 if net_mode=="client":_projectile_step(dt)
 for particle in fx.duplicate():
  particle.life-=dt;particle.v.y-=10*dt;particle.node.position+=particle.v*dt
  if particle.life<=0:particle.node.queue_free();fx.erase(particle)
func _update_hud() -> void:
 if not players.has(local_id):return
 var p=players[local_id]
 var mode="EXTRACAO" if extraction else "EQUIPAMENTO"
 var bar="|".repeat(int(float(extract_progress.get(local_id,0))/.3*15))
 var scores=""
 for id in players:scores+="%s: %d   " % [player_names.get(id,"Jogador"),players[id].score]
 hud.text="VOXMATERIA · %s · materia %d · vida %d\n%s\n%s %s" % [net_mode,p.matter,p.hp,scores,mode,bar]
 if p.ability_time>0:hud.text+=" · %s %.0fs" % [p.ability,p.ability_time]
func _bot(dt: float) -> void:
 if not players.has(99):return
 var bot=players[99];var target=players.get(local_id);bot_clock+=dt
 if not target:return
 var delta=target.position-bot.position
 var desired=atan2(-delta.x,-delta.z)
 var state={"x":sin(bot_clock)*.4,"z":-.5 if delta.length()>7 else .3,"yaw":desired,"pitch":0.0,"jump":false,"use":false,"extract":true}
 if bot.matter<65:
  state.yaw=0.0;state.pitch=-.7;state.use=true;state.z=0.0;bot_state="collect"
 elif bot.equipped.is_empty():_create_for(99,"lancador de bolas");bot_state="equip"
 else:state.use=true;state.extract=false;bot_state="fight"
 if bot.hp<35:state.z=1;bot_state="retreat"
 if bot.position.y<.2 and absf(bot.velocity.x)+absf(bot.velocity.z)<.2:state.jump=true;state.x=1
 inputs[99]=state
