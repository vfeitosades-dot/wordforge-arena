class_name BreachArena
extends Node3D
var solid={}
var covers=[]
var astar=AStarGrid2D.new()
var palette=[]
func box(pos: Vector3,size: Vector3,color: Color,collision=true) -> void:
 var mesh=MeshInstance3D.new();var shape=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=pos;var mat=StandardMaterial3D.new();mat.albedo_color=color*.45;mat.roughness=.85
 if palette.size()==4 and color==palette[3]:mat.emission_enabled=true;mat.emission=color*.45
 mesh.material_override=mat;add_child(mesh)
 if collision:
  var body=StaticBody3D.new();var col=CollisionShape3D.new();var b=BoxShape3D.new();b.size=size;col.shape=b;body.position=pos;body.add_child(col);add_child(body)
func build(index: int) -> void:
 astar.region=Rect2i(-24,-24,49,49);astar.cell_size=Vector2.ONE;astar.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;astar.update()
 for i in range(-24,25):
  for edge in [Vector2i(i,-24),Vector2i(i,24),Vector2i(-24,i),Vector2i(24,i)]:astar.set_point_solid(edge);solid[edge]=true
 var palettes=[[Color("bdc5cb"),Color("dfb69b"),Color("537d86"),Color("8ecbbb")],[Color("d8e4ef"),Color("9cadc4"),Color("455b77"),Color("edb88b")],[Color("61758d"),Color("4b6887"),Color("24354d"),Color("b580e0")],[Color("bccbb6"),Color("a8b4a2"),Color("4c6a60"),Color("a1d789")]]
 palette=palettes[clampi(index,0,3)]
 box(Vector3(0,-.25,0),Vector3(48,.5,48),palette[0])
 for i in range(-24,25,4):
  box(Vector3(i,.005,0),Vector3(.025,.01,48),palette[2],false);box(Vector3(0,.005,i),Vector3(48,.01,.025),palette[2],false)
 for item in [[Vector3(-24,3,0),Vector3(1,6,48)],[Vector3(24,3,0),Vector3(1,6,48)],[Vector3(0,3,-24),Vector3(48,6,1)],[Vector3(0,3,24),Vector3(48,6,1)]]:box(item[0],item[1],palette[1])
 var layouts=[
 [[-11,-9,6,5],[-11,8,5,5],[10,-10,6,5],[11,9,6,5],[0,0,4,4],[-2,-15,7,2],[1,15,7,2]],
 [[-12,0,4,13],[12,0,4,13],[0,-12,12,3],[0,12,12,3],[-4,-3,3,3],[4,4,3,3]],
 [[-12,-10,7,3],[10,-9,3,9],[-9,8,3,10],[11,11,9,3],[-1,0,6,4],[1,-17,6,2]],
 [[-10,-6,4,10],[10,6,4,10],[-7,12,8,3],[7,-12,8,3],[0,0,3,5]]]
 var layout=layouts[clampi(index,0,3)]
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
   astar.set_point_solid(Vector2i(x,z));solid[Vector2i(x,z)]=true
   box(Vector3(x,3,z),Vector3(.5,6,.5),palette[2]);box(Vector3(x,6,z),Vector3(3,.18,3),palette[3],false)
 for i in range(9):box(Vector3(-30+i*8,5+i%3*3,-34),Vector3(5,10+i%3*6,5),palette[2],false)
 for pair in [[Vector3(-17,.02,-17),Color("79dcc6")],[Vector3(17,.02,-17),Color("f4a07f")]]:
  box(pair[0],Vector3(7,.04,7),pair[1],false)
 # Modular visual dressing stays outside navigable space; it does not hide extra collision.
 for spec in layout:
  var x=float(spec[0]);var z=float(spec[1]);var width=float(spec[2]);var depth=float(spec[3])
  if index==0:
   for sign in [-1,1]:box(Vector3(x+sign*width*.3,1.75,z-depth*.5-.025),Vector3(.65,.9,.03),Color("426b80"),false)
   box(Vector3(x,3.05,z),Vector3(width+.5,.18,depth+.5),Color("b9a381"),false)
  elif index==1:
   box(Vector3(x,3.05,z),Vector3(width+.3,.22,depth+.3),Color("f1f5fa"),false)
   box(Vector3(x,1.8,z-depth*.5-.025),Vector3(width*.6,.5,.03),Color("779db9"),false)
  elif index==2:
   for n in range(1,int(width*2)):
    box(Vector3(x-width*.5+n*.5,1.4,z-depth*.5-.015),Vector3(.035,2.4,.035),palette[2],false)
   var sign=Label3D.new();sign.text="AURORA // CARGO";sign.position=Vector3(x,2,z-depth*.5-.04);sign.font_size=52;sign.pixel_size=.005;add_child(sign)
  else:
   for dx in [-width*.3,width*.3]:
    box(Vector3(x+dx,3.1,z),Vector3(.2,1,.2),Color("587358"),false)
    box(Vector3(x+dx,3.65,z),Vector3(1.4,.9,1.2),Color("76ab73"),false)
   box(Vector3(x,1.8,z-depth*.5-.03),Vector3(width*.7,.5,.03),Color("6b8f85"),false)
 for i in 2:
  var marker=Label3D.new();marker.text="A" if i==0 else "B";marker.position=Vector3(-17 if i==0 else 17,.08,-17);marker.rotation_degrees.x=-90;marker.font_size=140;marker.pixel_size=.025;add_child(marker)

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
