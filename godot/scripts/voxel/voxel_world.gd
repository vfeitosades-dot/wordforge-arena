class_name VoxelWorld
extends Node3D
const CHUNK=8
const DIRS=[Vector3i.RIGHT,Vector3i.LEFT,Vector3i.UP,Vector3i.DOWN,Vector3i.BACK,Vector3i.FORWARD]
const COLORS=[Color("8c9eae"),Color("bb735a"),Color("84ad79"),Color("d7bb82"),Color("88a9c9")]
var blocks: Dictionary={}
var chunks: Dictionary={}
var changes: Dictionary={}
var dirty: Dictionary={}
var built_faces=0
func key(p: Vector3i) -> Vector3i:
 return Vector3i(floori(float(p.x)/CHUNK),floori(float(p.y)/CHUNK),floori(float(p.z)/CHUNK))
func fill(a: Vector3i,b: Vector3i,material: int=0) -> void:
 for x in range(a.x,b.x+1):
  for y in range(a.y,b.y+1):
   for z in range(a.z,b.z+1): blocks[Vector3i(x,y,z)]=material
func generate() -> void:
 blocks.clear();changes.clear()
 fill(Vector3i(-12,-3,-12),Vector3i(12,-1,12))
 for p in [Vector3i(24,2,0),Vector3i(-24,0,0),Vector3i(0,4,-24),Vector3i(0,1,24)]:
  fill(p+Vector3i(-7,-3,-7),p+Vector3i(7,-1,7),0)
 fill(Vector3i(12,-1,-2),Vector3i(18,-1,2),3)
 fill(Vector3i(-18,-1,-2),Vector3i(-12,-1,2),3)
 fill(Vector3i(-2,0,12),Vector3i(2,0,18),3)
 # A climbable stair bridge to the elevated north island.
 for i in range(12): fill(Vector3i(-2,floori(i/3.0),-13-i),Vector3i(2,floori(i/3.0),-13-i),0)
 # Brick house, doorway and windows; each brick is real terrain data.
 fill(Vector3i(-8,0,-9),Vector3i(1,4,-9),1)
 fill(Vector3i(-8,0,-3),Vector3i(1,4,-3),1)
 fill(Vector3i(-8,0,-9),Vector3i(-8,4,-3),1)
 fill(Vector3i(1,0,-9),Vector3i(1,4,-3),1)
 for y in range(3):
  for x in [-4,-3]: blocks.erase(Vector3i(x,y,-3))
 for y in [2,3]:
  for z in [-7,-6]: blocks.erase(Vector3i(1,y,z))
 fill(Vector3i(-8,5,-9),Vector3i(1,5,-3),3)
 for x in [-24,24]:
  fill(Vector3i(x-2,0,-2),Vector3i(x+2,7,2),0)
  fill(Vector3i(x-3,8,-3),Vector3i(x+3,8,3),4)
 for pos in [Vector3i(7,0,5),Vector3i(-6,0,7),Vector3i(23,2,5)]:
  fill(pos,pos+Vector3i(0,4,0),3)
  fill(pos+Vector3i(-2,3,-2),pos+Vector3i(2,5,2),2)
 for p in blocks: dirty[key(p)]=true
 rebuild_all()
func set_block(p: Vector3i,material: int=-1,record=true) -> void:
 if material<0: blocks.erase(p)
 else: blocks[p]=material%COLORS.size()
 if record: changes[p]=material
 dirty[key(p)]=true
 for d in DIRS: dirty[key(p+d)]=true
func rebuild_all() -> void:
 var pending=dirty.keys();dirty.clear()
 for k in pending: rebuild(k)
func _process(_dt: float) -> void:
 var todo=dirty.keys()
 for i in mini(3,todo.size()):
  dirty.erase(todo[i]);rebuild(todo[i])
func rebuild(k: Vector3i) -> void:
 if chunks.has(k):
  var old=chunks[k]
  remove_child(old);old.queue_free();chunks.erase(k)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var faces=0
 for x in range(k.x*CHUNK,(k.x+1)*CHUNK):
  for y in range(k.y*CHUNK,(k.y+1)*CHUNK):
   for z in range(k.z*CHUNK,(k.z+1)*CHUNK):
    var p=Vector3i(x,y,z)
    if not blocks.has(p): continue
    for dir in DIRS:
     if blocks.has(p+dir): continue
     var normal=Vector3(dir)
     var tangent=Vector3.UP if absf(normal.y)<.5 else Vector3.RIGHT
     var u=normal.cross(tangent)*.5
     var v=normal.cross(u.normalized())*.5
     var center=Vector3(p)+Vector3.ONE*.5+normal*.5
     var corners=[center-u-v,center+u-v,center+u+v,center-u+v]
     var shade=.9+float(posmod(x*31+y*13+z*7,9))*.018
     st.set_color(COLORS[int(blocks[p])]*shade)
     st.set_normal(normal)
     # Clockwise triangles for Godot's front-face convention.
     for i in [0,2,1,0,3,2]: st.add_vertex(corners[i])
     faces+=1
 if faces==0: return
 var mesh=st.commit()
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=1.0
 mesh.surface_set_material(0,mat)
 var node=StaticBody3D.new();node.name="Chunk_%s_%s_%s" % [k.x,k.y,k.z];node.set_meta("voxel",true)
 var visual=MeshInstance3D.new();visual.mesh=mesh;node.add_child(visual)
 var shape=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();node.add_child(shape)
 add_child(node);chunks[k]=node;built_faces+=faces
func encoded_changes() -> Array:
 var result=[]
 for p in changes: result.append([p.x,p.y,p.z,changes[p]])
 return result
func apply_changes(entries: Array) -> void:
 for e in entries:
  if e.size()==4: set_block(Vector3i(int(e[0]),int(e[1]),int(e[2])),int(e[3]))
func collapse_above(p: Vector3i) -> Array:
 # Bounded local support rule: remove unsupported column segments, never scan the whole map.
 var fallen=[]
 for y in range(p.y+1,p.y+7):
  var q=Vector3i(p.x,y,p.z)
  if not blocks.has(q): continue
  var supported=blocks.has(q+Vector3i.DOWN)
  for d in [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.FORWARD,Vector3i.BACK]:
   supported=supported or blocks.has(q+d)
  if not supported:
   set_block(q,-1);fallen.append([q.x,q.y,q.z,-1])
 return fallen
