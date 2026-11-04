package com.wordforge.arena;
import android.app.Activity;
import android.os.Bundle;
import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.speech.RecognizerIntent;
import android.webkit.*;
import android.view.View;
import org.json.JSONObject;
import java.util.ArrayList;
public class MainActivity extends Activity {
 private WebView web;
 @Override public void onCreate(Bundle state){super.onCreate(state);getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);web=new WebView(this);setContentView(web);WebSettings s=web.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setAllowFileAccess(true);s.setAllowUniversalAccessFromFileURLs(true);s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);s.setMediaPlaybackRequiresUserGesture(false);web.setBackgroundColor(0xff0e1520);web.addJavascriptInterface(new VoiceBridge(),"AndroidVoice");web.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return !r.getUrl().toString().startsWith("file:///android_asset/");}});web.loadUrl("file:///android_asset/index.html");}
 public class VoiceBridge {@JavascriptInterface public void listen(){runOnUiThread(new Runnable(){public void run(){if(checkSelfPermission(Manifest.permission.RECORD_AUDIO)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO},9);else startSpeech();}});}}
 private void startSpeech(){try{Intent i=new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);i.putExtra(RecognizerIntent.EXTRA_LANGUAGE,"pt-BR");i.putExtra(RecognizerIntent.EXTRA_PROMPT,"Descreva o que deseja criar");i.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS,1);startActivityForResult(i,8);}catch(Exception e){reply("","Reconhecimento de voz indisponível. Instale um serviço de fala ou digite a palavra.");}}
 private void reply(String text,String error){web.evaluateJavascript("window.onNativeSpeech("+JSONObject.quote(text)+","+JSONObject.quote(error)+")",null);}
 @Override public void onRequestPermissionsResult(int code,String[] permissions,int[] grants){super.onRequestPermissionsResult(code,permissions,grants);if(code==9){if(grants.length>0&&grants[0]==PackageManager.PERMISSION_GRANTED)startSpeech();else reply("","Permita o microfone nas configurações do app ou digite a palavra.");}}
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==8){if(result==RESULT_OK&&data!=null){ArrayList<String> words=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);reply(words!=null&&!words.isEmpty()?words.get(0):"","");}else reply("","Voz cancelada. Tente novamente ou digite.");}}
 @Override protected void onPause(){super.onPause();web.evaluateJavascript("window.dispatchEvent(new Event('blur'))",null);web.onPause();}
 @Override protected void onResume(){super.onResume();if(web!=null)web.onResume();}
 @Override public void onBackPressed(){web.evaluateJavascript("document.querySelector('#exit').click()",null);}
 @Override protected void onDestroy(){web.destroy();super.onDestroy();}
}
