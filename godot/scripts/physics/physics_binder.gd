class_name PhysicsBinder
extends RefCounted
static func box(parent: Node3D,position: Vector3,size: Vector3) -> void:
 var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;collider.shape=shape;collider.position=position;parent.add_child(collider)
static func sphere(parent: Node3D,position: Vector3,radius: float) -> void:
 var collider=CollisionShape3D.new();var shape=SphereShape3D.new();shape.radius=radius;collider.shape=shape;collider.position=position;parent.add_child(collider)
static func bounds(graph: Dictionary) -> Vector3:
 var sizes={"wall":Vector3(4,2.8,.5),"platform":Vector3(4,.4,4),"tower":Vector3(2.1,3.4,2.1),"vehicle":Vector3(2.3,1.5,3),"portal":Vector3(2.3,2.9,.5),"tree":Vector3(2.5,3.4,2.5),"gravity":Vector3(2.4,2,2.4)}
 return sizes.get(graph.kind,Vector3(1.3,1.9,1.5))*float(graph.get("scale",1))
