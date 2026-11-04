import bpy,math,os,json
from mathutils import Vector
OUT=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'assets');os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
def mat(name,color,metal=0):
 if name not in materials:
  m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.38;materials[name]=m
 return materials[name]
INK=mat('graphite',(.035,.065,.09),.7);STEEL=mat('titanium',(.22,.29,.33),.8);IVORY=mat('ceramic',(.8,.82,.75),.3);SKIN=mat('glove',(.12,.18,.2));ACC=[mat('mint',(.13,.85,.7),.35),mat('ember',(.95,.27,.12),.35),mat('lilac',(.49,.37,.9),.35)]
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
 for name,length in [('idle',120),('walk',48),('run',36),('jump',40),('fire',9),('reload',108),('equip',36),('inspect',120),('ability',72)]:
  action=bpy.data.actions.new(rig.name+'_'+name);rig.animation_data_create();rig.animation_data.action=action
  for frame in range(1,length+1,3):
   t=(frame-1)/max(1,length-1);wave=math.sin(t*math.tau)
   for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
   root=rig.pose.bones['root']
   if kind=='weapon':
    if name=='idle':root.location.z=wave*.003
    if name in ('walk','run'):root.location.z=math.sin(t*math.tau*2)*(.012 if name=='walk' else .025);root.rotation_euler.y=wave*.025
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
    if name in ('walk','run'):
     for i,n in enumerate(['leg_l','leg_r']):rig.pose.bones[n].rotation_euler.x=wave*(.55 if name=='walk' else .9)*(-1 if i else 1)
     for i,n in enumerate(['arm_l','arm_r']):rig.pose.bones[n].rotation_euler.x=wave*.4*(1 if i else -1)
     root.location.z=abs(wave)*.04
    if name=='jump':root.location.z=math.sin(t*math.pi)*.15;rig.pose.bones['leg_l'].rotation_euler.x=-math.sin(t*math.pi)*.6
    if name=='fire':rig.pose.bones['arm_r'].rotation_euler.x=-1.1+math.sin(t*math.pi)*.1;rig.pose.bones['arm_l'].rotation_euler.x=-.7
    if name=='reload':rig.pose.bones['arm_l'].rotation_euler.x=-.5-math.sin(t*math.pi)*.8;rig.pose.bones['arm_r'].rotation_euler.x=-.9
    if name in ('ability','inspect'):
     rig.pose.bones['arm_l' if variant%2==0 else 'arm_r'].rotation_euler.x=-math.sin(t*math.pi)*(1.4+variant*.2)
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

def hero(name,v):
 bones=[('root',(0,0,.9),(0,0,1.05),None),('torso',(0,0,1.05),(0,0,1.5),'root'),('head',(0,0,1.55),(0,0,1.8),'torso'),('arm_l',(-.27,0,1.45),(-.27,0,1.0),'torso'),('arm_r',(.27,0,1.45),(.27,0,1.0),'torso'),('leg_l',(-.14,0,.9),(-.14,0,.12),'root'),('leg_r',(.14,0,.9),(.14,0,.12),'root')]
 col,rig=newrig(name,bones);a=ACC[v]
 piece(col,rig,'armored_torso',(0,0,1.28),(.47,.28,.57),a,'torso',.07)
 piece(col,rig,'vest',(0,.16,1.3),(.32,.07,.37),INK,'torso',.02)
 piece(col,rig,'belt',(0,0,.94),(.45,.29,.09),STEEL,'root')
 piece(col,rig,'neck',(0,0,1.59),(.15,.15,.13),SKIN,'head')
 piece(col,rig,'head',(0,0,1.75),(.29,.25,.3),IVORY if v==0 else SKIN,'head',.065)
 piece(col,rig,'visor',(0,.135,1.78),(.27,.035,.08),a,'head',.015)
 for side,bone in [(-1,'arm_l'),(1,'arm_r')]:
  piece(col,rig,'shoulder',(.32*side,0,1.47),(.21,.28,.2),IVORY if v==0 else INK,bone,.04)
  piece(col,rig,'forearm',(.34*side,.015,1.17),(.15,.2,.38),a,bone,.03)
  piece(col,rig,'hand',(.34*side,.03,.96),(.14,.17,.15),INK,bone,.025)
 for side,bone in [(-1,'leg_l'),(1,'leg_r')]:
  piece(col,rig,'thigh',(.14*side,0,.69),(.19,.24,.4),INK,bone,.035)
  piece(col,rig,'greave',(.14*side,.015,.34),(.18,.24,.35),a,bone,.03)
  piece(col,rig,'boot',(.14*side,.06,.1),(.21,.36,.16),STEEL,bone,.025)
 if v==0:
  piece(col,rig,'scarf',(.05,-.16,1.28),(.34,.08,.55),IVORY,'torso')
 elif v==1:
  piece(col,rig,'crest',(0,0,1.94),(.08,.31,.16),ACC[1],'head')
  piece(col,rig,'backpack',(0,-.22,1.3),(.33,.18,.4),STEEL,'torso')
 else:
  for x in [-.29,.29]:piece(col,rig,'mantle',(x,-.1,1.35),(.18,.2,.57),ACC[2],'torso')
 actions(rig,'hero',v);return col,rig
all_assets=[weapon(n,i) for i,n in enumerate(['Kestrel','Wisp','Longbow'])]+[hero(n,i)for i,n in enumerate(['Serein','Rook','Vesper'])]
for col,rig in all_assets:
 bpy.ops.object.select_all(action='DESELECT')
 for o in col.objects:o.select_set(True)
 bpy.context.view_layer.objects.active=rig
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,col.name+'.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_frame_range=False)
 bpy.ops.object.select_all(action='DESELECT')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.dirname(__file__),'Aurora_Source.blend'))
print('AURORA_ASSETS_OK',len(all_assets))
