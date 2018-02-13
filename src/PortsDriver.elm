module PortsDriver
    exposing
        ( -- Types
          Config
        , ID
        , FileRef
        , FileData
          -- Commands
        , log
        , setTitle
        , updateCss
        , readAsText
        , readAsDataURL
        , send
        , localStorageGetItem
        , localStorageSetItem
        , localStorageRemoveItem
          -- Subscriptions
        , inputDecoder
        , receiveFileAsText
        , receiveFileAsDataURL
        , receiveLocalStorageItem
        , receiveLocalStorageChange
        , subscriptions
          -- Event Helper
        , onFile
        )

{-| This is an Elm package - npm package combo designed to be used to simplify
some of the ports code usage.


# Types

@docs Config, ID, FileRef, FileData


# Html.Event Helper

@docs onFile


# FileReader API

These are the commands that will cause a reply to be sent back to Elm.

@docs readAsText, readAsDataURL
@docs receiveFileAsText, receiveFileAsDataURL


# LocalStorage API

These are the commands that will cause a reply to be sent back to Elm.

@docs localStorageGetItem, localStorageSetItem, localStorageRemoveItem
@docs receiveLocalStorageItem, receiveLocalStorageChange


# Other Commands

These are the commands that will not produce a reply.

@docs log, setTitle, updateCss, send


# Subscriptions

Decoders for the subscriptions.

@docs inputDecoder, subscriptions

-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Html.Events exposing (on, onWithOptions)
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


{-| An alias to make the type signatures more explicit
-}
type alias FileRef =
    Value


{-| An alias to make the type signatures more explicit
-}
type alias FileData =
    { id : ID
    , filename : String
    , contents : String
    }


encodeMsg : String -> Value -> Config msg -> Cmd msg
encodeMsg tag payload config =
    Encode.object
        [ ( "tag", Encode.string tag )
        , ( "payload", payload )
        ]
        |> config.output



-- COMMANDS


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


encodeFileRef : ID -> FileRef -> Value
encodeFileRef id fileRef =
    Encode.object
        [ ( "id", Encode.string id )
        , ( "fileRef", fileRef )
        ]


{-| sends a read command for the node with the provided ID. The contents are
read as text.
-}
readAsText : Config msg -> ID -> FileRef -> Cmd msg
readAsText config id fileRef =
    encodeMsg "FileReadAsText" (encodeFileRef id fileRef) config


{-| sends a read command for the node with the provided ID. The contents are
read as a dataURL.
-}
readAsDataURL : Config msg -> ID -> FileRef -> Cmd msg
readAsDataURL config id fileRef =
    encodeMsg "FileReadAsDataURL" (encodeFileRef id fileRef) config


{-| Sets the `localStorage` key to this value.
-}
localStorageSetItem : Config msg -> String -> String -> Cmd msg
localStorageSetItem config key value =
    let
        payload =
            Encode.object
                [ ( "key", Encode.string key )
                , ( "value", Encode.string value )
                ]
    in
        encodeMsg "LocalStorageSetItem" payload config


{-| Removes the `localStorage` key.
-}
localStorageRemoveItem : Config msg -> String -> Cmd msg
localStorageRemoveItem config key =
    encodeMsg "LocalStorageRemoveItem" (Encode.string key) config


{-| Requests the value for the provided `key`. The value will arrive through the
`receiveLocalStorageItem` subscription decoder.
-}
localStorageGetItem : Config msg -> String -> Cmd msg
localStorageGetItem config key =
    encodeMsg "LocalStorageGetItem" (Encode.string key) config



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
                    config.fail ("unknown message:" ++ toString json)
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
    Decode.map2 always (Decode.field "payload" payloadDecoder) (tagDecoder tag)


fileMsgDecoder : String -> (FileData -> msg) -> Decoder msg
fileMsgDecoder method toMsg =
    let
        actualDecoder =
            Decode.map3 FileData
                (Decode.field "id" Decode.string)
                (Decode.field "filename" Decode.string)
                (Decode.field "contents" Decode.string)
                |> Decode.map toMsg
    in
        inputDecoder method actualDecoder


{-| Decoder for the file reader `readAsText` command replay. The message creator
receives the `ID` of the input node, the `filename` and the contents of the file
as a `String`.
-}
receiveFileAsText : (FileData -> msg) -> Decoder msg
receiveFileAsText toMsg =
    fileMsgDecoder "FileReadAsText" toMsg


{-| Decoder for the file reader `readAsDataURL` command replay. The message creator
receives the `ID` of the input node, the `filename` and the contents of the file
as a `String`.
-}
receiveFileAsDataURL : (FileData -> msg) -> Decoder msg
receiveFileAsDataURL toMsg =
    fileMsgDecoder "FileReadAsDataURL" toMsg


{-| Decoder for the localStorage message after `localStorageGetItem`
-}
receiveLocalStorageItem : (String -> Maybe String -> msg) -> Decoder msg
receiveLocalStorageItem toMsg =
    let
        actualDecoder =
            Decode.map2 toMsg
                (Decode.field "key" Decode.string)
                (Decode.field "value" (Decode.maybe Decode.string))
    in
        inputDecoder "LocalStorageGetItem" actualDecoder


{-| Decoder for the localStorage message received from listening for changes.
-}
receiveLocalStorageChange : (String -> Maybe String -> msg) -> Decoder msg
receiveLocalStorageChange toMsg =
    let
        actualDecoder =
            Decode.map2 toMsg
                (Decode.field "key" Decode.string)
                (Decode.field "value" (Decode.maybe Decode.string))
    in
        inputDecoder "LocalStorageChange" actualDecoder



-- EVENT HELPERS


{-| A helper for input elements with `type_ "file"`
-}
onFile : (FileRef -> msg) -> Attribute msg
onFile toMsg =
    on "change"
        (Decode.map toMsg (Decode.at [ "target", "files", "0" ] Decode.value))
