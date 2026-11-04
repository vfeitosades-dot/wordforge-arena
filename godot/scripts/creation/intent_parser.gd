class_name IntentParser
extends RefCounted
const Norm = preload("res://scripts/creation/text_normalizer.gd")
const Registry = preload("res://scripts/creation/concept_registry.gd")
static func parse(text: String) -> Dictionary:
 if text.length()>350: return {"ok":false,"error":"Pedido muito longo: use ate 350 caracteres."}
 var n = Norm.normalize(text)
 if n.is_empty(): return {"ok":false,"error":"Diga ou escreva uma criacao."}
 var result = {"ok":true,"text":text,"kind":"","quantity":1,"scale":1.0,"speed":3.0,"color":"#82c4bd","mods":[],"emitter":{},"ability":"","duration":35.0}
 if n.contains("quero voar") or n.contains("me fazer voar"):
  result.ability="fly"
 elif n.contains("pular") and (n.contains("alto") or n.contains("vezes")):
  result.ability="jump"
 elif n.contains("correr") and (n.contains("rapido") or n.contains("veloz")):
  result.ability="speed"
 elif n.contains("ficar invisivel"):
  result.ability="invisible"
 if not result.ability.is_empty():
  result.kind="ability"
  return result
 var emit_rx = RegEx.new()
 emit_rx.compile("\\b(lanca|lancam|dispara|disparam|atira|atiram|joga|jogam|cospe|cospem)\\b")
 var emit = emit_rx.search(n)
 var subject = n.substr(0,emit.get_start()) if emit else n
 var entity = Registry.find_entity(subject)
 if entity.kind.is_empty(): return {"ok":false,"error":"Nao reconheci a entidade. Exemplos: pato, robo, cubo, parede, torre, portal. Consulte o catalogo em Como jogar."}
 result.kind=entity.kind
 var tokens = subject.split(" ",false)
 for i in tokens.size():
  var token=tokens[i]
  if i<tokens.size()-1 and tokens[i+1] in ["saida","saidas","emissor","emissores"]: continue
  if token in Registry.NUMBERS and Registry.NUMBERS[token]>1: result.quantity=Registry.NUMBERS[token];break
  if token.is_valid_int(): result.quantity=int(token);break
 if "gigante" in tokens or "gigantes" in tokens: result.scale=2.4
 elif "grande" in tokens or "grandes" in tokens: result.scale=1.7
 elif "pequeno" in tokens or "pequenos" in tokens or "mini" in tokens: result.scale=.6
 for token in tokens:
  if token in Registry.COLORS: result.color=Registry.COLORS[token]
 if subject.contains("rapido") or subject.contains("veloz"): result.speed=6.0
 if subject.contains("lento"): result.speed=1.4
 var synonyms={"fly":["voador","voadora","voadores","voa","voam","voar","propulsao","asas"],"orbit":["orbita","orbitando","orbitam","orbitante"],"follow":["siga","sigam","seguir","seguidor","acompanha","seguem"],"bounce":["saltitante","pula","pulam","elastico","elastica"],"spin":["giratorio","giratoria","gira","giram"],"glow":["luminoso","luminosa","brilhante"],"invisible":["invisivel","invisiveis"]}
 for mod in synonyms:
  for word in synonyms[mod]:
   if word in tokens:
    if mod not in result.mods: result.mods.append(mod)
 if result.kind in Registry.CREATURES and "orbit" not in result.mods and "follow" not in result.mods: result.mods.append("follow")
 if result.kind in ["pigeon","drone","ghost"] and "fly" not in result.mods: result.mods.append("fly")
 if result.kind=="jetpack": result.ability="fly"
 if emit:
  var tail = n.substr(emit.get_end())
  var projectile=Registry.find_entity(tail)
  if projectile.kind.is_empty(): return {"ok":false,"error":"Reconheci o emissor, mas falta o que ele lanca. Exemplo: bolas de tinta, cubos ou passaros."}
  result.emitter={"kind":projectile.kind,"color":"#ed8dba" if tail.contains("tinta") else result.color,"count":1,"paint":tail.contains("tinta"),"elastic":tail.contains("gelatina") or tail.contains("elastico")}
  var outlets=RegEx.new()
  outlets.compile("(tres|quatro|dois|[1-4]) (saidas|emissores)")
  var outlet_match=outlets.search(subject)
  if outlet_match: result.emitter.count=Registry.NUMBERS.get(outlet_match.get_string(1),int(outlet_match.get_string(1)))
 elif result.kind in ["launcher","tower"]:
  result.emitter={"kind":"sphere","color":result.color,"count":1,"paint":true,"elastic":false}
 var known="quero criar crie cria faz faca fazer me da dar eu um uma uns umas o a os as com sem que e de do da dos das por para no na em ao aos consiga pode capaz ficam fica minha meu sua seu cabeca volta torno perto automatico automaticamente propulsao grande grandes gigante gigantes pequeno pequena pequenos pequenas mini rapido rapida rapidos lento lenta voador voadora voadores voadoras voa voam voar asas orbita orbitando orbitam orbitante siga sigam seguir seguidor acompanha seguem saltitante pula pulam elastico elastica giratorio giratoria gira giram luminoso luminosa brilhante invisivel invisiveis lanca lancam dispara disparam atira atiram joga jogam cospe cospem tinta colorida coloridas colorido coloridos saida saidas saídas infinito infinitos multiplica".split(" ",false)
 for aliases in Registry.ENTITIES.values():
  for alias in aliases:
   for word in alias.split(" ",false):known.append(word)
 for color in Registry.COLORS:known.append(color)
 for number in Registry.NUMBERS:known.append(number)
 for word in n.split(" ",false):
  if word not in known and not word.is_valid_int():return {"ok":false,"error":"Conceito ou modificador nao reconhecido: '"+word+"'. Consulte o catalogo e reformule."}
 if result.kind=="portal":result.quantity=2
 if result.quantity<1 or result.quantity>5: return {"ok":false,"error":"Crie entre 1 e 5 entidades por pedido."}
 if subject.contains("infinito") or subject.contains("infinitos") or subject.contains("multiplica"):
  return {"ok":false,"error":"Geracao recursiva ou infinita nao e suportada. Use quantidade de 1 a 5."}
 return result
