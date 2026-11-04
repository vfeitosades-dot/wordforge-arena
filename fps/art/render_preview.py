import bpy,os,math
from mathutils import Vector
base=os.path.dirname(__file__);bpy.ops.wm.open_mainfile(filepath=base+'/Aurora_Source.blend')
for o in bpy.context.scene.objects:
 o.hide_render=True
for i,name in enumerate(['Serein','Rook','Vesper','Lumen']):
 col=bpy.data.collections[name]
 rig=next(o for o in col.objects if o.type=='ARMATURE');rig.location.x=(i-1.5)*1.15
 for track in rig.animation_data.nla_tracks:track.mute=True
 for o in col.objects:o.hide_render=False
# Ground and studio lighting; these are the actual Blender source characters.
bpy.ops.mesh.primitive_plane_add(size=200);floor=bpy.context.object;floor.location.z=-.02;m=bpy.data.materials.new('studio_floor');m.diffuse_color=(.025,.055,.075,1);floor.data.materials.append(m)
bpy.ops.object.camera_add(location=(4,7,3.4));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=6.2
for pos,energy,color,size in [((1,3,6),1400,(.72,.88,1),5),((-4,1,3),900,(.3,1,.8),4),((1,-3,4),1600,(1,.65,.4),3)]:
 bpy.ops.object.light_add(type='AREA',location=pos);l=bpy.context.object;l.data.energy=energy;l.data.color=color;l.data.shape='DISK';l.data.size=size;l.rotation_euler=(Vector((0,0,1))-l.location).to_track_quat('-Z','Y').to_euler()
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=48;s.cycles.use_denoising=False;s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100;s.world.color=(.1,.1,.1);s.render.filepath=os.path.join(base,'characters-preview.png');bpy.ops.render.render(write_still=True)
