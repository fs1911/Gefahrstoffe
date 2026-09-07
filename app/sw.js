/* StoffScan Service Worker – network-first (immer frisch), Cache nur Offline-Fallback */
var CACHE='stoffscan-v3';
var SHELL=['./','./index.html','./manifest.webmanifest','./icon.svg'];
self.addEventListener('install',function(e){
  e.waitUntil(caches.open(CACHE).then(function(c){return c.addAll(SHELL).catch(function(){});}).then(function(){return self.skipWaiting();}));
});
self.addEventListener('activate',function(e){
  e.waitUntil(caches.keys().then(function(keys){return Promise.all(keys.map(function(k){if(k!==CACHE)return caches.delete(k);}));}).then(function(){return self.clients.claim();}));
});
self.addEventListener('fetch',function(e){
  var req=e.request;if(req.method!=='GET')return;
  var url;try{url=new URL(req.url);}catch(_){return;}
  // Supabase API/Auth nie cachen
  if(/\.supabase\./.test(url.hostname))return;
  // Network-first fuer ALLES: online immer die frische Version, Cache nur wenn offline.
  e.respondWith(
    fetch(req).then(function(res){
      if(res&&(res.ok||res.type==='opaque')){var cp=res.clone();caches.open(CACHE).then(function(c){c.put(req.mode==='navigate'?'./index.html':req,cp);});}
      return res;
    }).catch(function(){
      return caches.match(req).then(function(m){return m||(req.mode==='navigate'?caches.match('./index.html').then(function(x){return x||caches.match('./');}):undefined);});
    })
  );
});
