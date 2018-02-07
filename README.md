# Elm Ports Driver

A combo of JavaScript code and Elm code to automate some of the JavaScript interop

# Installation 

- add `elm-ports-driver` as a dependency `npm install elm-ports-driver --save` 

- install the `elm-ports-driver` elm package `elm-package install pdamoc/elm-ports-driver`

inside your Elm's project `index.js` use something like :

``` 

var elm_ports_driver = require( 'elm-ports-driver' ); // the actual driver

var Elm = require( '../../src/Main' );

var app = Elm.Main.fullscreen();


elm_ports_driver.install(app);
```


inside your Main Elm file install the driver: 

```
import PortsDriver exposing (Driver)


driver : Driver Msg
driver =
    PortsDriver.install
        { output = Ports.output
        , input = Ports.input
        , lift = PortsMsg -- Message that lifts the PortsDriver.Msg to the app's Msg
        , fail = Fail -- Message that will be called if unrecognized data comes through the port
        }

```

Please see the `example` folder for a full example. 

