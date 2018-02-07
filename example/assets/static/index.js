// pull in desired CSS/SASS files
require( './styles/main.scss' );

var elm_ports_driver = require( '../../..' ); // the actual driver

var Elm = require( '../../src/Main' );

var app = Elm.Main.fullscreen();


elm_ports_driver.install(app);