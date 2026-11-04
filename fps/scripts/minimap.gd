extends Control
var game
func _process(_dt: float) -> void:queue_redraw()
func point(p: Vector3) -> Vector2:return Vector2(100+p.x*3.5,100+p.z*3.5)
func _draw() -> void:
 if not is_instance_valid(game) or not game.playing or not is_instance_valid(game.arena):return
 draw_style_box(game.style(Color(.025,.06,.085,.9),Color("4b6e7f")),Rect2(0,0,200,200))
 draw_rect(Rect2(16,16,168,168),Color("243e4c"))
 for cell in game.arena.solid:
  draw_rect(Rect2(100+cell.x*3.5,100+cell.y*3.5,3.5,3.5),Color("657d8c"))
 for i in 2:
  var pos=point(Vector3(-17 if i==0 else 17,0,-17));draw_circle(pos,8,Color("68bfa9") if i==0 else Color("dfab8b"))
 if is_instance_valid(game.player):
  var p=point(game.player.position);draw_circle(p,4,Color("a3ffe1"));draw_line(p,p+Vector2(-sin(game.yaw),-cos(game.yaw))*11,Color.WHITE,2)
 for bot in game.enemies:
  if is_instance_valid(bot) and bot.active and game.visible_enemy(bot):draw_circle(point(bot.position),3,Color("f29380"))
 if game.mode==3 and game.tactical.planted:draw_arc(point(game.tactical.plant_position),10,0,TAU,24,Color("ffcd7c"),2)
