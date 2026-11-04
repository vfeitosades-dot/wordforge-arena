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
 for asset in ["Kestrel","Wisp","Longbow","Serein","Rook","Vesper"]:
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
  if not anims.is_empty() and not skeletons.is_empty():
   var ap=anims[0];var skeleton=skeletons[0]
   var clip="reload" if asset in ["Kestrel","Wisp","Longbow"] else "ability"
   var bone=skeleton.find_bone("magazine" if clip=="reload" else "arm_r" if asset=="Rook" else "arm_l")
   for key in ap.get_animation_list():
    if key.ends_with(clip) and bone>=0:
     ap.play(key);ap.seek(0,true);ap.advance(0)
     var before=skeleton.get_bone_pose(bone)
     ap.seek(ap.get_animation(key).length*.4,true);ap.advance(0)
     var after=skeleton.get_bone_pose(bone)
     check(not before.is_equal_approx(after),asset+" actual animated bone movement")
  check(all_nodes(model,"MeshInstance3D").size()>12,asset+" detailed multipart model")
  model.queue_free()
 var arena_script=load("res://scripts/arena.gd")
 for index in 2:
  var arena=arena_script.new();root.add_child(arena);arena.build(index)
  for i in 10:
   var start=arena.spawn();var end=arena.spawn();var path=arena.path(start,end)
   check(not path.is_empty(),"Navigable arena %d"%index)
   for p in path:check(not arena.astar.is_point_solid(Vector2i(roundi(p.x),roundi(p.z))),"Path avoids cover")
  arena.queue_free()
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
 game.mode_box.select(1);game.start_match();check(game.enemies.size()==2 and game.wave==1,"Wave mode starts correctly")
 game.mode_box.select(2);game.start_match();check(game.enemies.size()==5,"Training mode bots")
 game.paused=true;var t=game.clock;await physics_frame;check(game.clock==t,"Pause freezes gameplay clock")
 print("AURORA_TESTS: %d checks, %d failures" % [checks,failed.size()])
 game.queue_free();await create_timer(.3).timeout;quit(0 if failed.is_empty() else 1)
