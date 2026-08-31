/* StoffScan Service Worker (Block 14) – App-Shell-Cache fuer Offline */
var CACHE='stoffscan-v1';
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
  if(/supabase\.co$/.test(url.hostname)||/\.supabase\./.test(url.hostname))return;
  if(req.mode==='navigate'){
    e.respondWith(fetch(req).then(function(res){var cp=res.clone();caches.open(CACHE).then(function(c){c.put('./index.html',cp);});return res;}).catch(function(){return caches.match('./index.html').then(function(m){return m||caches.match('./');});}));
    return;
  }
  e.respondWith(caches.match(req).then(function(hit){
    if(hit)return hit;
    return fetch(req).then(function(res){
      if(res&&(res.ok||res.type==='opaque')){var cp=res.clone();caches.open(CACHE).then(function(c){c.put(req,cp);});}
      return res;
    }).catch(function(){return hit;});
  }));
});
