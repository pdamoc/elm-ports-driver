module PortsDriver
    exposing
        ( -- Types
          Config
        , ID
          -- Commands
        , log
        , setTitle
        , updateCss
        , readAsText
        , readAsDataURL
        , send
          -- Subscriptions
        , inputDecoder
        , receiveFileAsText
        , receiveFileAsDataURL
        , subscriptions
          -- Event Helper
        , onFileChange
        )

{-| This is an Elm package - npm package combo designed to be used to simplify
some of the ports code usage.


# Types

@docs Config, ID


# Html.Event Helper

@docs onFileChange


# Commands without reply

These are the commands that will not produce a reply.

@docs log, setTitle, updateCss, send


# Commands with reply

These are the commands that will cause a reply to be sent back to Elm.

@docs readAsText, readAsDataURL


# Subscriptions

Decoders for the subscriptions.

@docs inputDecoder, receiveFileAsText, receiveFileAsDataURL, subscriptions

-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Html.Events exposing (on)
import Html exposing (Attribute)


-- TYPES


{-| The `Config` record contains the output port, the input port a function handle
unknown input port messages. This record is needed for all the functions.
-}
type alias Config msg =
    { output : Value -> Cmd msg
    , input : (Value -> msg) -> Sub msg
    , fail : String -> msg
    }


{-| An alias to make the type signatures more explicit
-}
type alias ID =
    String


encodeMsg : String -> Value -> Config msg -> Cmd msg
encodeMsg tag payload config =
    Encode.object
        [ ( "tag", Encode.string tag )
        , ( "payload", payload )
        ]
        |> config.output


{-| Logs the provided `String` to the Console.
-}
log : Config msg -> String -> Cmd msg
log config text =
    encodeMsg "Log" (Encode.string text) config


{-| Generic function for sending messages to JavaScript.
-}
send : Config msg -> String -> Value -> Cmd msg
send config tag value =
    encodeMsg tag value config


{-| Sets the provided `String` as the title of the page.
-}
setTitle : Config msg -> String -> Cmd msg
setTitle config title =
    encodeMsg "SetTitle" (Encode.string title) config


{-| Updates the head node with a style node containing the value provided as a
`String`.
-}
updateCss : Config msg -> String -> Cmd msg
updateCss config css =
    encodeMsg "UpdateCss" (Encode.string css) config


{-| sends a read command for the node with the provided ID. The contents are
read as text.
-}
readAsText : Config msg -> ID -> Cmd msg
readAsText config id =
    encodeMsg "FileReadAsText" (Encode.string id) config


{-| sends a read command for the node with the provided ID. The contents are
read as a dataURL.
-}
readAsDataURL : Config msg -> ID -> Cmd msg
readAsDataURL config id =
    encodeMsg "FileReadAsDataURL" (Encode.string id) config



-- SUBSCRIPTIONS


{-| The main subscription. Receives a list of decoders for the messages received
from the input port.
-}
subscriptions : Config msg -> List (Decoder msg) -> Sub msg
subscriptions config decoders =
    let
        inputDecoder json =
            case Decode.decodeValue (Decode.oneOf decoders) json of
                Ok msg ->
                    msg

                Err err ->
                    config.fail err
    in
        config.input inputDecoder



-- DECODERS


tagDecoder : String -> Decoder String
tagDecoder expected =
    Decode.field "tag" Decode.string
        |> Decode.andThen
            (\inputTag ->
                if inputTag == expected then
                    Decode.succeed expected
                else
                    Decode.fail ""
            )


{-| Generic input decoder. Receives the tag of the message and a decoder for the
payload of the message. Returns a decoder that can be used with `subscriptions`.
-}
inputDecoder : String -> Decoder msg -> Decoder msg
inputDecoder tag payloadDecoder =
    Decode.map2 always payloadDecoder (tagDecoder tag)


fileDecoder : String -> (ID -> String -> String -> msg) -> Decoder msg
fileDecoder method toMsg =
    let
        actualDecoder =
            Decode.map3 toMsg
                (Decode.field "id" Decode.string)
                (Decode.field "filename" Decode.string)
                (Decode.field "contents" Decode.string)
                |> Decode.field "payload"
    in
        inputDecoder method actualDecoder


{-| Decoder for the file reader `readAsText` command replay. The message creator
receives the `ID` of the input node, the `filename` and the contents of the file
as a `String`.
-}
receiveFileAsText : (ID -> String -> String -> msg) -> Decoder msg
receiveFileAsText toMsg =
    fileDecoder "FileReadAsText" toMsg


{-| Decoder for the file reader `readAsDataURL` command replay. The message creator
receives the `ID` of the input node, the `filename` and the contents of the file
as a `String`.
-}
receiveFileAsDataURL : (ID -> String -> String -> msg) -> Decoder msg
receiveFileAsDataURL toMsg =
    fileDecoder "FileReadAsDataURL" toMsg



-- EVENT HELPERS


{-| A helper for the FileReader part of the driver.
-}
onFileChange : msg -> Attribute msg
onFileChange msg =
    on "change"
        (Decode.succeed msg)
