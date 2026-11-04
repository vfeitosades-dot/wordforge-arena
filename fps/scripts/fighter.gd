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
  visual=load("res://assets/"+["Serein","Rook","Vesper"][actor]+".glb").instantiate();add_child(visual);animation_player=find_anim(visual)
  if animation_player:animation_player.speed_scale=2.5
  var w=load("res://assets/Kestrel.glb").instantiate();w.position=Vector3(.3,1.18,-.35);w.scale=Vector3.ONE*.7;visual.add_child(w)
func find_anim(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:return node
 for child in node.get_children():
  var found=find_anim(child)
  if found:return found
 return null
func play_clip(clip: String,loop=true) -> void:
 if not animation_player:return
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
 var player=controller.player
 if not is_instance_valid(player):return
 rethink-=dt;fire_timer-=dt;memory=maxf(0,memory-dt);reload_clock=maxf(0,reload_clock-dt)
 var delta=player.position-position
 var ray=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.55,player.global_position+Vector3.UP*1.2);ray.exclude=[get_rid()]
 var hit=get_world_3d().direct_space_state.intersect_ray(ray)
 var sees=not hit.is_empty() and hit.collider==player and delta.length()<32
 if sees:
  memory=6;last_seen=player.position
  reaction+=dt
  rotation.y=lerp_angle(rotation.y,atan2(-delta.x,-delta.z),dt*7)
  state="retreat" if hp<35 else "engage"
  if reaction>controller.reaction_time and fire_timer<=0 and reload_clock<=0 and controller.mode!=2:
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
  if state=="retreat":
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
 if not sees and reload_clock<=0:play_clip("run" if direction.length()>.1 else "idle")
 if position.distance_to(last_position)<.005 and direction.length()>.1:stuck+=dt
 else:stuck=0
 if stuck>1.5:rethink=0;target_point=controller.arena.spawn();path=controller.arena.path(position,target_point);stuck=0
 last_position=position
