const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('forgeDesktop',{listen:()=>ipcRenderer.invoke('speech'),hostInfo:()=>ipcRenderer.invoke('host-info')});
