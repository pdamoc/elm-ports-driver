# Elm Ports Driver

A combo of JavaScript code and Elm code to automate some of the JavaScript interop

# Installation 

- add `elm-ports-driver` as a dependency `npm install elm-ports-driver --save` 

- install the `elm-ports-driver` elm package `elm-package install pdamoc/elm-ports-driver`

inside your Elm's project `index.js` (the app's entrypoint) use something like :

``` 

var elm_ports_driver = require( 'elm-ports-driver' ); // the actual driver

var Elm = require( '../../src/Main' );

var app = Elm.Main.fullscreen();

// custom plugin for the elm_ports_driver. 
var custom = 
    { "MyLog": function(input, payload) { console.log("MyLog: ", payload)}
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
```

You can use only the plugins you need. 


Inside your Main Elm file create a configuration record that holds your app's input and output ports as well as a message generator for the messages that are unrecognized. If you receive messages from JavaScript make sure you subscrible using the provided decoders. 

```

config : Config Msg
config =
    { output = Ports.output
    , input = Ports.input
    , fail = Fail
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    PortsDriver.subscriptions config
        [ PortsDriver.receiveFileAsDataURL ReceiveFile
        , PortsDriver.receiveLocalStorageItem ReceiveStorageItem
        , PortsDriver.receiveLocalStorageChange ReceiveStorageItem

        -- handler for the custom event listener installed in JS
        , PortsDriver.inputDecoder "WindowResize" (Decode.map Resize windowResizeDecoder)
        ]
```


Please see the `example` folder for a full example. (Inside the `example` folder run `npm start`)
