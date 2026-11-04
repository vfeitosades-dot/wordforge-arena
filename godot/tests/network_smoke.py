import os,subprocess,time,sys,tempfile
from pathlib import Path
exe=sys.argv[1] if len(sys.argv)>1 else 'godot'
project=Path(__file__).resolve().parents[1]
logs=project/'test-results';logs.mkdir(exist_ok=True)
processes=[]
def launch(role):
 f=(logs/(role+'.log')).open('w',encoding='utf-8')
 p=subprocess.Popen([exe,'--headless','--path',str(project),'--script','res://tests/network_actor.gd','--',role],stdout=f,stderr=subprocess.STDOUT)
 processes.append((p,f));return p
try:
 host=launch('host');deadline=time.monotonic()+15
 while time.monotonic()<deadline:
  if 'HOST_READY' in (logs/'host.log').read_text(encoding='utf-8',errors='replace'):break
  if host.poll() is not None:raise RuntimeError('Host failed: '+(logs/'host.log').read_text())
  time.sleep(.1)
 else:raise RuntimeError('Host startup timeout')
 a=launch('client-a');a.wait(timeout=20)
 if a.returncode:raise RuntimeError((logs/'client-a.log').read_text())
 b=launch('client-b');b.wait(timeout=20)
 if b.returncode:raise RuntimeError((logs/'client-b.log').read_text())
 print('ENET_NETWORK_OK: authoritative cost, creation replication, late join terrain and entities; 2 client sessions')
finally:
 for p,f in processes:
  if p.poll() is None:p.terminate()
  f.close()
