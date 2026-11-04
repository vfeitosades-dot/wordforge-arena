class_name CostCalculator
extends RefCounted
const BASE={"cube":5,"sphere":7,"wall":15,"platform":30,"launcher":40,"robot":65,"duck":30,"pigeon":30,"dog":40,"cat":40,"drone":65,"spider":45,"slime":35,"golem":65,"ghost":55,"tower":70,"vehicle":90,"shield":70,"portal":65,"gravity":160,"jetpack":85,"tree":20,"ability":55}
static func calculate(graph: Dictionary) -> int:
 if not graph.get("ok",false): return 0
 var base=float(BASE.get(graph.kind,50))
 var scale_factor=clampf(pow(float(graph.get("scale",1)),1.5),.45,5)
 var modifiers=graph.get("mods",[]).size()*8
 var emitter=graph.get("emitter",{})
 var emission=20*int(emitter.get("count",0)) if not emitter.is_empty() else 0
 return clampi(ceili((base*scale_factor+modifiers+emission)*int(graph.get("quantity",1))),1,3000)
