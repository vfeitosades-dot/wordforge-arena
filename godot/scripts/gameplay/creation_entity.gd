class_name CreationEntity
extends RigidBody3D
var graph={}
var entity_id=0
var owner_id=1
var authoritative=true
var age=0.0
var hp=100.0
var emit_cool=1.2
var controller: Node
var original_y=0.0
var paired_id=-1
func configure(g: Dictionary,id: int,owner: int,host: Node,is_authoritative: bool) -> void:
 graph=g.duplicate(true);entity_id=id;owner_id=owner;controller=host;authoritative=is_authoritative;name="Creation_%d" % id
 mass=clampf(float(g.cost)/15.0,.6,20)
 var factory=preload("res://scripts/creation/object_factory.gd")
 factory.build(self,graph)
 var sc=float(graph.scale)
 for child in get_children():
  if child is Node3D: child.position*=sc
  if child is MeshInstance3D: child.scale*=sc
  if child is CollisionShape3D:
   if child.shape is BoxShape3D: child.shape.size*=sc
   if child.shape is SphereShape3D: child.shape.radius*=sc
 var material=PhysicsMaterial.new();material.friction=.7;material.bounce=.8 if "bounce" in graph.mods else .12;physics_material_override=material
 if graph.kind in ["wall","tower","tree","portal","shield","gravity"]: freeze=true
 if "fly" in graph.mods or "orbit" in graph.mods or graph.kind=="platform": gravity_scale=0
 if not authoritative: freeze=true
 contact_monitor=true;max_contacts_reported=4
func _physics_process(dt: float) -> void:
 if not authoritative: return
 age+=dt;emit_cool-=dt
 if age>120 or position.y< -20 or hp<=0:
  controller.remove_entity(entity_id);return
 var owner=controller.players.get(owner_id)
 if not is_instance_valid(owner): return
 if "orbit" in graph.mods:
  var phase=float(entity_id)*2.1+age*1.2
  var desired=owner.position+Vector3(cos(phase)*3,2.3,sin(phase)*3)
  linear_velocity=(desired-position).limit_length(float(graph.speed)*2)
 elif "follow" in graph.mods:
  var target=owner.position+Vector3(0,1.4 if "fly" in graph.mods else 0,0)
  var diff=target-position
  var direction=diff.normalized()*float(graph.speed) if diff.length()>2.5 else Vector3.ZERO
  linear_velocity.x=move_toward(linear_velocity.x,direction.x,dt*10)
  linear_velocity.z=move_toward(linear_velocity.z,direction.z,dt*10)
  if "fly" in graph.mods: linear_velocity.y=clampf(diff.y*2,-4,4)
  if Vector2(diff.x,diff.z).length()>.5: rotation.y=lerp_angle(rotation.y,atan2(-diff.x,-diff.z),dt*4)
 if "spin" in graph.mods: angular_velocity.y=2
 if "bounce" in graph.mods and get_contact_count()>0 and linear_velocity.y<.5: linear_velocity.y=6
 if graph.kind=="platform":
  var target=Vector3(position.x,original_y+sin(age)*1.1,position.z)
  linear_velocity.y=clampf((target.y-position.y)*4,-4,4)
 if graph.kind=="gravity":
  for other in controller.entities.values():
   if other==self or other.freeze: continue
   var delta=position+Vector3.UP-other.position
   if delta.length()<10 and delta.length()>.5: other.apply_central_force(delta.normalized()*other.mass*8)
  for player in controller.players.values():
   var delta=position-player.position
   if delta.length()<8 and delta.length()>1: player.velocity+=delta.normalized()*dt*8
 if graph.kind=="shield" and owner.position.distance_to(position)<5: owner.hp=mini(100,owner.hp+1)
 if graph.kind=="portal" and paired_id>=0 and controller.entities.has(paired_id):
  var partner=controller.entities[paired_id]
  for p in controller.players.values():
   if p.position.distance_to(position)<1.35 and not controller.portal_cooldowns.has(p.peer_id):
    p.position=partner.position-partner.global_transform.basis.z*2.2+Vector3.UP*.1
    p.velocity=p.velocity.rotated(Vector3.UP,partner.rotation.y-rotation.y)
    controller.portal_cooldowns[p.peer_id]=1.5
 if not graph.emitter.is_empty() and emit_cool<=0:
  emit_cool=1.6
  controller.entity_fire(self)
func snapshot() -> Dictionary:
 return {"id":entity_id,"p":[position.x,position.y,position.z],"r":[rotation.x,rotation.y,rotation.z],"hp":hp}
