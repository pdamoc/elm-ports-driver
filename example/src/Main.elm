module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import PortsDriver exposing (Config, FileRef, FileData)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, Value)


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


config : Config Msg
config =
    { output = Ports.output
    , input = Ports.input
    , fail = Fail
    }


type alias Size =
    { width : Int
    , height : Int
    }


windowResizeDecoder : Decoder Size
windowResizeDecoder =
    Decode.map2 Size
        (Decode.field "width" Decode.int)
        (Decode.field "height" Decode.int)


subscriptions : Model -> Sub Msg
subscriptions _ =
    PortsDriver.subscriptions config
        [ PortsDriver.receiveFileAsDataURL ReceiveFile
        , PortsDriver.receiveLocalStorageItem ReceiveStorageItem
        , PortsDriver.receiveLocalStorageChange ReceiveStorageItem

        -- handler for the custom event listener installed in JS
        , PortsDriver.inputDecoder "WindowResize" (Decode.map Resize windowResizeDecoder)
        ]



-- MODEL


type alias Model =
    { fileContents : Maybe String
    , storageEvents : List ( String, Maybe String )
    , windowSize : Size
    }


type alias ID =
    String


model : Model
model =
    { fileContents = Nothing
    , storageEvents = []
    , windowSize = Size 0 0
    }



-- UPDATE


type Msg
    = SetTitle
    | Fail String
    | FileSelect ID FileRef
    | ReceiveFile FileData
    | UpdateCss String
    | Log String
    | MyLog String
    | GetKeyToken
    | SetKeyToken
    | RemoveKeyToken
    | ReceiveStorageItem String (Maybe String)
    | Resize Size
    | FileDrop FileRef


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fail str ->
            ( model, PortsDriver.log config str )

        SetTitle ->
            ( model, PortsDriver.setTitle config "AWESOME!!!" )

        FileSelect id value ->
            ( model, PortsDriver.readAsDataURL config id value )

        ReceiveFile { id, filename, contents } ->
            ( { model | fileContents = Just contents }, Cmd.none )

        UpdateCss css ->
            ( model, PortsDriver.updateCss config css )

        Log str ->
            ( model, PortsDriver.log config str )

        MyLog str ->
            ( model, PortsDriver.send config "MyLog" (Encode.string str) )

        GetKeyToken ->
            ( model, PortsDriver.localStorageGetItem config "token" )

        SetKeyToken ->
            ( model, PortsDriver.localStorageSetItem config "token" "token_value" )

        RemoveKeyToken ->
            ( model, PortsDriver.localStorageRemoveItem config "token" )

        ReceiveStorageItem key maybeValue ->
            ( { model | storageEvents = ( key, maybeValue ) :: model.storageEvents }, Cmd.none )

        Resize size ->
            ( { model | windowSize = size }, Cmd.none )

        FileDrop fileRef ->
            ( model, PortsDriver.readAsDataURL config "image-select" fileRef )



-- VIEW


view : Model -> Html Msg
view model =
    let
        imgContents =
            case model.fileContents of
                Nothing ->
                    "static/img/elm.jpg"

                Just contents ->
                    contents
    in
        [ div [ class "row jumbotron" ]
            [ div [ class "col-12" ]
                [ h1 []
                    [ text <|
                        String.join " "
                            [ "Elm Ports Driver ("
                            , toString model.windowSize.width
                            , " x "
                            , toString model.windowSize.height
                            , ")"
                            ]
                    ]
                ]
            , div [ class "col-12" ]
                [ img [ src imgContents, style styles.img ] []
                ]
            , div [ class "col-12" ]
                [ input
                    [ id "image-select"
                    , type_ "file"
                    , PortsDriver.onFile (FileSelect "image-select")
                    ]
                    [ label
                        [ class "input-group-text", for "inputGroupFile01" ]
                        [ text "Choose image" ]
                    ]
                ]
            , div [ class "col-12" ] [ hr [] [] ]
            , div
                [ class "col-12" ]
                [ button [ class "btn btn-primary btn-lg ml-3", onClick SetTitle ]
                    [ text "Set Title to AWESOME!"
                    ]
                , button [ class "btn btn-primary btn-lg ml-3", onClick (UpdateCss makeBkgRed) ]
                    [ text "Make Background Red"
                    ]
                , button [ class "btn btn-primary btn-lg ml-3", onClick (UpdateCss makeBkgAqua) ]
                    [ text "Make Background Aqua"
                    ]
                ]
            , div [ class "col-12 m-3" ]
                [ button
                    [ class "btn btn-primary btn-lg ml-3"
                    , onClick (Log "Hello!")
                    ]
                    [ text "Log Hello!"
                    ]
                , button
                    [ class "btn btn-primary btn-lg ml-3"
                    , onClick (MyLog "Hello!")
                    ]
                    [ text "MyLog Hello!"
                    ]
                ]
            , div [ class "col-12 m-3" ]
                [ button
                    [ class "btn btn-primary btn-lg ml-3"
                    , onClick GetKeyToken
                    ]
                    [ text "Get Token"
                    ]
                , button
                    [ class "btn btn-primary btn-lg ml-3"
                    , onClick SetKeyToken
                    ]
                    [ text "Set Token"
                    ]
                , button
                    [ class "btn btn-primary btn-lg ml-3"
                    , onClick RemoveKeyToken
                    ]
                    [ text "Remove Token"
                    ]
                ]
            ]
        ]
            ++ (List.map (\item -> div [ class "row" ] [ text <| toString item ]) model.storageEvents)
            |> div [ class "container", style [ ( "margin-top", "30px" ), ( "text-align", "center" ) ] ]



-- CSS STYLES


makeBkgRed : String
makeBkgRed =
    """
body {
  background-color: crimson;
}
"""


makeBkgAqua : String
makeBkgAqua =
    """
body {
  background-color: aqua;
}
"""


styles : { img : List ( String, String ) }
styles =
    { img =
        [ ( "width", "33%" )
        , ( "border", "4px solid #337AB7" )
        ]
    }
