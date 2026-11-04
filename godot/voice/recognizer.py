"""VoxMateria local speech worker. PCM stays in memory; only status/text cross the IPC boundary."""
import argparse,json,os,queue,sys,time,threading,math
from pathlib import Path

def main():
 p=argparse.ArgumentParser();p.add_argument('--session');p.add_argument('--model');p.add_argument('--self-test',action='store_true');args=p.parse_args()
 import vosk,sounddevice as sd
 if args.self_test:
  print(json.dumps({'vosk':True,'devices':len(sd.query_devices())}));return
 vosk.SetLogLevel(-1);folder=Path(args.session);folder.mkdir(parents=True,exist_ok=True)
 status={'state':'loading','level':0,'text':'','partial':'','error':'','seq':0,'devices':[]}
 def publish():
  tmp=folder/'status.tmp';tmp.write_text(json.dumps(status,ensure_ascii=False),encoding='utf-8');
  try:os.replace(tmp,folder/'status.json')
  except PermissionError:pass
 try:
  status['devices']=[{'id':i,'name':d['name']}for i,d in enumerate(sd.query_devices())if d['max_input_channels']>0]
  publish()
  if not args.model or not Path(args.model).is_dir():raise RuntimeError('Modelo offline ausente. Execute instalar-modelo.ps1 ou selecione uma pasta Vosk portuguesa.')
  model=vosk.Model(args.model);status['state']='ready';publish()
 except Exception as exc:
  status.update(state='error',error=str(exc));publish();return
 samples=queue.Queue(maxsize=90);stream=None;recognizer=None;rate=16000;last_command=-1;listening=False;last_voice=0;began=0;last_status=0;segments=[];resample_state=None
 def callback(indata,frames,timing,flags):
  try:samples.put_nowait(bytes(indata))
  except queue.Full:pass
 def stop(cancel=False):
  nonlocal stream,listening
  if stream:
   stream.stop();stream.close();stream=None
  listening=False
  text='' if cancel or recognizer is None else ' '.join(segments+[json.loads(recognizer.FinalResult()).get('text','')]).strip()
  status.update(state='ready',text=text,partial='',level=0);publish()
 while True:
  try:
   command_file=folder/'command.json'
   if command_file.exists():
    cmd=json.loads(command_file.read_text(encoding='utf-8'))
    if cmd.get('seq')!=last_command:
     last_command=cmd.get('seq');status['seq']=last_command
     action=cmd.get('action')
     if action=='shutdown':stop(True);return
     if action in ('stop','cancel'):stop(action=='cancel')
     if action=='start':
      if listening:stop(True)
      while not samples.empty():samples.get_nowait()
      device=cmd.get('device',-1);device=None if device<0 else device
      segments=[];resample_state=None
      info=sd.query_devices(device,'input');rate=int(info['default_samplerate']);recognizer=vosk.KaldiRecognizer(model,16000)
      # Resampling uses the standard-library audioop implementation in Python 3.11.
      import audioop
      stream=sd.RawInputStream(samplerate=rate,channels=1,dtype='int16',device=device,blocksize=max(400,rate//20),callback=callback)
      stream.start();listening=True;began=last_voice=time.monotonic();status.update(state='listening',text='',partial='',error='');publish()
   if listening:
    try:
     chunk=samples.get(timeout=.02)
     import audioop
     level=audioop.rms(chunk,2)/32768;status['level']=min(1,level*8)
     if level>.008:last_voice=time.monotonic()
     if level<.003:chunk=b'\0'*len(chunk)
     if rate!=16000:chunk,resample_state=audioop.ratecv(chunk,2,1,rate,16000,resample_state)
     
     if recognizer.AcceptWaveform(chunk):segments.append(json.loads(recognizer.Result()).get('text',''))
     status['partial']=json.loads(recognizer.PartialResult()).get('partial','')
    except queue.Empty:pass
    now=time.monotonic()
    if now-began>20 or (now-last_voice>3 and now-began>3):stop()
   if time.monotonic()-last_status>.12:publish();last_status=time.monotonic()
  except Exception as exc:
   if stream:
    try:stream.stop();stream.close()
    except Exception:pass
   stream=None;listening=False;status.update(state='error',error=str(exc),level=0);publish()
  time.sleep(.02)
if __name__=='__main__':main()
