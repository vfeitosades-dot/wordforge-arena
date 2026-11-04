extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);seed(444);game.mode_box.select(2);game.start_match();Engine.max_fps=0
 await create_timer(1).timeout
 game.paused=true
 var samples=[];var prev=Time.get_ticks_usec();var draws=[];var triangles=[]
 for i in 180:
  await RenderingServer.frame_post_draw
  var now=Time.get_ticks_usec();samples.append((now-prev)/1000.0);prev=now;draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));triangles.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
 samples.sort();var mean=0.0
 for v in samples:mean+=v
 mean/=samples.size()
 var report={"renderer":"OpenGL llvmpipe software; not reference GPU","resolution":[root.size.x,root.size.y],"frames":samples.size(),"average_fps":1000/mean,"one_percent_low_fps":1000/samples[int(samples.size()*.99)],"mean_frame_ms":mean,"draw_calls":draws[-1],"primitives":triangles[-1],"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_reported_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
 var name=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "baseline"
 var file=FileAccess.open("user://aurora-"+name+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 root.get_texture().get_image().save_png("user://aurora-"+name+".png")
 print(JSON.stringify(report));quit()
