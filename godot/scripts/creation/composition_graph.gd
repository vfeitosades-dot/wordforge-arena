class_name CompositionGraph
extends RefCounted
const Parser=preload("res://scripts/creation/intent_parser.gd")
const Cost=preload("res://scripts/creation/cost_calculator.gd")
static func from_text(text: String) -> Dictionary:
 var graph=Parser.parse(text)
 if graph.get("ok",false):
  graph["schema"]=1
  graph["cost"]=Cost.calculate(graph)
 return graph
