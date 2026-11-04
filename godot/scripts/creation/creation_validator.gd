class_name CreationValidator
extends RefCounted
static func validate(graph: Dictionary, matter: int, active_count: int) -> String:
 if not graph.get("ok",false): return graph.get("error","Pedido invalido")
 if int(graph.get("quantity",1))<1 or int(graph.get("quantity",1))>5: return "Quantidade permitida: 1 a 5."
 if active_count+int(graph.get("quantity",1))>24: return "Limite de 24 criacoes ativas. Remova uma criacao antes."
 if int(graph.get("cost",0))>matter: return "Materia insuficiente: precisa de %d; disponivel %d." % [graph.cost,matter]
 return ""
