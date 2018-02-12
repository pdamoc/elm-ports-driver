'use strict';

function readFile(method, input, payload) {

  console.log("payload", payload.fileRef)
  var reader = new FileReader();

  reader.onload = (function(event) {
     
    var return_payload = {
      id: payload.id,
      contents: event.target.result,
      filename: payload.fileRef.name
    };
    input.send(toMsg("FileR" + method.slice(1), return_payload));
  });

  reader[method](payload.fileRef);
}

function toMsg(tag, payload) {
    return {"tag" : tag, "payload":payload}
}
 

function merge(obj1, obj2) {
  for (var attrname in obj2) { obj1[attrname] = obj2[attrname]; }
  return obj1
}

function install(output, input, plugins) { 
    var processor = plugins.reduce(function(accumulator, currentValue){ 
      return merge(accumulator, currentValue)}, {})

    output.subscribe(function (msg) {
        var plugin = processor[msg.tag]
        if (plugin === undefined){
          console.log("Unknow message (Maybe you forgot to add a plugin to the plugin list): ", msg);
        }
        else {
          plugin(input, msg.payload);
        }
    })
    var plugin, keys, key;
    for (plugin in plugins) { 
      keys = Object.keys(plugins[plugin])        
      for (key in keys){
        if (keys[key].indexOf("Install") == 0){
          plugins[plugin][keys[key]](input);
        }
      }
    }
}

// PLUGINS 

function file_reader(method) {
  return function(input, payload) {
    readFile(method, input, payload) 
  }
}


function updateCss(input, payload) {
  var elm_driver_css = document.getElementById('elm-ports-driver-css')
  if (elm_driver_css == null) {
      elm_driver_css = document.createElement('style');
      elm_driver_css.type = 'text/css';
      elm_driver_css.id = 'elm-ports-driver-css'
      document.getElementsByTagName('head')[0].appendChild(elm_driver_css);
  }

  elm_driver_css.textContent = payload;
}

function local_storage_get_item(input, payload) {
  var return_payload = 
    { 'key': payload, 'value': localStorage.getItem(payload)}

  input.send(toMsg("LocalStorageGetItem", return_payload));
}

function local_storage_set_item(input, payload) {
   localStorage.setItem(payload.key, payload.value);
}
function local_storage_remove_item(input, payload) {
   localStorage.removeItem(payload);
}

function local_storage_listener(input) {
  window.addEventListener('storage', function(e) { 
    input.send(toMsg("LocalStorageChange", { 'key': e.key, 'value':e.newValue}));
  });
}

exports.install = install;
exports.toMsg = toMsg;
exports.log = { "Log": function(input, payload){ console.log(payload) }};
exports.set_title = { "SetTitle": function(input, payload){ document.title = payload }};
exports.update_css = { "UpdateCss": updateCss };
exports.file_reader = 
  { "FileReadAsDataURL": file_reader("readAsDataURL")
  , "FileReadAsTextFile": file_reader("readAsTextFile")
  };

exports.local_storage = 
  { "LocalStorageGetItem" : local_storage_get_item
  , "LocalStorageSetItem" : local_storage_set_item 
  , "LocalStorageRemoveItem" : local_storage_remove_item 
  };

exports.local_storage_listener = 
  { "InstallLocalStorageListner" : local_storage_listener
  };
