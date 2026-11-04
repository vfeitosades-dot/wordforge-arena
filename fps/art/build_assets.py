import bpy,math,os,json
from mathutils import Vector
OUT=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'assets');os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
def mat(name,color,metal=0):
 if name not in materials:
  m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.38;materials[name]=m
 return materials[name]
INK=mat('graphite',(.035,.065,.09),.7);STEEL=mat('titanium',(.22,.29,.33),.8);IVORY=mat('ceramic',(.8,.82,.75),.3);SKIN=mat('glove',(.12,.18,.2));ACC=[mat('mint',(.13,.85,.7),.35),mat('ember',(.95,.27,.12),.35),mat('lilac',(.49,.37,.9),.35),mat('gold',(.9,.68,.18),.3)]
collections=[]
def newrig(name,bones):
 col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col);collections.append(col)
 arm=bpy.data.armatures.new(name+'_skeleton');rig=bpy.data.objects.new(name,arm);col.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 for n,head,tail,parent in bones:
  b=arm.edit_bones.new(n);b.head=head;b.tail=tail
  if parent:b.parent=arm.edit_bones[parent]
 bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False);return col,rig

def piece(col,rig,name,loc,scale,material,bone='root',bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o);o.data.materials.append(material)
 if bevel:
  mod=o.modifiers.new('crafted_edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('rig','ARMATURE');mod.object=rig;o.parent=rig;o.select_set(False);return o

def actions(rig,kind,variant):
 for name,length in [('idle',120),('aim',120),('walk',48),('run',36),('jump',40),('fire',9),('reload',108),('equip',36),('inspect',120),('ability',72),('strafe_left',48),('strafe_right',48),('walk_back',48),('crouch_idle',120),('crouch_walk',60),('hit',24),('death',66)]:
  if kind=='weapon' and name not in ['idle','walk','run','jump','fire','reload','equip','inspect','ability']:continue
  action=bpy.data.actions.new(rig.name+'_'+name);rig.animation_data_create();rig.animation_data.action=action
  for frame in range(1,length+1,3):
   t=(frame-1)/max(1,length-1);wave=math.sin(t*math.tau)
   for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
   root=rig.pose.bones['root']
   if kind=='weapon':
    if name=='idle':root.location.z=wave*.003
    if name in ('walk','run','strafe_left','strafe_right','walk_back','crouch_walk'):root.location.z=math.sin(t*math.tau*2)*(.012 if name=='walk' else .025);root.rotation_euler.y=wave*.025
    if name=='fire':root.location.y=-math.sin(t*math.pi)*.065;root.rotation_euler.x=math.sin(t*math.pi)*.08;rig.pose.bones['bolt'].location.y=-math.sin(t*math.pi)*.06
    if name=='reload':
     root.rotation_euler.y=math.sin(t*math.pi)*-.38;root.rotation_euler.x=math.sin(t*math.pi)*-.15
     rig.pose.bones['magazine'].location.z=-.3*max(0,math.sin(min(1,max(0,(t-.12)/.64))*math.pi))
     rig.pose.bones['left_hand'].location.z=-.16*math.sin(t*math.pi);rig.pose.bones['left_hand'].location.y=-.1*math.sin(t*math.pi)
     rig.pose.bones['bolt'].location.y=-.07*max(0,math.sin((t-.75)*4*math.pi)) if t>.75 else 0
    if name=='equip':root.location.z=-.35*(1-t)**2;root.rotation_euler.y=(1-t)*.5
    if name=='inspect':root.rotation_euler.y=math.sin(t*math.pi)*.65;root.location.x=-math.sin(t*math.pi)*.08
   else:
    if name=='idle':root.location.z=wave*.008;rig.pose.bones['head'].rotation_euler.z=wave*.035
    if name in ('walk','run','strafe_left','strafe_right','walk_back','crouch_walk'):
     for i,n in enumerate(['leg_l','leg_r']):rig.pose.bones[n].rotation_euler.x=wave*(.55 if name=='walk' else .9)*(-1 if i else 1)
     for i,n in enumerate(['arm_l','arm_r']):rig.pose.bones[n].rotation_euler.x=wave*.4*(1 if i else -1)
     root.location.z=abs(wave)*.025
     for suffix in ['l','r']:
      if 'calf_'+suffix in rig.pose.bones:rig.pose.bones['calf_'+suffix].rotation_euler.x=max(0,-wave if suffix=='l' else wave)*.7
     if name.startswith('strafe'):root.rotation_euler.z=.18 if name=='strafe_left' else -.18
    if name.startswith('crouch'):root.location.z=-.25;root.rotation_euler.x=.15
    if name=='hit':root.rotation_euler.x=math.sin(t*math.pi)*.18
    if name=='death':root.rotation_euler.x=-t*1.45;root.location.z=-t*.7
    if name=='jump':root.location.z=math.sin(t*math.pi)*.15;rig.pose.bones['leg_l'].rotation_euler.x=-math.sin(t*math.pi)*.6
    if name in ('aim','fire','reload'):
     for bone,angles in [('arm_r',(.72,-.03,-.36)),('forearm_r',(1.28,-.8,.6)),('arm_l',(1,.715,-.585)),('forearm_l',(0,-.79,.135))]:rig.pose.bones[bone].rotation_euler=angles
     if name=='fire':rig.pose.bones['arm_r'].rotation_euler.x+=math.sin(t*math.pi)*.045
     if name=='reload':
      rig.pose.bones['arm_l'].rotation_euler.x-=math.sin(t*math.pi)*.7
      rig.pose.bones['forearm_l'].rotation_euler.z+=math.sin(t*math.pi)*.3
    if name in ('ability','inspect'):
     rig.pose.bones['arm_l' if variant%2==0 else 'arm_r'].rotation_euler.x=math.sin(t*math.pi)*(1.4+variant*.2)
     rig.pose.bones['head'].rotation_euler.z=math.sin(t*math.pi)*(.35 if variant==1 else -.25)
     root.rotation_euler.z=math.sin(t*math.pi)*(.15+variant*.1)
   for pb in rig.pose.bones:
    pb.keyframe_insert('location',frame=frame,group=pb.name);pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name)
  track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action);strip.name=name
 rig.animation_data.action=None
 for pb in rig.pose.bones:pb.rotation_euler=(0,0,0);pb.location=(0,0,0)

def weapon(name,v):
 bones=[('root',(0,0,0),(0,0,.1),None),('bolt',(0,.1,.13),(0,.2,.13),'root'),('magazine',(0,.08,0),(0,.08,-.1),'root'),('left_hand',(-.12,.3,-.06),(-.12,.4,-.06),'root'),('right_hand',(.06,-.1,-.08),(.06,-.1,-.2),'root')]
 col,rig=newrig(name,bones);a=ACC[v];length=[.75,.43,1.1][v]
 piece(col,rig,'receiver',(0,.15,.12),(.13,length*.5,.13),IVORY)
 piece(col,rig,'lower_receiver',(0,.08,.035),(.11,.27,.09),INK)
 piece(col,rig,'barrel',(0,length*.68,.12),(.055,length*.55,.055),STEEL)
 piece(col,rig,'muzzle',(0,length*.94,.12),(.075,.09,.075),INK)
 piece(col,rig,'rail',(0,.2,.205),(.075,length*.55,.025),INK)
 for i in range(6):piece(col,rig,'rail_tooth',(0,.02+i*.05,.225),(.08,.02,.015),STEEL,bevel=.004)
 piece(col,rig,'grip',(.012,-.08,-.055),(.085,.09,.21),INK)
 piece(col,rig,'magazine',(0,.12,-.12),(.09,.12,.2),a,'magazine')
 piece(col,rig,'mag_base',(0,.12,-.23),(.11,.15,.035),INK,'magazine')
 piece(col,rig,'charging_handle',(.085,.12,.15),(.06,.08,.035),a,'bolt')
 piece(col,rig,'accent_l',(-.071,.13,.14),(.012,.23,.025),a)
 if v!=1:
  piece(col,rig,'stock',(0,-.24,.1),(.1,.25,.1),STEEL)
  piece(col,rig,'butt_plate',(0,-.38,.09),(.13,.045,.2),INK)
  piece(col,rig,'front_guard',(0,.38,.1),(.15,.23,.11),a)
 if v==2:
  piece(col,rig,'optic_body',(0,.2,.3),(.09,.26,.1),INK)
  piece(col,rig,'optic_lens',(0,.335,.3),(.07,.015,.075),a)
 for side,bone,y in [(-1,'left_hand',.34),(1,'right_hand',-.08)]:
  piece(col,rig,'palm_'+bone,(side*.065,y,-.055),(.085,.14,.07),SKIN,bone)
  piece(col,rig,'sleeve_'+bone,(side*.12,y-.14,-.11),(.11,.24,.11),a,bone)
  for i in range(4):piece(col,rig,'finger_'+bone,(side*.075,y-.04+i*.027,-.105),(.075,.019,.035),INK,bone,bevel=.006)
 actions(rig,'weapon',v);return col,rig

def bind_mesh(o,col,rig,material,bone):
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o);o.data.materials.append(material)
 group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('rig','ARMATURE');mod.object=rig;o.parent=rig;o.select_set(False);return o

def ellipsoid(col,rig,name,pos,size,material,bone):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=1,location=pos);o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return bind_mesh(o,col,rig,material,bone)

def limb(col,rig,name,a,b,r1,r2,material,bone):
 d=Vector(b)-Vector(a);bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=r1,radius2=r2,depth=d.length,location=(Vector(a)+Vector(b))/2)
 o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y');bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return bind_mesh(o,col,rig,material,bone)

def hero(name,v):
 bones=[('root',(0,0,.94),(0,0,1.04),None),('torso',(0,0,1.04),(0,0,1.46),'root'),('neck',(0,0,1.5),(0,0,1.61),'torso'),('head',(0,0,1.61),(0,0,1.84),'neck')]
 for side,suffix in [(-1,'l'),(1,'r')]:
  bones += [('clavicle_'+suffix,(0,0,1.44),(side*.24,0,1.45),'torso'),('arm_'+suffix,(side*.25,0,1.44),(side*.31,.015,1.17),'clavicle_'+suffix),('forearm_'+suffix,(side*.31,.015,1.17),(side*.32,.035,.94),'arm_'+suffix),('hand_'+suffix,(side*.32,.035,.94),(side*.32,.07,.81),'forearm_'+suffix),('leg_'+suffix,(side*.12,0,.95),(side*.13,.015,.54),'root'),('calf_'+suffix,(side*.13,.015,.54),(side*.13,0,.13),'leg_'+suffix),('foot_'+suffix,(side*.13,0,.13),(side*.13,.18,.08),'calf_'+suffix)]
  for i in range(3):bones.append(('finger_%s_%d'%(suffix,i),(side*.32-.025+i*.025,.07,.85),(side*.32-.025+i*.025,.09,.78),'hand_'+suffix))
 col,rig=newrig(name,bones);accent=ACC[v]
 skin=mat('skin_'+name,[(.57,.3,.21),(.47,.29,.2),(.72,.43,.29),(.27,.14,.085)][v])
 cloth=mat('cloth_'+name,[(.15,.24,.23),(.19,.2,.22),(.15,.14,.23),(.2,.24,.3)][v]);hair=mat('hair_'+name,[(.035,.025,.03),(.12,.075,.035),(.055,.035,.075),(.018,.024,.03)][v])
 ellipsoid(col,rig,'jacket_shape',(0,0,1.26),(.235,.145,.29),cloth,'torso')
 piece(col,rig,'chest_plate',(0,.135,1.3),(.3,.07,.26),IVORY if v==1 else cloth,'torso',.04)
 piece(col,rig,'zipper',(0,.177,1.27),(.016,.012,.27),accent,'torso',.003)
 piece(col,rig,'collar',(0,0,1.5),(.25,.24,.09),accent,'torso',.03)
 ellipsoid(col,rig,'hips',(0,0,.96),(.18,.13,.13),INK,'root')
 piece(col,rig,'belt',(0,.02,1.02),(.34,.27,.05),STEEL,'root',.012)
 for x in [-.15,.15]:piece(col,rig,'belt_pouch',(x,.15,.99),(.09,.07,.12),cloth,'root',.012)
 limb(col,rig,'neck_skin',(0,0,1.49),(0,0,1.65),.065,.065,skin,'neck')
 ellipsoid(col,rig,'face_planes',(0,.015,1.737),(.096,.088,.126),skin,'head')
 ellipsoid(col,rig,'jaw',(0,.045,1.674),(.077,.067,.062),skin,'head')
 piece(col,rig,'nose',(0,.112,1.733),(.029,.055,.045),skin,'head',.009)
 piece(col,rig,'mouth',(0,.104,1.682),(.047,.008,.008),mat('lip',(.27,.105,.085)),'head',.003)
 for x in [-.043,.043]:
  piece(col,rig,'eye_white',(x,.096,1.753),(.038,.015,.017),IVORY,'head',.006)
  piece(col,rig,'iris',(x,.106,1.753),(.014,.006,.015),hair,'head',.003)
  piece(col,rig,'brow',(x,.103,1.775),(.046,.012,.008),hair,'head',.003)
  ellipsoid(col,rig,'ear',(x*2.3,.0,1.73),(.017,.025,.035),skin,'head')
 ellipsoid(col,rig,'hair_cap',(0,-.005,1.823),(.101,.091,.052),hair,'head')
 if v==0:
  for x in [-.09,.09]:ellipsoid(col,rig,'bob_side',(x,-.022,1.76),(.024,.082,.09),hair,'head')
  piece(col,rig,'medical_pack',(.19,-.14,1.19),(.12,.12,.24),IVORY,'torso',.035)
  piece(col,rig,'medical_mark',(.19,-.207,1.2),(.065,.01,.02),accent,'torso',.005)
 elif v==1:
  piece(col,rig,'brow_guard',(0,.075,1.81),(.21,.1,.045),STEEL,'head',.02)
  piece(col,rig,'field_pack',(0,-.19,1.29),(.25,.14,.29),STEEL,'torso',.03)
 elif v==2:
  limb(col,rig,'ponytail',(0,-.06,1.81),(.04,-.21,1.57),.045,.025,hair,'head')
  for side in [-1,1]:piece(col,rig,'coat_tail',(side*.11,-.1,.95),(.15,.12,.38),cloth,'root',.035)
 else:
  piece(col,rig,'recon_eye',(.067,.112,1.76),(.06,.025,.035),accent,'head',.01)
  piece(col,rig,'radio',(0,-.2,1.38),(.15,.1,.22),INK,'torso',.025)
  limb(col,rig,'radio_aerial',(.08,-.21,1.45),(.08,-.21,1.68),.008,.006,STEEL,'torso')
 for side,suffix in [(-1,'l'),(1,'r')]:
  upper=(side*.25,0,1.43);elbow=(side*.31,.015,1.17);wrist=(side*.32,.035,.94)
  ellipsoid(col,rig,'deltoid',upper,(.105,.105,.12),IVORY if v==1 else cloth,'arm_'+suffix)
  limb(col,rig,'upper_sleeve',upper,elbow,.085,.067,cloth,'arm_'+suffix)
  limb(col,rig,'forearm_sleeve',elbow,wrist,.07,.049,cloth,'forearm_'+suffix)
  piece(col,rig,'wrist_cuff',(side*.32,.035,.97),(.1,.11,.08),accent,'forearm_'+suffix,.017)
  ellipsoid(col,rig,'gloved_palm',(side*.32,.048,.876),(.047,.035,.067),SKIN,'hand_'+suffix)
  for i in range(3):limb(col,rig,'finger',(side*.32-.025+i*.025,.07,.86),(side*.32-.025+i*.025,.09,.80),.012,.01,SKIN,'finger_%s_%d'%(suffix,i))
  limb(col,rig,'thigh',(side*.12,0,.95),(side*.13,.015,.54),.105,.077,INK,'leg_'+suffix)
  limb(col,rig,'calf',(side*.13,.015,.54),(side*.13,0,.14),.073,.049,cloth,'calf_'+suffix)
  piece(col,rig,'kneepad',(side*.13,.08,.55),(.12,.06,.13),accent,'calf_'+suffix,.025)
  piece(col,rig,'boot',(side*.13,.065,.105),(.14,.29,.19),INK,'foot_'+suffix,.035)
 actions(rig,'hero',v)
 # Merge by material while retaining weighted vertex groups to reduce draw submissions.
 groups={}
 for o in list(col.objects):
  if o.type=='MESH':groups.setdefault(o.data.materials[0].name,[]).append(o)
 for meshes in groups.values():
  bpy.ops.object.select_all(action='DESELECT')
  for o in meshes:o.select_set(True)
  bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();bpy.context.object.select_set(False)
 return col,rig

all_assets=[weapon(n,i) for i,n in enumerate(['Kestrel','Wisp','Longbow'])]+[hero(n,i)for i,n in enumerate(['Serein','Rook','Vesper','Lumen'])]
for col,rig in all_assets:
 bpy.ops.object.select_all(action='DESELECT')
 for o in col.objects:o.select_set(True)
 bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,col.name+'.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_frame_range=False)
 if col.name in ['Kestrel','Wisp','Longbow']:
  world_groups={}
  for o in list(col.objects):
   if o.type=='MESH' and not any(k in o.name for k in ['palm','sleeve','finger']):world_groups.setdefault(o.data.materials[0].name,[]).append(o)
  merged=[]
  for meshes in world_groups.values():
   bpy.ops.object.select_all(action='DESELECT')
   for o in meshes:o.select_set(True)
   bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();merged.append(bpy.context.object)
  bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
  for o in merged:o.select_set(True)
  bpy.context.view_layer.objects.active=rig
  bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,col.name+'World.glb'),use_selection=True,export_format='GLB',export_animations=False)
 bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.dirname(__file__),'Aurora_Source.blend'))
print('AURORA_ASSETS_OK',len(all_assets))
