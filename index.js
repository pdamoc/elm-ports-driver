'use strict';

function command_processor(input, msg, fallback) {
    
    switch(msg.tag) {
        case "Log":
            console.log(msg.payload)
            break; 

        case "SetTitle":
            document.title = msg.payload
            break; 

        case "UpdateCss":
            var elm_driver_css = document.getElementById('elm-ports-driver-css')
            if (elm_driver_css == null) {
                elm_driver_css = document.createElement('style');
                elm_driver_css.type = 'text/css';
                elm_driver_css.id = 'elm-ports-driver-css'
                document.getElementsByTagName('head')[0].appendChild(elm_driver_css);
            }
      
            elm_driver_css.textContent = msg.payload;

            break; 

        case "FileReadAsDataURL":
            readFile("readAsDataURL", input, msg.payload)
            break;

        case "FileReadAsTextFile":
            readFile("readAsTextFile", input, msg.payload)
            break;

        case "FileReadAsArrayBuffer":
            readFile("readAsArrayBuffer", input, msg.payload)
            break;

        default:
            fallback(input, msg)
    }


}

function readFile(method, input, id) {
  var node = document.getElementById(id);
  if (node === null) {
    console.log("Could not find node with ID: ", id);
    return;
  }

  // If your file upload field allows multiple files, you might
  // want to consider turning this into a `for` loop.
  var file = node.files[0];
  var reader = new FileReader();

  // FileReader API is event based. Once a file is selected
  // it fires events. We hook into the `onload` event for our reader.
  reader.onload = (function(event) {
    // The event carries the `target`. The `target` is the file
    // that was selected. The result is base64 encoded contents of the file.
     
    var payload = {
      id: id,
      contents: event.target.result,
      filename: file.name
    };

    // We call the `fileContentRead` port with the file data
    // which will be sent to our Elm runtime via Subscriptions.
    input.send(toMsg("FileR" + method.slice(1), payload));
  });

  // Connect our FileReader with the file that was selected in our `input` node.
  reader[method](file);
}

function toMsg(tag, payload) {
    return {"tag" : tag, "payload":payload}
}
 

function merge(obj1, obj2) {
  for (var attrname in obj2) { obj1[attrname] = obj2[attrname]; }
  return obj1
}

function install(app, plugins) { 
  var processor = plugins.reduce(function(accumulator, currentValue){ 
    return merge(accumulator, currentValue)}, {})
    app.ports.output.subscribe(function (msg) {
        var plugin = processor[msg.tag]
        if (plugin === undefined){
          console.log("Unknow message", msg);
        }
        else {
          plugin(app.ports.input, msg.payload);
        }
    })
}

// PLUGINS 

function file_reader(method) {
  return function(input, id) {
    readFile(method, input, id) 
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

exports.install = install;
exports.log = { "Log": function(input, payload){ console.log(payload) }};
exports.set_title = { "SetTitle": function(input, payload){ document.title = payload }};
exports.update_css = { "UpdateCss": updateCss };
exports.file_reader = 
  { "FileReadAsDataURL": file_reader("readAsDataURL")
  , "FileReadAsTextFile": file_reader("readAsTextFile")
  };

