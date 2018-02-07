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

function log_fallback(input, msg) {
    console.log("Unknow message", msg)
}

function install(app) {
    app.ports.output.subscribe(function (msg) {
        command_processor(app.ports.input, msg, log_fallback);
    })
}

function install_with_fallback(app, fallback) {
    app.ports.output.subscribe(function (msg) {
        command_processor(app.ports.input, msg, fallback);
    })
}

exports.install = install 
exports.install_with_fallback = install_with_fallback 

