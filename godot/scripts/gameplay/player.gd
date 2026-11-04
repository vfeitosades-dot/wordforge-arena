class_name VoxPlayer
extends CharacterBody3D
var peer_id=1
var matter=0
var hp=100
var score=0
var camera: Camera3D
var yaw=0.0
var pitch=0.0
var local_control=false
var third_person=false
var input_state={}
var ability=""
var ability_time=0.0
var equipped={}
var cooldown=0.0
var crouching=false
var body_mesh: Node3D
func setup(id: int,local: bool) -> void:
 peer_id=id;local_control=local;name="Player_%d" % id
 var shape=CollisionShape3D.new();var cap=CapsuleShape3D.new();cap.radius=.32;cap.height=1.7;shape.shape=cap;shape.position.y=.85;add_child(shape)
 body_mesh=Node3D.new();add_child(body_mesh)
 for spec in [[Vector3(0,1,0),Vector3(.6,.7,.35),Color("7ba5de")],[Vector3(0,1.65,0),Vector3(.5,.5,.5),Color("e4edf4")],[Vector3(-.17,.35,0),Vector3(.22,.7,.25),Color("8b9aaa")],[Vector3(.17,.35,0),Vector3(.22,.7,.25),Color("8b9aaa")]]:
  var m=MeshInstance3D.new();var box=BoxMesh.new();box.size=spec[1];m.mesh=box;m.position=spec[0];var mat=StandardMaterial3D.new();mat.albedo_color=spec[2];m.material_override=mat;body_mesh.add_child(m)
 camera=Camera3D.new();camera.position=Vector3(0,1.6,0);camera.fov=78;camera.current=local;add_child(camera);body_mesh.visible=not local
func simulate(dt: float,state: Dictionary) -> void:
 input_state=state
 yaw=float(state.get("yaw",yaw));pitch=clampf(float(state.get("pitch",pitch)),-1.45,1.45)
 rotation.y=yaw;camera.rotation.x=pitch
 ability_time=maxf(0,ability_time-dt)
 if ability_time==0: ability=""
 cooldown=maxf(0,cooldown-dt)
 var v=Vector2(float(state.get("x",0)),float(state.get("z",0))).limit_length(1)
 var speed=8.5 if state.get("run",false) else 5.4
 if ability=="speed": speed*=1.7
 crouching=state.get("crouch",false)
 if crouching: speed*=.45
 var collider=get_child(0)
 collider.shape.height=1.1 if crouching else 1.7
 collider.position.y=.55 if crouching else .85
 camera.position.y=1.0 if crouching else 1.6
 var direction=transform.basis*Vector3(v.x,0,v.y)
 velocity.x=move_toward(velocity.x,direction.x*speed,dt*32)
 velocity.z=move_toward(velocity.z,direction.z*speed,dt*32)
 if ability=="fly": velocity.y=(float(state.get("jump",false))-float(state.get("down",false)))*6.5
 else:
  velocity.y-=24*dt
  if is_on_floor() and state.get("jump",false): velocity.y=14 if ability=="jump" else 8
 move_and_slide()
 if position.y< -18: position=Vector3(4,3,8);velocity=Vector3.ZERO;hp=100
 body_mesh.visible=(not local_control or third_person) and ability!="invisible"
func look_direction() -> Vector3:
 return -camera.global_transform.basis.z
func snapshot() -> Dictionary:
 return {"id":peer_id,"p":[position.x,position.y,position.z],"yaw":yaw,"pitch":pitch,"matter":matter,"hp":hp,"score":score,"ability":ability,"time":ability_time}
func apply_snapshot(data: Dictionary) -> void:
 var p=Vector3(data.p[0],data.p[1],data.p[2])
 if not local_control or position.distance_to(p)>1.8: position=position.lerp(p,.55)
 if not local_control: rotation.y=data.yaw;camera.rotation.x=data.pitch
 matter=data.matter;hp=data.hp;score=data.score;ability=data.ability;ability_time=data.time
 body_mesh.visible=(not local_control or third_person) and ability!="invisible"
