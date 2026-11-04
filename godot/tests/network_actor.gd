extends SceneTree
var main
var role=""
func _initialize() -> void:call_deferred("run")
func run() -> void:
 role=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "host"
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 if role=="host":
  main._host();main.players[1].matter=100;main._create_for(1,"um cubo");main.world.set_block(Vector3i(0,-1,0),-1);main.world.rebuild_all();print("HOST_READY")
  var granted={}
  for i in range(1200):
   for id in main.players:
    if id!=1 and not granted.has(id):main.players[id].matter=100;granted[id]=true
   await physics_frame
  quit(0)
 else:
  main.ip_box.text="127.0.0.1";main.name_box.text="QA "+role;main._join()
  if role=="client-b":main.yaw=-PI/2
  var sent=false
  for i in range(900):
   await physics_frame
   if main.players.has(main.local_id) and main.players[main.local_id].matter==100 and main.players[main.local_id].position.y<.5 and not sent:
    if main.world.blocks.has(Vector3i(0,-1,0)):push_error("Terrain delta missing");quit(2);return
    if main.entities.size()<1:continue
    main._request_creation.rpc_id(1,"um cubo");sent=true
   if sent and main.players.has(main.local_id) and main.players[main.local_id].matter==95:
    var own=false
    for e in main.entities.values():own=own or e.owner_id==main.local_id
    if own:print("CLIENT_NET_OK: "+role);quit(0);return
  push_error("Network timeout: "+role+" "+main.status_text);quit(1)
