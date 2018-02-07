module PortsDriver exposing (Driver, Config, Msg(..), Contents(..), install, onFileChange)

{-| This is an Elm package - npm package combo designed to be used to simplify
some of the ports code usage.


# Types

@docs Driver, Msg, Contents


# Html.Event Helper

@docs onFileChange


# Main function

@docs Config, install

-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Html.Events exposing (on)
import Html exposing (Attribute)


-- TYPES


{-| A union type holding the contents of the file read by the browser.
Contents read with `readAsText` and `readAsDataURL` will be received as `TextFile String`.
-}
type Contents
    = TextFile String


{-| The types of messages received from the driver. `File id filename contents`
-}
type Msg
    = File String String Contents


type alias FileOps msg =
    { readAsText : String -> Cmd msg
    , readAsDataURL : String -> Cmd msg
    }


{-| A record with links to the functions that can be used to generate commands
for the driver and a subscription for the replies from the driver.
-}
type alias Driver msg =
    { log : String -> Cmd msg
    , setTitle : String -> Cmd msg
    , updateCss : String -> Cmd msg
    , file : FileOps msg
    , subscriptions : Sub msg
    }



-- EVENT HELPERS


{-| A helper for the FileReader part of the driver.
-}
onFileChange : msg -> Attribute msg
onFileChange msg =
    on "change"
        (Decode.succeed msg)



-- PRIVATE HELPERS


toMsg : ( String, Value ) -> Decoder Msg
toMsg ( tag, payload ) =
    let
        decodeFile toContents contentsDecoder =
            let
                actualDecoder =
                    Decode.map3 File
                        (Decode.field "id" Decode.string)
                        (Decode.field "filename" Decode.string)
                        (Decode.map toContents (Decode.field "contents" contentsDecoder))
            in
                case Decode.decodeValue actualDecoder payload of
                    Ok msg ->
                        Decode.succeed msg

                    Err error ->
                        Decode.fail error
    in
        case tag of
            "FileReadAsDataURL" ->
                decodeFile TextFile Decode.string

            "FileReadAsText" ->
                decodeFile TextFile Decode.string

            _ ->
                Decode.fail <| "unknown tag: " ++ tag


inputDecoder : Decoder Msg
inputDecoder =
    Decode.map2 (,) (Decode.field "tag" Decode.string) (Decode.field "payload" Decode.value)
        |> Decode.andThen toMsg


decodeMsg : (String -> msg) -> (Msg -> msg) -> Value -> msg
decodeMsg fail lift json =
    case Decode.decodeValue inputDecoder json of
        Ok msg ->
            lift msg

        Err error ->
            fail error



-- PUBLIC API


{-| The `Config` record contains the output port, the input port a function to generate an error
in case of port error and a function to lift the type of messages that can arrive from the driver to
the Main Msg type.
-}
type alias Config msg =
    { output : Value -> Cmd msg
    , input : (Value -> msg) -> Sub msg
    , fail : String -> msg
    , lift : Msg -> msg
    }


{-| A function that will create the driver record.
-}
install : Config msg -> Driver msg
install { output, input, fail, lift } =
    let
        encodeMsg tag payload =
            Encode.object
                [ ( "tag", Encode.string tag )
                , ( "payload", payload )
                ]
                |> output
    in
        { log = \text -> encodeMsg "Log" (Encode.string text)
        , setTitle = \title -> encodeMsg "SetTitle" (Encode.string title)
        , updateCss = \css -> encodeMsg "UpdateCss" (Encode.string css)
        , file =
            { readAsText = \id -> encodeMsg "FileReadAsText" (Encode.string id)
            , readAsDataURL = \id -> encodeMsg "FileReadAsDataURL" (Encode.string id)
            }
        , subscriptions = input (decodeMsg fail lift)
        }
