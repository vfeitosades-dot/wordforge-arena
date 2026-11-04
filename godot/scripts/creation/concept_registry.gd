class_name ConceptRegistry
extends RefCounted
const DEFAULT_ENTITIES = {
 "robot":["robo","robos","robot"],"duck":["pato","patos","duck"],"pigeon":["pombo","pombos","passaro","passaros","bird"],
 "dog":["cachorro","cachorros","cao","caes","dog"],"cat":["gato","gatos","cat"],"drone":["drone","drones"],
 "spider":["aranha","aranhas"],"slime":["gelatina","gelatinoso","gelatinosa","slime"],"golem":["golem","pedra"],"ghost":["fantasma","fantasmas"],
 "cube":["cubo","cubos","bloco","blocos","cube"],"sphere":["bola","bolas","esfera","esferas","bolinha","bolinhas"],
 "wall":["parede","paredes","muro","muros"],"platform":["plataforma","plataformas","ponte"],"tower":["torre","torres"],
 "vehicle":["carro","carros","veiculo","veiculos"],"launcher":["lancador","lancadores","emissor","emissores","arma","armas","pistola"],
 "shield":["escudo","escudos"],"portal":["portal","portais"],"gravity":["buraco negro","campo gravitacional","campo de gravidade"],
 "jetpack":["jetpack","mochila propulsora"],"tree":["arvore","arvores"]
}
const CREATURES = ["robot","duck","pigeon","dog","cat","drone","spider","slime","golem","ghost"]
const COLORS = {"azul":"#70a9ec","vermelho":"#e97b63","vermelha":"#e97b63","verde":"#87bb77","amarelo":"#edd36c","amarela":"#edd36c","rosa":"#eaa4cc","roxo":"#b093db","branco":"#e9eff5","branca":"#e9eff5","preto":"#3d4654","preta":"#3d4654","laranja":"#ecac6b"}
const NUMBERS = {"um":1,"uma":1,"dois":2,"duas":2,"tres":3,"quatro":4,"cinco":5,"seis":6,"sete":7,"oito":8}
static func find_entity(text: String) -> Dictionary:
 var best = {"kind":"","position":999999,"end":0}
 for kind in ENTITIES:
  for alias in ENTITIES[kind]:
   var rx = RegEx.new()
   rx.compile("\\b"+alias+"\\b")
   var m = rx.search(text)
   if m and (m.get_start()<best.position or (m.get_start()==best.position and alias.length()>best.end-best.position)):
    best = {"kind":kind,"position":m.get_start(),"end":m.get_end()}
 return best

static var ENTITIES: Dictionary = _load_entities()
static func _load_entities() -> Dictionary:
 var path="res://data/concepts.json"
 if FileAccess.file_exists(path):
  var data=JSON.parse_string(FileAccess.get_file_as_string(path))
  if data is Dictionary:return data
 return DEFAULT_ENTITIES.duplicate(true)
