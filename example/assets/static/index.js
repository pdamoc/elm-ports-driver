// pull in desired CSS/SASS files
require( './styles/main.scss' );

var elm_ports_driver = require( '../../..' ); // the actual driver

var Elm = require( '../../src/Main' );

var app = Elm.Main.fullscreen();

// custom plugin for the elm_ports_driver. 
var custom = 
    { "MyLog": function(input, payload) { console.log("MyLog: ", payload)}
    }

// installing custom event listners 
window.onresize = function(event) {
    app.ports.input.send(elm_ports_driver.toMsg("WindowResize", 
        {"width": window.innerWidth , "height": window.innerHeight}))
}

elm_ports_driver.install(app.ports.output, app.ports.input,
     [ elm_ports_driver.file_reader
     , elm_ports_driver.log
     , elm_ports_driver.set_title
     , elm_ports_driver.update_css
     , elm_ports_driver.local_storage
     , elm_ports_driver.local_storage_listener
     , custom
     ]
     );