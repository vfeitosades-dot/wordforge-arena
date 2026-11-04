extends SceneTree
var checks=0
var failed=[]
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failed.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func all_nodes(root: Node,kind: String) -> Array:
 var result=[]
 if root.is_class(kind):result.append(root)
 for child in root.get_children():result.append_array(all_nodes(child,kind))
 return result
func run() -> void:
 seed(1234)
 for asset in ["Kestrel","Wisp","Longbow","Serein","Rook","Vesper","Lumen"]:
  var model=load("res://assets/"+asset+".glb").instantiate();root.add_child(model)
  var anims=all_nodes(model,"AnimationPlayer");check(not anims.is_empty(),asset+" imported animation player")
  var skeletons=all_nodes(model,"Skeleton3D");check(not skeletons.is_empty(),asset+" skeletal rig")
  if not anims.is_empty():
   var ap=anims[0]
   for clip in ["idle","walk","run","fire","reload","equip","inspect","ability"]:
    var found=false
    for name in ap.get_animation_list():
     if name.ends_with(clip):found=true;check(ap.get_animation(name).get_track_count()>0,asset+" "+clip+" actual tracks")
    check(found,asset+" has "+clip)
  if asset in ["Serein","Rook","Vesper","Lumen"]:
   for clip in ["aim","strafe_left","strafe_right","walk_back","crouch_idle","crouch_walk","hit","death"]:
    var found=false
    for name in anims[0].get_animation_list():
     if name.ends_with(clip):found=true
    check(found,asset+" directional and reaction clip "+clip)
   check(skeletons[0].get_bone_parent(skeletons[0].find_bone("forearm_r"))==skeletons[0].find_bone("arm_r"),asset+" articulated elbow chain")
  if not anims.is_empty() and not skeletons.is_empty():
   var ap=anims[0];var skeleton=skeletons[0]
   var clip="reload" if asset in ["Kestrel","Wisp","Longbow"] else "ability"
   var bone=skeleton.find_bone("magazine" if clip=="reload" else "arm_r" if asset in ["Rook","Lumen"] else "arm_l")
   for key in ap.get_animation_list():
    if key.ends_with(clip) and bone>=0:
     ap.play(key);ap.seek(0,true);ap.advance(0)
     var before=skeleton.get_bone_pose(bone)
     ap.seek(ap.get_animation(key).length*.4,true);ap.advance(0)
     var after=skeleton.get_bone_pose(bone)
     check(not before.is_equal_approx(after),asset+" actual animated bone movement")
  var meshes=all_nodes(model,"MeshInstance3D")
  check(meshes.size()>=4,asset+" imported material groups")
  var vertices=0
  for mesh in meshes:
   for i in mesh.mesh.get_surface_count():vertices+=mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX].size()
  check(vertices>500,asset+" authored geometry")
  model.queue_free()
 for asset in ["Kestrel","Wisp","Longbow"]:
  var world=load("res://assets/"+asset+"World.glb").instantiate();root.add_child(world)
  var meshes=all_nodes(world,"MeshInstance3D")
  check(meshes.size()<=8 and meshes.size()>0,asset+" optimized world material groups")
  for mesh in meshes:
   check(not ("palm" in mesh.name or "sleeve" in mesh.name or "finger" in mesh.name),asset+" world model excludes viewmodel hands")
  world.queue_free()
 var arena_script=load("res://scripts/arena.gd")
 for index in 4:
  var arena=arena_script.new();root.add_child(arena);arena.build(index)
  for i in 10:
   var start=arena.spawn();var end=arena.spawn();var path=arena.path(start,end)
   check(not path.is_empty(),"Navigable arena %d"%index)
   for p in path:check(not arena.astar.is_point_solid(Vector2i(roundi(p.x),roundi(p.z))),"Path avoids cover")
  arena.queue_free()
 var Tactical=load("res://scripts/tactical.gd")
 var tac=Tactical.new();tac.start()
 check(tac.phase=="buy" and tac.cash==800,"Tactical preparation and credits")
 check(tac.purchase("rifle").contains("insuficientes"),"Cannot overspend")
 check(tac.purchase("armor").is_empty() and tac.cash==450 and tac.armor==50,"Armor buy")
 check(not tac.purchase("armor").is_empty(),"No duplicate armor charge")
 check(tac.apply_damage(20)==8 and tac.armor==38,"Armor absorbs damage")
 tac.step(8,Vector3.ZERO,false,true,false)
 check(tac.phase=="live","Preparation transitions to live")
 check(not tac.purchase("rifle").is_empty(),"Purchases blocked midround")
 tac.step(2,Vector3.ZERO,true,true,false)
 check(not tac.planted,"Cannot plant outside site")
 tac.step(1,Tactical.SITES[0],true,true,false)
 check(tac.plant_progress==1,"Plant holding progress")
 tac.step(.1,Tactical.SITES[0],false,true,false)
 check(tac.plant_progress==0,"Releasing cancels plant")
 tac.step(2.5,Tactical.SITES[0],true,true,false)
 check(tac.planted and tac.timer==35,"Real planted state and fuse")
 tac.step(1,Vector3.ZERO,false,true,true)
 tac.step(.1,Vector3.ZERO,false,true,false)
 check(tac.defuse_progress==0,"Interrupted defuse resets")
 tac.step(4,Vector3.ZERO,false,true,true)
 check(tac.phase=="result" and tac.score_defend==1,"Enemy defuse wins round")
 tac.step(4,Vector3.ZERO,false,true,false)
 check(tac.phase=="buy" and tac.round_number==2 and not tac.planted,"Next round resets objective")
 tac.step(8,Vector3.ZERO,false,true,false);tac.step(2.5,Tactical.SITES[1],true,true,false)
 tac.step(35,Vector3.ZERO,false,false,false)
 check(tac.score_attack==1,"Planted fuse can win after player death")
 tac.step(4,Vector3.ZERO,false,true,false);tac.step(8,Vector3.ZERO,false,true,false)
 tac.step(.1,Vector3.ZERO,false,false,false)
 check(tac.phase=="result" and tac.score_defend==2,"Death before planting loses round")
 tac.step(4,Vector3.ZERO,false,true,false);tac.step(8,Vector3.ZERO,false,true,false)
 tac.step(90,Vector3.ZERO,false,true,false);tac.step(4,Vector3.ZERO,false,true,false)
 check(tac.phase=="finished" and tac.score_defend==3,"Best of five match conclusion")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.start_match()
 check(game.enemies.size()==4,"Confronto bots spawned")
 for i in 45:await physics_frame
 check(game.player.is_on_floor(),"Player floor collision")
 game.action_time=0;game._fire();check(game.ammo[game.gun]==24,"Firing consumes ammo")
 game._reload();check(game.reload_time>0,"Reload enters timed state")
 game._equip(1);check(game.reload_time==0 and game.ammo[0]==24,"Weapon switch cancels reload without duplication")
 game.player.hp=40;game.skill_cd=0;game.agents=0;game._skill();check(game.player.hp==75,"Serein restores health")
 game.agents=1;game.skill_cd=0;game._skill();check(game.shield_time==5,"Rook protection")
 game.agents=2;game.skill_cd=0;game._skill();check(game.player.velocity.length()>10,"Vesper dash")
 game.agents=3;game.skill_cd=0;game._skill();check(game.radar_time==5,"Lumen reveal duration")
 for bot in game.enemies:
  check(bot.animation_tree!=null and bot.animation_tree.active,"Layered locomotion tree")
  check(not all_nodes(bot,"BoneAttachment3D").is_empty(),"World weapon socket follows hand")
 var animated_bot=game.enemies[0];var rig=animated_bot._skeleton(animated_bot.visual)
 animated_bot.animation_tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 animated_bot.play_clip("reload",false);animated_bot.animation_tree.set("parameters/action_mix/blend_amount",1.0)
 animated_bot.animation_tree.set("parameters/locomotion/blend_position",Vector2(0,-1))
 animated_bot.animation_tree.advance(.04);rig.force_update_all_bone_transforms();var leg_before=rig.get_bone_pose(rig.find_bone("leg_l"))
 animated_bot.animation_tree.advance(.12);rig.force_update_all_bone_transforms();var leg_after=rig.get_bone_pose(rig.find_bone("leg_l"))
 check(not leg_before.is_equal_approx(leg_after),"Leg locomotion remains active during upper-body reload")
 game.pending_respawns.append(.1)
 game.mode_box.select(1);game.start_match();check(game.pending_respawns.is_empty(),"New match clears pending respawns");check(game.enemies.size()==2 and game.wave==1,"Wave mode starts correctly")
 game.mode_box.select(2);game.start_match();check(game.enemies.size()==5,"Training mode bots")
 game.mode_box.select(3);game.map_box.select(2);game.start_match()
 check(game.mode==3 and game.tactical.phase=="buy" and game.enemies.size()==4,"Tactical match and four defenders")
 check(game.gun==1 and game.buy_panel.visible,"Free pistol and active purchase UI")
 game.tactical.cash=2000;game._purchase("rifle")
 check(game.gun==0 and game.tactical.cash==1000,"Purchase equips bought gun")
 game._equip(2);check(game.gun==0,"Unpurchased weapon cannot be equipped")
 game.tactical.step(8,Vector3.ZERO,false,true,false)
 game.player.position=game.tactical.SITES[0];game.player.velocity=Vector3.ZERO
 game.tactical.step(2.5,game.player.position,true,true,false);game._device()
 check(is_instance_valid(game.objective_model),"Planted objective has visible model")
 game.tactical.planted=false;game.tactical.plant_progress=1;game.action_time=0;game.reload_time=0
 var previous_ammo=game.ammo[game.gun];game._fire()
 check(game.ammo[game.gun]==previous_ammo,"Cannot fire while planting")
 game._skill();check(game.skill_cd==0,"Cannot use skill while planting")
 game.tactical.plant_progress=0;game.gun=2;game.resume()
 check(game.gun==game.equipped_index,"Paused menu cannot equip unpurchased gun")
 game.paused=true;game.pending_respawns.append(.3);var t=game.clock;await physics_frame;check(game.clock==t,"Pause freezes gameplay clock");check(game.pending_respawns[0]==.3,"Pause preserves respawn delay")
 game._layout_ui();check(game.ammo_label.position.x>900,"HUD ammo anchored to right");check(game.ammo_label.get_global_rect().end.y<=game.get_viewport().get_visible_rect().end.y,"Two-line ammo HUD fits vertically")
 game.left_handed=true;game.reduce_motion=true;game.master_volume=.35;game.cross_color=2;game._save()
 var config=ConfigFile.new();config.load("user://aurora.cfg")
 check(config.get_value("controls","left_handed",false),"Handedness persists")
 check(config.get_value("accessibility","reduce_motion",false),"Reduced motion persists")
 check(config.get_value("audio","volume",1)==.35,"Audio persists")
 game._reset_settings();check(not game.left_handed and game.cross_color==0,"Restore defaults")
 print("AURORA_TESTS: %d checks, %d failures" % [checks,failed.size()])
 game.queue_free();await create_timer(.3).timeout;quit(0 if failed.is_empty() else 1)
