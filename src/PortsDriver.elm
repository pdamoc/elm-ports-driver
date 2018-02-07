module PortsDriver exposing (Driver, Config, Msg(..), Contents(..), install, onFileChange)

{-| This is an Elm package - npm package combo designed to be used to simply
some of the ports code usage.


# Types

@docs Driver, Context, Msg, Contents


# Main function

@docs Config, install

-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Html.Events exposing (on)
import Html exposing (Attribute)


-- TYPES


{-| Contents is a union type holding the contents of the file read by the browser.
-}
type Contents
    = TextFile String
    | Blob Value


type Msg
    = File String String Contents


type alias FileOps msg =
    { readAsText : String -> Cmd msg
    , readAsArrayBuffer : String -> Cmd msg
    , readAsDataURL : String -> Cmd msg
    }


type alias Driver msg =
    { log : String -> Cmd msg
    , setTitle : String -> Cmd msg
    , updateCss : String -> Cmd msg
    , file : FileOps msg
    , subscriptions : Sub msg
    }



-- EVENT HELPERS


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


type alias Config msg =
    { output : Value -> Cmd msg
    , input : (Value -> msg) -> Sub msg
    , fail : String -> msg
    , lift : Msg -> msg
    }


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
            , readAsArrayBuffer = \id -> encodeMsg "FileReadAsDataURL" (Encode.string id)
            , readAsDataURL = \id -> encodeMsg "FileReadAsDataURL" (Encode.string id)
            }
        , subscriptions = input (decodeMsg fail lift)
        }
