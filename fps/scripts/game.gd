extends Node3D
const Arena=preload("res://scripts/arena.gd")
const Tactical=preload("res://scripts/tactical.gd")
const Minimap=preload("res://scripts/minimap.gd")
const Fighter=preload("res://scripts/fighter.gd")
const GUNS=[{"name":"KESTREL / AR-7","model":"Kestrel","mag":25,"rate":.12,"damage":32.0,"reload":1.8},{"name":"WISP / P-9","model":"Wisp","mag":12,"rate":.24,"damage":28.0,"reload":1.8},{"name":"LONGBOW / MR-3","model":"Longbow","mag":8,"rate":.75,"damage":70.0,"reload":1.8}]
const AGENTS=[{"name":"SEREIN","role":"SUPORTE","color":"#79dec2","skill":"Pulso restaurador · recupera 35 de vida"},{"name":"ROOK","role":"SENTINELA","color":"#f59c76","skill":"Blindagem · reduz dano por 5 segundos"},{"name":"VESPER","role":"VANGUARDA","color":"#b7a1f0","skill":"Impulso · avanco rapido na direcao da camera"}]
var arena
var player
var camera: Camera3D
var view: Node3D
var weapon
var weapon_anim: AnimationPlayer
var showcase
var showcase_anim
var menu_camera: Camera3D
var agents=0
var gun=0
var mode=0
var map_index=0
var difficulty=1
var reaction_time=.45
var bot_spread=.055
var playing=false
var paused=false
var equipped_index=0
var yaw=0.0
var pitch=0.0
var sensitivity=.0022
var fov=78.0
var cooldown=0.0
var reload_time=0.0
var action_time=0.0
var ammo=[25,12,8]
var reserve=[150,96,48]
var enemies=[]
var kills=0
var deaths=0
var shots=0
var hits=0
var headshots=0
var wave=1
var skill_cd=0.0
var shield_time=0.0
var invulnerable=0.0
var clock=0.0
var recoil=0.0
var flashes=[]
var menu_root: Control
var settings_panel: Control
var hud: Control
var hud_text: Label
var ammo_label: Label
var match_label: Label
var notice: Label
var agent_desc: Label
var mode_box: OptionButton
var map_box: OptionButton
var agent_box: OptionButton
var gun_box: OptionButton
var diff_box: OptionButton
var tip: Label
var cross: Label
var hitmarker: Label
var hit_time=0.0
var settings=ConfigFile.new()
var title_card: Label
var tactical=Tactical.new()
var objective_label: Label
var buy_panel: PanelContainer
var buy_status: Label
var objective_model: Node3D
var lighting: WorldEnvironment
var beep_clock=0.0
func _ready() -> void:
 randomize();settings.load("user://aurora.cfg");sensitivity=settings.get_value("controls","sensitivity",.0022);fov=settings.get_value("controls","fov",78.0)
 var environment=WorldEnvironment.new();lighting=environment;var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("b7c9db");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d1e1f3");env.ambient_light_energy=.16;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=.9;environment.environment=env;add_child(environment)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_energy=.45;sun.shadow_enabled=true;sun.name="Sun";add_child(sun)
 arena=Arena.new();add_child(arena);arena.build(0)
 var studio=Arena.new();add_child(studio)
 studio.box(Vector3(-55,-.1,0),Vector3(14,.2,14),Color("243e50"))
 studio.box(Vector3(-55,3,-4),Vector3(14,7,.3),Color("20364a"))
 for x in [-58,-52]:studio.box(Vector3(x,2,-3.8),Vector3(.08,4,.08),Color("63af9c"),false)
 menu_camera=Camera3D.new();menu_camera.position=Vector3(4,1.6,5);menu_camera.current=true;menu_camera.fov=48;add_child(menu_camera)
 _ui();_preview(false)
 if "--smoke" in OS.get_cmdline_user_args():
  start_match();get_tree().create_timer(2).timeout.connect(func():print("AURORA_EXE_OK");get_tree().quit())
 if "--capture" in OS.get_cmdline_user_args():
  get_tree().create_timer(2).timeout.connect(func():get_viewport().get_texture().get_image().save_png("user://menu.png");start_match();get_tree().create_timer(2).timeout.connect(func():get_viewport().get_texture().get_image().save_png("user://game.png");get_tree().quit()))
func style(bg: Color,border: Color=Color.TRANSPARENT) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(5);s.content_margin_left=18;s.content_margin_right=18;s.content_margin_top=12;s.content_margin_bottom=12;return s
func label(text: String,size: int,color: Color,parent: Node) -> Label:
 var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_shadow_color",Color(0,0,0,.8));l.add_theme_constant_override("shadow_offset_y",1);l.add_theme_constant_override("outline_size",1);parent.add_child(l);return l
func button(text: String,fn: Callable,parent: Node,primary=false) -> Button:
 var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(0,38);b.add_theme_stylebox_override("normal",style(Color("79dec2") if primary else Color("192c3b"),Color("35505f")));b.add_theme_stylebox_override("hover",style(Color("96f4da") if primary else Color("2b4555")));b.add_theme_color_override("font_color",Color("102d2c") if primary else Color("e9f0f4"));b.pressed.connect(fn);parent.add_child(b);return b
func option(title: String,items: Array,parent: Node) -> OptionButton:
 label(title,11,Color("91aab7"),parent);var o=OptionButton.new();o.custom_minimum_size=Vector2(0,32);o.add_theme_stylebox_override("normal",style(Color("192c3b"),Color("35505f")))
 for item in items:o.add_item(item)
 parent.add_child(o);return o
func _ui() -> void:
 var canvas=CanvasLayer.new();add_child(canvas)
 menu_root=Control.new();menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(menu_root)
 var dark=ColorRect.new();dark.color=Color(.035,.065,.095,.96);dark.size=Vector2(565,720);menu_root.add_child(dark)
 var content=VBoxContainer.new();content.position=Vector2(44,22);content.size=Vector2(465,650);content.add_theme_constant_override("separation",6);menu_root.add_child(content)
 label("A / B     AURORA DIVISION",12,Color("79dec2"),content)
 title_card=label("AURORA\nBREACH",48,Color("edf4f5"),content)
 label("CONTROLE O ESPACO. ESCOLHA SEU RITMO.",10,Color("9db7c4"),content)
 var nav=HBoxContainer.new();content.add_child(nav)
 button("OPERADORES",func():_preview(false),nav);button("ARSENAL",func():_preview(true),nav);button("AJUSTES",func():settings_panel.visible=not settings_panel.visible,nav)
 mode_box=option("OPERACAO",["01   /   CONFRONTO · 15 eliminacoes","02   /   SOBREVIVENCIA · 3 ondas","03   /   ESTANDE · treino livre","04   /   RUPTURA · plantar / desarmar"],content)
 var row=HBoxContainer.new();content.add_child(row)
 var a=VBoxContainer.new();a.custom_minimum_size.x=226;row.add_child(a);var b=VBoxContainer.new();b.custom_minimum_size.x=226;row.add_child(b)
 map_box=option("ARENA",["Marina solar","Estacao boreal","Doca neon","Complexo verdant"],a);diff_box=option("BOTS",["Facil","Normal","Dificil"],b);diff_box.select(1)
 agent_box=option("OPERADOR",["Serein / suporte","Rook / sentinela","Vesper / vanguarda"],content);agent_box.item_selected.connect(func(i):agents=i;_preview(false))
 gun_box=option("EQUIPAMENTO INICIAL",["Kestrel · rifle","Wisp · pistola","Longbow · precisao"],content);gun_box.item_selected.connect(func(i):gun=i;_preview(true))
 agent_desc=label("",12,Color("b4cbd5"),content)
 button("ENTRAR NA ARENA     →",start_match,content,true)
 var bottom=HBoxContainer.new();content.add_child(bottom);button("CONTINUAR",resume,bottom);button("SAIR",func():get_tree().quit(),bottom)
 label("WASD mover · mouse mirar · R recarregar · E habilidade\n1/2/3 trocar · F inspecionar · Espaco pular · Esc menu",11,Color("819eae"),content)
 var stamp=label("OPERACAO / 01\n\nRECURSOS ORIGINAIS\nMODELADOS NO BLENDER",12,Color("f0f5f7"),menu_root);stamp.position=Vector2(1020,40)
 tip=label("SEREIN\nSUPORTE / AURORA DIVISION",24,Color("eaf4f5"),menu_root);tip.position=Vector2(710,570)
 settings_panel=PanelContainer.new();settings_panel.position=Vector2(580,100);settings_panel.custom_minimum_size=Vector2(400,0);settings_panel.add_theme_stylebox_override("panel",style(Color("102431")));settings_panel.visible=false;menu_root.add_child(settings_panel)
 var sc=VBoxContainer.new();sc.add_theme_constant_override("separation",14);settings_panel.add_child(sc);label("CONFIGURACOES",25,Color.WHITE,sc)
 label("Sensibilidade do mouse",13,Color.WHITE,sc);var s=HSlider.new();s.min_value=.0006;s.max_value=.006;s.step=.0001;s.value=sensitivity;s.value_changed.connect(func(v):sensitivity=v;_save());sc.add_child(s)
 label("Campo de visao",13,Color.WHITE,sc);var f=HSlider.new();f.min_value=65;f.max_value=100;f.value=fov;f.value_changed.connect(func(v):fov=v;if_camera_fov();_save());sc.add_child(f)
 label("Volume",13,Color.WHITE,sc);var volume=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=.05;volume.value=1;volume.value_changed.connect(func(v):AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,v))));sc.add_child(volume)
 button("Alternar tela cheia",func():DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN),sc)
 button("Sombras: alternar",func():get_node("Sun").shadow_enabled=not get_node("Sun").shadow_enabled,sc)
 button("Fechar",func():settings_panel.hide(),sc)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.visible=false;canvas.add_child(hud)
 for rect in [Rect2(20,620,330,80),Rect2(935,620,330,80),Rect2(20,15,480,78)]:
  var bg=ColorRect.new();bg.position=rect.position;bg.size=rect.size;bg.color=Color(.025,.06,.085,.85);hud.add_child(bg)
 hud_text=label("",22,Color("e6f4f0"),hud);hud_text.position=Vector2(32,640)
 ammo_label=label("",28,Color("e6f4f0"),hud);ammo_label.position=Vector2(960,630)
 match_label=label("",19,Color.WHITE,hud);match_label.position=Vector2(32,24)
 notice=label("",19,Color("79dec2"),hud);notice.position=Vector2(450,90)
 cross=label("+",30,Color("95f4dc"),hud);cross.position=Vector2(630,339)
 hitmarker=label("×",36,Color("ffe0af"),hud);hitmarker.position=Vector2(628,336);hitmarker.visible=false
 label("R RECARGA / E HABILIDADE / G PLANTAR / B COMPRAR / ESC MENU",10,Color("c4d5dc"),hud).position=Vector2(390,688)
 var minimap=Minimap.new();minimap.game=self;minimap.position=Vector2(1048,18);minimap.size=Vector2(200,200);minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(minimap)
 objective_label=label("",16,Color("ffe2a6"),hud);objective_label.position=Vector2(350,123)
 buy_panel=PanelContainer.new();buy_panel.position=Vector2(830,245);buy_panel.custom_minimum_size=Vector2(400,0);buy_panel.add_theme_stylebox_override("panel",style(Color("102431")));buy_panel.hide();hud.add_child(buy_panel)
 var buy_content=VBoxContainer.new();buy_content.add_theme_constant_override("separation",10);buy_panel.add_child(buy_content)
 label("PREPARACAO / ARSENAL",22,Color.WHITE,buy_content)
 buy_status=label("",15,Color("a7edda"),buy_content)
 button("KESTREL / 1000 creditos",func():_purchase("rifle"),buy_content)
 button("LONGBOW / 1400 creditos",func():_purchase("marksman"),buy_content)
 button("BLINDAGEM / 350 creditos",func():_purchase("armor"),buy_content)
 button("Fechar / B",func():buy_panel.hide();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED,buy_content)
func if_camera_fov() -> void:
 if is_instance_valid(camera):camera.fov=fov
func _save() -> void:
 settings.set_value("controls","sensitivity",sensitivity);settings.set_value("controls","fov",fov);settings.save("user://aurora.cfg")
func _preview(is_gun: bool) -> void:
 if is_instance_valid(showcase):remove_child(showcase);showcase.queue_free()
 var asset=GUNS[gun].model if is_gun else ["Serein","Rook","Vesper"][agents]
 showcase=load("res://assets/"+asset+".glb").instantiate();add_child(showcase);showcase.position=Vector3(-55.0,0,0);showcase.rotation.y=PI+.25
 if is_gun:showcase.position.y=1.1;showcase.scale=Vector3.ONE*2.2
 var finder=Fighter.new();showcase_anim=finder.find_anim(showcase);finder.free()
 if showcase_anim:showcase_anim.speed_scale=2.5
 if showcase_anim:
  for key in showcase_anim.get_animation_list():
   if key.ends_with("idle"):showcase_anim.get_animation(key).loop_mode=Animation.LOOP_LINEAR;showcase_anim.play(key)
  if not is_gun:
   for key in showcase_anim.get_animation_list():
    if key.ends_with("ability"):showcase_anim.play(key,.15)
 if showcase_anim:
  showcase_anim.animation_finished.connect(_preview_idle)
 menu_camera.position=Vector3(-56.7,1.35,4.8);menu_camera.look_at(Vector3(-56.7,1.0,0))
 if agent_desc:agent_desc.text=AGENTS[agents].skill
 if tip:tip.text=(GUNS[gun].name if is_gun else AGENTS[agents].name)+"\n"+("ARSENAL / FABRICACAO AURORA" if is_gun else AGENTS[agents].role+" / AURORA DIVISION")
func _preview_idle(_name: String) -> void:
 if not is_instance_valid(showcase_anim):return
 for key in showcase_anim.get_animation_list():
  if key.ends_with("idle"):showcase_anim.get_animation(key).loop_mode=Animation.LOOP_LINEAR;showcase_anim.play(key,.15)
func start_match() -> void:
 for e in enemies:
  if is_instance_valid(e):e.queue_free()
 enemies.clear()
 if is_instance_valid(player):player.queue_free()
 if is_instance_valid(arena):remove_child(arena);arena.queue_free()
 arena=Arena.new();add_child(arena);map_index=map_box.selected;arena.build(map_index);_map_lighting()
 mode=mode_box.selected;difficulty=diff_box.selected;reaction_time=[.8,.45,.26][difficulty];bot_spread=[.12,.06,.025][difficulty]
 kills=0;deaths=0;shots=0;hits=0;headshots=0;wave=1;clock=0;skill_cd=0;shield_time=0;invulnerable=2
 ammo=[25,12,8];reserve=[150,96,48];reload_time=0;cooldown=0;action_time=0
 player=Fighter.new();player.setup(self,true,agents);add_child(player);player.position=Vector3(-6,.05,20)
 camera=Camera3D.new();camera.position.y=1.6;camera.fov=fov;player.add_child(camera);camera.current=true
 view=Node3D.new();camera.add_child(view);view.position=Vector3(.24,-.26,-.65);_equip(gun_box.selected)
 yaw=0;pitch=0;playing=true;paused=false;menu_root.hide();hud.show();showcase.hide();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 for i in (4 if mode==0 else 2 if mode==1 else 5):_spawn_bot()
 notice.text="CONFRONTO · PRIMEIRO A 15" if mode==0 else "ONDA 1 / 3" if mode==1 else "TREINO LIVRE · BOTS SEM DISPARO"
 buy_panel.hide();objective_label.text=""
 if is_instance_valid(objective_model):objective_model.queue_free()
 if mode==3:tactical.start();_tactical_round()
func _spawn_bot() -> void:
 var bot=Fighter.new();bot.setup(self,false,randi()%3);add_child(bot)
 for i in range(100):
  bot.position=arena.spawn()
  if bot.position.distance_to(player.position)>10:break
 enemies.append(bot)
func resume() -> void:
 if not playing:return
 if mode==3:gun=equipped_index;gun_box.select(equipped_index)
 paused=false;menu_root.hide();settings_panel.hide();hud.show();camera.current=true;
 if equipped_index!=gun:_equip(gun)
 elif weapon_anim and not weapon_anim.is_playing():weapon_anim.play()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _equip(index: int) -> void:
 if mode==3 and playing and index!=tactical.bought and index!=1:return
 gun=index;equipped_index=index;reload_time=0;action_time=0
 if is_instance_valid(weapon):weapon.get_parent().remove_child(weapon);weapon.queue_free()
 weapon=load("res://assets/"+GUNS[gun].model+".glb").instantiate();view.add_child(weapon);weapon_anim=player.find_anim(weapon);weapon_anim.speed_scale=2.5;action_time=_clip("equip",false);_tone(500,.04,.08)
func _clip(clip: String,loop=false) -> float:
 if not weapon_anim:return .1
 for key in weapon_anim.get_animation_list():
  if key.to_lower().ends_with(clip):weapon_anim.get_animation(key).loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE;weapon_anim.play(key,.045);return weapon_anim.get_animation(key).length/weapon_anim.speed_scale
 return .1
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE and playing:
   paused=not paused;menu_root.visible=paused;hud.visible=not paused
   if paused:menu_camera.current=true;showcase.show();weapon_anim.pause();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   else:resume()
  if not playing or paused:return
  if event.keycode==KEY_B and mode==3:
   if tactical.phase=="buy":buy_panel.visible=not buy_panel.visible;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if buy_panel.visible else Input.MOUSE_MODE_CAPTURED
   else:notice.text="Compras apenas na preparacao."
  if event.keycode==KEY_R:_reload()
  if event.keycode==KEY_F and reload_time<=0:action_time=_clip("inspect")
  if event.keycode==KEY_E:_skill()
  if event.keycode in [KEY_1,KEY_2,KEY_3]:_equip(event.keycode-KEY_1)
 if event is InputEventMouseMotion and playing and not paused and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  yaw-=event.relative.x*sensitivity;pitch=clampf(pitch-event.relative.y*sensitivity,-1.35,1.35)
func _reload() -> void:
 if not player.active or mode==3 and tactical.plant_progress>0:return
 if reload_time>0 or ammo[gun]>=GUNS[gun].mag or reserve[gun]<=0:return
 reload_time=maxf(.1,_clip("reload"));action_time=reload_time;_tone(240,.07,.1)
func _skill() -> void:
 if skill_cd>0 or not player.active or mode==3 and (tactical.phase!="live" or tactical.plant_progress>0):return
 skill_cd=18;_clip("ability");_tone(700,.2,.12)
 if agents==0:player.hp=minf(100,player.hp+35);notice.text="PULSO RESTAURADOR"
 if agents==1:shield_time=5;notice.text="BLINDAGEM ATIVA · 5s"
 if agents==2:
  var dir=-camera.global_transform.basis.z;dir.y=0;player.velocity+=dir.normalized()*18;notice.text="IMPULSO"
func _physics_process(dt: float) -> void:
 if not playing or paused:return
 if mode==3:
  _tactical_step(dt)
  if not playing:return
 clock+=dt;cooldown=maxf(0,cooldown-dt);action_time=maxf(0,action_time-dt);skill_cd=maxf(0,skill_cd-dt);shield_time=maxf(0,shield_time-dt);invulnerable=maxf(0,invulnerable-dt);hit_time=maxf(0,hit_time-dt)
 if reload_time>0:
  reload_time-=dt
  if reload_time<=0:
   var count=mini(GUNS[gun].mag-ammo[gun],reserve[gun]);ammo[gun]+=count;reserve[gun]-=count;_tone(650,.04,.08)
 var movement=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).limit_length(1)
 if mode==3 and (tactical.phase!="live" or not player.active):movement=Vector2.ZERO
 var crouch=Input.is_physical_key_pressed(KEY_C);var sprint=Input.is_physical_key_pressed(KEY_SHIFT);var ads=Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
 player.rotation.y=yaw;camera.rotation.x=pitch+recoil;var dir=player.transform.basis*Vector3(movement.x,0,movement.y);var speed=3 if crouch or ads else 7 if sprint else 5
 player.velocity.x=move_toward(player.velocity.x,dir.x*speed,dt*28);player.velocity.z=move_toward(player.velocity.z,dir.z*speed,dt*28);player.velocity.y-=24*dt
 if player.is_on_floor() and Input.is_physical_key_pressed(KEY_SPACE) and player.active and (mode!=3 or tactical.phase=="live"):player.velocity.y=7.5
 player.move_and_slide();camera.position.y=lerpf(camera.position.y,1.1 if crouch else 1.6,dt*12)
 camera.fov=lerpf(camera.fov,fov-18 if ads else fov,dt*12)
 recoil=move_toward(recoil,0,dt*1.4)
 var sway=sin(clock*(12 if sprint else 9))*movement.length()
 view.position=view.position.lerp(Vector3(.24 if not ads else .03,-.26+sway*.008,-.65),minf(1,dt*12))
 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and cooldown<=0 and reload_time<=0 and action_time<=.05:_fire()
 elif action_time<=0 and not weapon_anim.is_playing():_clip("idle",true)
 hitmarker.visible=hit_time>0
 hud_text.text="%03d  VIDA    %s\n%s · E %s" % [ceili(player.hp),"BLINDAGEM" if shield_time>0 else "",AGENTS[agents].name,"PRONTA" if skill_cd<=0 else str(ceili(skill_cd))+"s"]
 ammo_label.text="%02d / %03d\n%s" % [ammo[gun],reserve[gun],"RECARREGANDO" if reload_time>0 else GUNS[gun].name]
 match_label.text="AURORA / BREACH    %s    %02d:%02d\nELIMINACOES %02d    MORTES %02d    %s" % [["CONFRONTO","SOBREVIVENCIA","ESTANDE","RUPTURA"][mode],int(clock)/60,int(clock)%60,kills,deaths,"ONDA %d/3"%wave if mode==1 else "META 15" if mode==0 else "PRIMEIRO A 3" if mode==3 else "TREINO"]
func _fire() -> void:
 if not player.active or mode==3 and (tactical.phase!="live" or tactical.plant_progress>0):return
 if ammo[gun]<=0:_reload();return
 ammo[gun]-=1;shots+=1;cooldown=GUNS[gun].rate;_clip("fire");recoil+=.014 if gun!=2 else .035;_tone([100,170,65][gun],.09,.2)
 var origin=camera.global_position;var direction=-camera.global_transform.basis.z
 var spread=.0015+Vector2(player.velocity.x,player.velocity.z).length()*.003
 direction=(direction+Vector3(randf_range(-spread,spread),randf_range(-spread,spread),randf_range(-spread,spread))).normalized()
 var ray=PhysicsRayQueryParameters3D.create(origin,origin+direction*110);ray.exclude=[player.get_rid()];var hit=get_world_3d().direct_space_state.intersect_ray(ray);var target=origin+direction*70
 if not hit.is_empty():
  target=hit.position
  if hit.collider is Fighter:
   hits+=1;hit_time=.15;var head=hit.position.y-hit.collider.global_position.y>1.45
   if head:headshots+=1
   hit.collider.damage(GUNS[gun].damage*(2.4 if head else 1));_tone(900,.025,.07)
 _tracer(camera.global_position+camera.global_transform.basis*Vector3(.2,-.15,-.8),target,Color("ffdca8"))
func bot_shot(bot: Node,direction: Vector3) -> void:
 if mode==2:return
 var origin=bot.global_position+Vector3.UP*1.45;var ray=PhysicsRayQueryParameters3D.create(origin,origin+direction*70);ray.exclude=[bot.get_rid()];var hit=get_world_3d().direct_space_state.intersect_ray(ray);var target=origin+direction*40
 if not hit.is_empty():
  target=hit.position
  if hit.collider==player and invulnerable<=0:player.damage(tactical.apply_damage(10.0*(.4 if shield_time>0 else 1)) if mode==3 else 10.0*(.4 if shield_time>0 else 1))
 _tracer(origin,target,Color("ff9b80"))
func eliminated(victim: Node) -> void:
 if victim==player:
  deaths+=1
  if mode==3:return
  if mode==1:_end("OPERACAO ENCERRADA");return
  player.hp=100;player.active=true;player.position=arena.spawn();invulnerable=2;notice.text="REAPARECEU · 2s DE PROTECAO";return
 kills+=1;enemies.erase(victim);victim.queue_free();notice.text="ELIMINACAO CONFIRMADA"
 if mode==0:
  if kills>=15:_end("VITORIA / CONFRONTO")
  else:get_tree().create_timer(1.3).timeout.connect(func():if_spawn())
 elif mode==1 and enemies.is_empty():
  wave+=1
  if wave>3:_end("VITORIA / SOBREVIVENCIA")
  else:
   player.hp=minf(100,player.hp+25);reserve=[150,96,48];notice.text="ONDA %d / 3" % wave
   for i in 2+wave:_spawn_bot()
 elif mode==2:get_tree().create_timer(1).timeout.connect(func():if_spawn())
 elif mode==3:
  tactical.cash+=200
  if enemies.is_empty():tactical.finish(true,"Defensores eliminados")
func if_spawn() -> void:
 if playing and not paused:_spawn_bot()
func _end(text: String) -> void:
 playing=false;paused=false;menu_root.show();hud.hide();menu_camera.current=true;showcase.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 title_card.text="FIM DA\nOPERACAO";tip.text=text+"\n%d eliminacoes · %d mortes\nPrecisao %d%% · %d headshots" % [kills,deaths,100*hits/maxi(1,shots),headshots]
 if mode==3:tip.text+="\nRODADAS: ATAQUE %d × %d DEFESA" % [tactical.score_attack,tactical.score_defend]
func _tone(freq: float,duration: float,volume: float) -> void:
 var audio=AudioStreamPlayer.new();var wav=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;var bytes=PackedByteArray();bytes.resize(int(duration*22050)*2)
 for i in bytes.size()/2:
  var t=float(i)/22050;var envelope=pow(1-t/duration,2);var sample=(sin(t*TAU*freq)*.65+randf_range(-1,1)*.35)*envelope*volume;bytes.encode_s16(i*2,int(sample*16000))
 wav.data=bytes;audio.stream=wav;add_child(audio);audio.finished.connect(audio.queue_free);audio.play()
func _tracer(a: Vector3,b: Vector3,color: Color) -> void:
 var visual=MeshInstance3D.new();var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES);mesh.surface_add_vertex(a);mesh.surface_add_vertex(b);mesh.surface_end();visual.mesh=mesh;var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.albedo_color=color;visual.material_override=m;add_child(visual);flashes.append({"node":visual,"life":.055})
func _process(dt: float) -> void:
 if not playing and is_instance_valid(showcase):showcase.rotation.y+=dt*.1
 for flash in flashes.duplicate():
  flash.life-=dt
  if flash.life<=0:flash.node.queue_free();flashes.erase(flash)

func _exit_tree() -> void:
 for child in get_children():
  if child is AudioStreamPlayer:child.stop();child.stream=null

func visible_enemy(bot: Node) -> bool:
 if not is_instance_valid(player) or not is_instance_valid(camera):return false
 var q=PhysicsRayQueryParameters3D.create(camera.global_position,bot.global_position+Vector3.UP*1.2);q.exclude=[player.get_rid()]
 var hit=get_world_3d().direct_space_state.intersect_ray(q)
 return not hit.is_empty() and hit.collider==bot
func _map_lighting() -> void:
 var colors=[Color("b7c9db"),Color("bacddd"),Color("121d36"),Color("b3c7be")]
 lighting.environment.background_color=colors[map_index]
 lighting.environment.ambient_light_energy=.28 if map_index==2 else .16
 get_node("Sun").light_energy=.18 if map_index==2 else .45
func _purchase(item: String) -> void:
 var error=tactical.purchase(item)
 if not error.is_empty():buy_status.text=error;return
 if item!="armor":_equip(tactical.bought)
 buy_status.text="%d creditos / blindagem %d" % [tactical.cash,int(tactical.armor)]
 _tone(550,.05,.08)
func _tactical_round() -> void:
 for bot in enemies:
  if is_instance_valid(bot):bot.queue_free()
 enemies.clear()
 player.hp=100;player.active=true;player.position=Vector3(-6,.05,20);player.velocity=Vector3.ZERO;yaw=0;pitch=0
 ammo=[25,12,8];reserve=[150,96,48];reload_time=0;skill_cd=0;shield_time=0;_equip(1)
 if is_instance_valid(objective_model):objective_model.queue_free()
 for i in 4:_spawn_bot()
 buy_panel.show();buy_status.text="%d creditos / pistola gratuita"%tactical.cash;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 notice.text="RUPTURA / ATAQUE · PRIMEIRO A 3 RODADAS"
func _tactical_step(dt: float) -> void:
 var near=false
 for bot in enemies:
  if is_instance_valid(bot) and bot.active and bot.position.distance_to(tactical.plant_position)<2.1:near=true
 var event=tactical.step(dt,player.position,Input.is_physical_key_pressed(KEY_G) and reload_time<=0 and action_time<=0,player.active,near,Vector2(player.velocity.x,player.velocity.z).length()<.4 and player.is_on_floor())
 if event=="live":buy_panel.hide();Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;notice.text="Encontre A ou B. Segure G para plantar."
 elif event=="round":_tactical_round()
 elif event=="planted":_device();_tone(750,.15,.12);notice.text="DISPOSITIVO ARMADO / IMPECA O DESARME"
 elif event=="finished":_end("VITORIA / RUPTURA" if tactical.score_attack>=3 else "DEFESA VENCEU")
 if tactical.phase=="result":notice.text=tactical.result+" · proxima rodada em "+str(ceili(tactical.timer))
 var hint="B / ARSENAL" if tactical.phase=="buy" else "G / PLANTAR EM A OU B" if not tactical.planted else "PROTEJA O DISPOSITIVO"
 objective_label.text="ATAQUE %d : %d DEFESA · RODADA %d · %.0fs
%s · CREDITOS %d · BLINDAGEM %d" % [tactical.score_attack,tactical.score_defend,tactical.round_number,tactical.timer,hint,tactical.cash,int(tactical.armor)]
 if tactical.plant_progress>0 and not tactical.planted:objective_label.text+="
PLANTANDO %.0f%%"%(100*tactical.plant_progress/Tactical.PLANT_TIME)
 if tactical.defuse_progress>0:objective_label.text+="
DESARME INIMIGO %.0f%%"%(100*tactical.defuse_progress/Tactical.DEFUSE_TIME)
 if not player.active and tactical.planted:objective_label.text+="
OPERADOR ELIMINADO / OBSERVANDO O DISPOSITIVO"
 if tactical.planted and tactical.phase=="live":
  beep_clock-=dt
  if beep_clock<=0:beep_clock=.3 if tactical.timer<10 else .8;_tone(880,.035,.08)
func _device() -> void:
 objective_model=Node3D.new();add_child(objective_model);objective_model.position=tactical.plant_position+Vector3.UP*.35
 var mesh=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(.4,.6,.35);mesh.mesh=box
 var material=StandardMaterial3D.new();material.albedo_color=Color("374e61");material.emission_enabled=true;material.emission=Color("eaa85e")*.3;mesh.material_override=material;objective_model.add_child(mesh)
 var light=OmniLight3D.new();light.light_color=Color("f5b763");light.omni_range=3;light.light_energy=1;objective_model.add_child(light)
