class_name ObjectFactory
extends RefCounted
const Binder=preload("res://scripts/physics/physics_binder.gd")
static func add_box(parent: Node3D,pos: Vector3,size: Vector3,color: Color) -> void:
 var mesh=BoxMesh.new();mesh.size=size
 var node=MeshInstance3D.new();node.mesh=mesh;node.position=pos
 var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.85
 node.material_override=material;parent.add_child(node)
 Binder.box(parent,pos,size)
static func add_sphere(parent: Node3D,pos: Vector3,radius: float,color: Color) -> void:
 var visual=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=radius;sphere.height=radius*2;sphere.radial_segments=12;sphere.rings=6;visual.mesh=sphere;visual.position=pos
 var mat=StandardMaterial3D.new();mat.albedo_color=color;visual.material_override=mat;parent.add_child(visual)
 Binder.sphere(parent,pos,radius)
static func build(parent: Node3D,graph: Dictionary) -> void:
 var c=Color(graph.get("color","#82c4bd"));var white=Color("e6edf2");var dark=Color("34445b")
 var kind=graph.kind
 if kind in ["robot","golem","ghost"]:
  add_box(parent,Vector3(0,.9,0),Vector3(.8,.9,.5),c)
  add_box(parent,Vector3(0,1.65,0),Vector3(.7,.65,.65),white if kind=="robot" else c)
  add_box(parent,Vector3(0,1.7,-.34),Vector3(.5,.12,.04),dark)
  for side in [-1,1]:
   add_box(parent,Vector3(side*.52,.9,0),Vector3(.22,.75,.25),c)
   add_box(parent,Vector3(side*.23,.25,0),Vector3(.25,.5,.3),white)
 elif kind in ["duck","pigeon","dog","cat"]:
  var bird=kind in ["duck","pigeon"]
  if bird: c=Color("e9cf69") if kind=="duck" else Color("9da9bc")
  add_box(parent,Vector3(0,.65,0),Vector3(.85,.7,1.15),c)
  add_box(parent,Vector3(0,1.15,-.45),Vector3(.6,.6,.6),c)
  add_box(parent,Vector3(0,1.08,-.85),Vector3(.5,.13,.35),Color("ed9e55") if bird else dark)
  for side in [-1,1]:
   add_box(parent,Vector3(side*.18,1.25,-.76),Vector3(.08,.1,.04),dark)
   add_box(parent,Vector3(side*.25,.17,0),Vector3(.16,.34,.25),Color("ed9e55") if bird else c)
   if kind=="cat": add_box(parent,Vector3(side*.2,1.56,-.4),Vector3(.2,.25,.2),c)
   if not bird: add_box(parent,Vector3(side*.25,.17,.4),Vector3(.16,.34,.25),c)
 elif kind=="spider":
  add_box(parent,Vector3(0,.6,0),Vector3(1,.6,1),c)
  for side in [-1,1]:
   for i in range(4): add_box(parent,Vector3(side*.7,.32,-.5+i*.3),Vector3(.8,.16,.14),dark)
 elif kind=="drone":
  add_box(parent,Vector3(0,.7,0),Vector3(.7,.4,.7),c)
  for x in [-.6,.6]:
   for z in [-.6,.6]:
    add_box(parent,Vector3(x,.7,z),Vector3(.6,.1,.6),dark)
 elif kind=="slime":
  add_box(parent,Vector3(0,.5,0),Vector3(1.1,.9,1.1),Color("8bd5aa"))
  for x in [-.23,.23]: add_box(parent,Vector3(x,.7,-.56),Vector3(.12,.15,.05),dark)
 elif kind=="sphere": add_sphere(parent,Vector3(0,.5,0),.5,c)
 elif kind=="wall": add_box(parent,Vector3(0,1.4,0),Vector3(4,2.8,.5),c)
 elif kind=="platform": add_box(parent,Vector3.ZERO,Vector3(4,.4,4),c)
 elif kind=="tower":
  add_box(parent,Vector3(0,1.5,0),Vector3(1.5,3,1.5),c)
  add_box(parent,Vector3(0,3.1,0),Vector3(2.1,.3,2.1),white)
 elif kind=="vehicle":
  add_box(parent,Vector3(0,.6,0),Vector3(2,.5,3),c)
  add_box(parent,Vector3(0,1.1,0),Vector3(1.4,.6,1.4),white)
  for x in [-1,1]:
   for z in [-1,1]: add_box(parent,Vector3(x,.3,z),Vector3(.3,.6,.6),dark)
 elif kind=="portal":
  for x in [-1,1]: add_box(parent,Vector3(x,1.3,0),Vector3(.3,2.6,.4),c)
  add_box(parent,Vector3(0,2.6,0),Vector3(2.3,.3,.4),c)
  add_box(parent,Vector3(0,1.3,0),Vector3(1.6,2.3,.08),Color("b69ae3"))
 elif kind=="gravity":
  add_box(parent,Vector3(0,1,0),Vector3(1.2,1.2,1.2),dark)
  add_box(parent,Vector3(0,1,0),Vector3(2.4,.12,2.4),Color("caa5ef"))
 elif kind=="shield":
  add_box(parent,Vector3(0,1,0),Vector3(2,2,.16),Color("80d6ec"))
 elif kind=="jetpack":
  for x in [-.25,.25]: add_box(parent,Vector3(x,.5,0),Vector3(.35,1,.4),c)
 elif kind=="tree":
  add_box(parent,Vector3(0,1,0),Vector3(.4,2,.4),Color("a87955"))
  add_box(parent,Vector3(0,2.5,0),Vector3(2.5,1.8,2.5),Color("89b97d"))
 elif kind=="launcher":
  add_box(parent,Vector3(0,.2,-.35),Vector3(.4,.35,1.1),c)
  add_box(parent,Vector3(0,-.1,0),Vector3(.2,.5,.25),dark)
 else:
  add_box(parent,Vector3(0,.5,0),Vector3.ONE,c)
 if "fly" in graph.get("mods",[]):
  for side in [-1,1]: add_box(parent,Vector3(side*.9,.9,0),Vector3(1.2,.1,.8),c.lightened(.15))
 var emitter=graph.get("emitter",{})
 if not emitter.is_empty():
  for i in int(emitter.get("count",1)):
   add_box(parent,Vector3((i-(float(emitter.count)-1)/2)*.35,1,-.7),Vector3(.23,.23,.65),dark)
