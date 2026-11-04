class_name BreachFighter
extends CharacterBody3D
var hp=100.0
var actor_index=0
var controller
var local=false
var visual: Node3D
var animation_player: AnimationPlayer
var state="patrol"
var path=PackedVector3Array()
var target_point=Vector3.ZERO
var rethink=0.0
var fire_timer=0.0
var reaction=0.0
var active=true
var memory=0.0
var last_seen=Vector3.ZERO
var rounds=25
var reload_clock=0.0
var last_position=Vector3.ZERO
var stuck=0.0
func setup(game: Node,is_local: bool,actor: int) -> void:
 controller=game;local=is_local;actor_index=actor
 var c=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.height=1.8;shape.radius=.33;c.shape=shape;c.position.y=.9;add_child(c)
 if not local:
  visual=load("res://assets/"+["Serein","Rook","Vesper","Lumen"][actor]+".glb").instantiate();add_child(visual);animation_player=find_anim(visual)
  if animation_player:animation_player.speed_scale=2.5
  var w=load("res://assets/KestrelWorld.glb").instantiate()
  var skeleton=_skeleton(visual)
  if skeleton and skeleton.find_bone("hand_r")>=0:
   var socket=BoneAttachment3D.new();socket.bone_name="hand_r";skeleton.add_child(socket);socket.add_child(w)
   for key in animation_player.get_animation_list():
    if key.ends_with("aim"):animation_player.play(key);animation_player.seek(0,true);animation_player.advance(0)
   skeleton.force_update_all_bone_transforms()
   var grip=skeleton.get_bone_global_pose(skeleton.find_bone("hand_r"))
   w.transform=grip.affine_inverse()*Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.7),Vector3(.12,1.3485,-.336))
  else:visual.add_child(w);w.position=Vector3(.3,1.18,-.35);w.scale=Vector3.ONE*.7
  setup_animation_tree()
func find_anim(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:return node
 for child in node.get_children():
  var found=find_anim(child)
  if found:return found
 return null
func play_clip(clip: String,loop=true) -> void:
 if not animation_player:return
 if is_instance_valid(animation_tree) and animation_tree.active:
  if clip in ["idle","run","walk"]:return
  if clip=="death":animation_tree.active=false
  else:
   for key in animation_player.get_animation_list():
    if key.ends_with(clip):
     if action_time_left>0 and action_node.animation==key:return
     action_node.animation=key;action_time_left=animation_player.get_animation(key).length/2.5
     animation_tree.set("parameters/seek/seek_request",0.0);return
 for key in animation_player.get_animation_list():
  if key.to_lower().ends_with(clip):
   if animation_player.current_animation==key and animation_player.is_playing():return
   animation_player.get_animation(key).loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE;animation_player.play(key,.12);return
func damage(amount: float) -> void:
 if not active:return
 hp-=amount
 if hp<=0:active=false;controller.eliminated(self)
func _physics_process(dt: float) -> void:
 if local or not active or not controller.playing or controller.paused:return
 if controller.mode==3 and controller.tactical.phase!="live":
  velocity=Vector3.ZERO;play_clip("idle");return
 var player=controller.player
 if not is_instance_valid(player):return
 if controller.mode==3 and controller.tactical.planted and position.distance_to(controller.tactical.plant_position)<2.1:
  play_clip("ability",false);velocity.x=move_toward(velocity.x,0,dt*18);velocity.z=move_toward(velocity.z,0,dt*18);velocity.y-=24*dt;move_and_slide();return
 rethink-=dt;fire_timer-=dt;memory=maxf(0,memory-dt);reload_clock=maxf(0,reload_clock-dt)
 var delta=player.position-position
 var ray=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.55,player.global_position+Vector3.UP*1.2);ray.exclude=[get_rid()]
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 var sees=player.active and not hit.is_empty() and hit.collider==player and delta.length()<32
 if sees:
  memory=6;last_seen=player.position
  reaction+=dt
  rotation.y=lerp_angle(rotation.y,atan2(-delta.x,-delta.z),dt*7)
  state="retreat" if hp<35 else "engage"
  if reaction>controller.reaction_time and fire_timer<=0 and reload_clock<=0 and controller.mode!=2 and not (controller.mode==3 and controller.tactical.planted and position.distance_to(controller.tactical.plant_position)<2.1):
   if rounds<=0:
    reload_clock=1.8;rounds=25;play_clip("reload",false);return
   rounds-=1
   fire_timer=randf_range(.22,.55);play_clip("fire",false)
   var aim=(player.global_position+Vector3.UP*1.25-(global_position+Vector3.UP*1.45)).normalized()
   var spread=controller.bot_spread*(.7 if delta.length()<12 else 1.2)
   aim=(aim+Vector3(randf_range(-spread,spread),randf_range(-spread,spread),randf_range(-spread,spread))).normalized()
   controller.bot_shot(self,aim)
 else:reaction=0;state="hunt" if memory>0 else "patrol"
 if rethink<=0:
  rethink=randf_range(.45,.9)
  if controller.mode==3 and controller.tactical.planted and not sees:
   target_point=controller.tactical.plant_position
  elif controller.mode==3 and not sees and memory<=0:
   target_point=controller.tactical.SITES[actor_index%2]+Vector3(randf_range(-2,2),0,randf_range(-2,2))
  elif state=="retreat":
   var best=position;var score=-INF
   for cover in controller.arena.covers:
    var s=cover.distance_to(player.position)-cover.distance_to(position)*.5
    if s>score:score=s;best=cover
   target_point=best
  elif state=="engage":target_point=position+transform.basis.x*randf_range(-3,3)
  elif state=="hunt":target_point=last_seen
  else:
   if path.size()<2 or position.distance_to(target_point)<1.5:target_point=controller.arena.spawn()
  path=controller.arena.path(position,target_point)
 var direction=Vector3.ZERO
 if path.size()>1:
  if position.distance_to(path[1])<.65:path.remove_at(0)
  if path.size()>1:direction=(path[1]-position).normalized()
 var speed=2.6 if sees else 4.0
 velocity.x=move_toward(velocity.x,direction.x*speed,dt*18);velocity.z=move_toward(velocity.z,direction.z*speed,dt*18);velocity.y-=24*dt;move_and_slide()
 if not sees and direction.length()>.1:rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),dt*6)
 if not sees and reload_clock<=0:
  if animation_player:animation_player.speed_scale=2.5
  if animation_tree:animation_tree.set("parameters/speed/scale",2.5)
  play_clip("run" if direction.length()>.1 else "idle")
 if position.distance_to(last_position)<.005 and direction.length()>.1:stuck+=dt
 else:stuck=0
 if stuck>1.5:rethink=0;target_point=controller.arena.spawn();path=controller.arena.path(position,target_point);stuck=0
 last_position=position

var animation_tree: AnimationTree
var action_node: AnimationNodeAnimation
var action_time_left=0.0
func setup_animation_tree() -> void:
 if not animation_player:return
 var clips={}
 for key in animation_player.get_animation_list():
  for suffix in ["idle","aim","run","walk_back","strafe_left","strafe_right"]:
   if key.ends_with(suffix):clips[suffix]=key;animation_player.get_animation(key).loop_mode=Animation.LOOP_LINEAR
 if clips.size()<6:return
 var space=AnimationNodeBlendSpace2D.new();space.min_space=Vector2(-1,-1);space.max_space=Vector2(1,1)
 var points=[[Vector2.ZERO,"idle"],[Vector2(0,-1),"run"],[Vector2(0,1),"walk_back"],[Vector2(-1,0),"strafe_left"],[Vector2(1,0),"strafe_right"],[Vector2(-1,-1),"strafe_left"],[Vector2(1,-1),"strafe_right"],[Vector2(-1,1),"walk_back"],[Vector2(1,1),"walk_back"]]
 for point in points:
  var a=AnimationNodeAnimation.new();a.animation=clips[point[1]];space.add_blend_point(a,point[0])
 var root=AnimationNodeBlendTree.new();root.add_node("locomotion",space)
 action_node=AnimationNodeAnimation.new();action_node.animation=clips.idle;root.add_node("action",action_node)
 root.add_node("seek",AnimationNodeTimeSeek.new());root.connect_node("seek",0,"action")
 var aim=AnimationNodeAnimation.new();aim.animation=clips.aim;root.add_node("aim",aim)
 root.add_node("action_mix",AnimationNodeBlend2.new());root.connect_node("action_mix",0,"aim");root.connect_node("action_mix",1,"seek")
 var upper=AnimationNodeBlend2.new();upper.filter_enabled=true
 var sample=animation_player.get_animation(clips.idle)
 for i in sample.get_track_count():
  var path=sample.track_get_path(i);var bone=str(path).get_slice(":",1)
  if bone.begins_with("arm_") or bone.begins_with("forearm_") or bone.begins_with("hand_") or bone.begins_with("finger_") or bone.begins_with("clavicle_") or bone in ["torso","neck","head"]:upper.set_filter_path(path,true)
 root.add_node("upper",upper);root.connect_node("upper",0,"locomotion");root.connect_node("upper",1,"action_mix")
 root.add_node("speed",AnimationNodeTimeScale.new());root.connect_node("speed",0,"upper");root.connect_node("output",0,"speed")
 animation_tree=AnimationTree.new();visual.add_child(animation_tree);animation_tree.anim_player=animation_tree.get_path_to(animation_player);animation_tree.tree_root=root;animation_tree.set("parameters/speed/scale",2.5);animation_tree.set("parameters/upper/blend_amount",1.0);animation_tree.active=true
func _process(dt: float) -> void:
 if not is_instance_valid(animation_tree) or not animation_tree.active:return
 var v=transform.basis.inverse()*Vector3(velocity.x,0,velocity.z)
 animation_tree.set("parameters/locomotion/blend_position",Vector2(v.x,v.z)/4)
 action_time_left=maxf(0,action_time_left-dt)
 var amount=float(animation_tree.get("parameters/action_mix/blend_amount"))
 animation_tree.set("parameters/action_mix/blend_amount",move_toward(amount,1.0 if action_time_left>0 else 0.0,dt*10))

func _skeleton(node: Node) -> Skeleton3D:
 if node is Skeleton3D:return node
 for child in node.get_children():
  var found=_skeleton(child)
  if found:return found
 return null
