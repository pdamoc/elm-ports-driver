port module Ports exposing (..)

import Json.Decode exposing (Value)


port output : Value -> Cmd msg


port input : (Value -> msg) -> Sub msg
