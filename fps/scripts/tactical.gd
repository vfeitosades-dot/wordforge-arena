class_name BreachTactical
extends RefCounted
const BUY_TIME=8.0
const ROUND_TIME=90.0
const FUSE_TIME=35.0
const PLANT_TIME=2.5
const DEFUSE_TIME=4.0
const SITES=[Vector3(-17,0,-17),Vector3(17,0,-17)]
var phase="idle"
var cash=800
var score_attack=0
var score_defend=0
var round_number=0
var timer=0.0
var plant_progress=0.0
var defuse_progress=0.0
var planted=false
var plant_position=Vector3.ZERO
var planting_site=-1
var armor=0.0
var bought=1
var result=""
func start() -> void:
 cash=800;score_attack=0;score_defend=0;round_number=0;begin_round()
func begin_round() -> void:
 round_number+=1;phase="buy";timer=BUY_TIME;plant_progress=0;defuse_progress=0;planted=false;planting_site=-1;armor=0;bought=1;result=""
func purchase(item: String) -> String:
 if phase!="buy":return "Compras disponiveis somente na preparacao."
 var costs={"rifle":1000,"marksman":1400,"armor":350}
 if item not in costs:return "Compra invalida."
 if item=="armor" and armor>0:return "Blindagem ja adquirida."
 if item=="rifle" and bought==0 or item=="marksman" and bought==2:return "Arma ja adquirida."
 if cash<costs[item]:return "Creditos insuficientes: precisa de %d."%costs[item]
 cash-=costs[item]
 if item=="armor":armor=50
 elif item=="rifle":bought=0
 elif item=="marksman":bought=2
 return ""
func site_near(position: Vector3) -> int:
 for i in SITES.size():
  if Vector2(position.x-SITES[i].x,position.z-SITES[i].z).length()<3.2:return i
 return -1
func step(dt: float,position: Vector3,interacting: bool,player_alive: bool,defender_near: bool,stationary=true) -> String:
 if phase=="idle" or phase=="finished":return ""
 timer=maxf(0,timer-dt)
 if phase=="buy":
  if timer<=0:phase="live";timer=ROUND_TIME;return "live"
  return ""
 if phase=="result":
  if timer<=0:
   if score_attack>=3 or score_defend>=3:phase="finished";return "finished"
   begin_round();return "round"
  return ""
 if not player_alive and not planted:return finish(false,"Operador eliminado")
 if not planted:
  var site=site_near(position)
  if interacting and player_alive and stationary and site>=0:
   if planting_site!=site:plant_progress=0;planting_site=site
   plant_progress+=dt
   if plant_progress>=PLANT_TIME:
    planted=true;plant_position=SITES[site];timer=FUSE_TIME;plant_progress=PLANT_TIME;return "planted"
  else:plant_progress=0;planting_site=-1
  if timer<=0:return finish(false,"Tempo esgotado")
 else:
  defuse_progress=defuse_progress+dt if defender_near else 0.0
  if defuse_progress>=DEFUSE_TIME:return finish(false,"Dispositivo desarmado")
  if timer<=0:return finish(true,"Ruptura concluida")
 return ""
func finish(attack_wins: bool,reason: String) -> String:
 if phase!="live":return ""
 if attack_wins:score_attack+=1;cash+=1000
 else:score_defend+=1;cash+=600
 phase="result";timer=4;result=reason
 return "result"
func apply_damage(amount: float) -> float:
 var absorbed=minf(armor,amount*.6);armor-=absorbed;return amount-absorbed
