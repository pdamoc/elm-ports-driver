// pull in desired CSS/SASS files
require( './styles/main.scss' );

var elm_ports_driver = require( 'elm-ports-driver' ); // the actual driver

var Elm = require( '../../src/Main' );

var app = Elm.Main.fullscreen();

var custom = 
    {"MyLog": function(input, payload) { console.log("MyLog:", payload)}
    }

elm_ports_driver.install(app,
     [ elm_ports_driver.file_reader
     , elm_ports_driver.log
     , elm_ports_driver.set_title
     , elm_ports_driver.update_css
     , custom
     ]
     );