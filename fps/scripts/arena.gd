class_name BreachArena
extends Node3D
var solid={}
var covers=[]
var astar=AStarGrid2D.new()
var palette=[]
func box(pos: Vector3,size: Vector3,color: Color,collision=true) -> void:
 var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=pos;var mat=StandardMaterial3D.new();mat.albedo_color=color*.45;mat.roughness=.85;mesh.material_override=mat;add_child(mesh)
 if collision:
  var body=StaticBody3D.new();var col=CollisionShape3D.new();var b=BoxShape3D.new();b.size=size;col.shape=b;body.position=pos;body.add_child(col);add_child(body)
func build(index: int) -> void:
 astar.region=Rect2i(-24,-24,49,49);astar.cell_size=Vector2.ONE;astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;astar.update()
 palette=[Color("bdc5cb"),Color("dfb69b"),Color("537d86"),Color("8ecbbb")] if index==0 else [Color("bec8d5"),Color("91a3be"),Color("5f577f"),Color("b7a2e3")]
 box(Vector3(0,-.25,0),Vector3(48,.5,48),palette[0])
 for i in range(-24,25,4):
  box(Vector3(i,.005,0),Vector3(.025,.01,48),palette[2],false);box(Vector3(0,.005,i),Vector3(48,.01,.025),palette[2],false)
 for item in [[Vector3(-24,3,0),Vector3(1,6,48)],[Vector3(24,3,0),Vector3(1,6,48)],[Vector3(0,3,-24),Vector3(48,6,1)],[Vector3(0,3,24),Vector3(48,6,1)]]:box(item[0],item[1],palette[1])
 var layout=[[-11,-9,6,5],[-11,8,5,5],[10,-10,6,5],[11,9,6,5],[0,0,4,4],[-2,-15,7,2],[1,15,7,2]] if index==0 else [[-12,0,4,13],[12,0,4,13],[0,-12,12,3],[0,12,12,3],[-4,-3,3,3],[4,4,3,3]]
 for spec in layout:
  var pos=Vector3(spec[0],1.4,spec[1]);var size=Vector3(spec[2],2.8,spec[3]);box(pos,size,palette[1]);box(pos+Vector3(0,1.48,0),Vector3(size.x+.16,.15,size.z+.16),palette[2])
  box(pos+Vector3(0,.8,-size.z*.5-.015),Vector3(size.x*.6,.12,.025),palette[3],false)
  for x in range(floori(pos.x-size.x/2)-1,ceili(pos.x+size.x/2)+1):
   for z in range(floori(pos.z-size.z/2)-1,ceili(pos.z+size.z/2)+1):
    if astar.is_in_boundsv(Vector2i(x,z)):astar.set_point_solid(Vector2i(x,z));solid[Vector2i(x,z)]=true
  for side in [-1,1]:covers.append(Vector3(pos.x+side*(size.x/2+2),0,pos.z))
 # Architectural skyline, canopy supports and illuminated site markers.
 for x in [-20,20]:
  for z in [-18,0,18]:
   box(Vector3(x,3,z),Vector3(.5,6,.5),palette[2]);box(Vector3(x,6,z),Vector3(3,.18,3),palette[3],false)
 for i in range(9):box(Vector3(-30+i*8,5+i%3*3,-34),Vector3(5,10+i%3*6,5),palette[2],false)
 for pair in [[Vector3(-17,.02,-17),Color("79dcc6")],[Vector3(17,.02,17),Color("f4a07f")]]:
  box(pair[0],Vector3(7,.04,7),pair[1],false)
func path(from: Vector3,to: Vector3) -> PackedVector3Array:
 var a=Vector2i(roundi(from.x),roundi(from.z));var b=Vector2i(roundi(to.x),roundi(to.z));var result=PackedVector3Array()
 if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b) or astar.is_point_solid(a) or astar.is_point_solid(b):return result
 for p in astar.get_id_path(a,b):result.append(Vector3(p.x,0,p.y))
 return result
func spawn() -> Vector3:
 for i in range(100):
  var p=Vector2i(randi_range(-20,20),randi_range(-20,20))
  if not astar.is_point_solid(p):return Vector3(p.x,.05,p.y)
 return Vector3(0,.05,20)
