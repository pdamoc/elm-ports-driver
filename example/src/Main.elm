module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import PortsDriver exposing (Config)
import Json.Encode as Encode


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


subscriptions : Model -> Sub Msg
subscriptions _ =
    PortsDriver.subscriptions config
        [ PortsDriver.receiveFileAsDataURL ReceiveFile ]



-- MODEL


type alias Model =
    { fileContents : Maybe String }


type alias ID =
    String


model : Model
model =
    { fileContents = Nothing }



-- UPDATE


type Msg
    = SetTitle
    | Fail String
    | FileSelect ID
    | ReceiveFile ID String String
    | UpdateCss String
    | Log String
    | MyLog String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fail str ->
            ( model, PortsDriver.log config str )

        SetTitle ->
            ( model, PortsDriver.setTitle config "AWESOME!!!" )

        FileSelect id ->
            ( model, PortsDriver.readAsDataURL config id )

        ReceiveFile id filename contents ->
            ( { model | fileContents = Just contents }, Cmd.none )

        UpdateCss css ->
            ( model, PortsDriver.updateCss config css )

        Log str ->
            ( model, PortsDriver.log config str )

        MyLog str ->
            ( model, PortsDriver.send config "MyLog" (Encode.string str) )



-- VIEW
-- Html is defined as: elem [ attribs ][ children ]
-- CSS can be applied via class names or inline style attrib


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
        div [ class "container", style [ ( "margin-top", "30px" ), ( "text-align", "center" ) ] ]
            [ -- inline CSS (literal)
              div [ class "row jumbotron" ]
                [ div [ class "col-12" ]
                    [ img [ src imgContents, style styles.img ] [] -- inline CSS (via var)
                    , p [] [ text ("Elm Ports Driver") ]
                    , button [ class "btn btn-primary btn-lg ml-3", onClick SetTitle ]
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
                , div [ class "col-12" ]
                    [ input
                        [ id "image-select"
                        , type_ "file"
                        , PortsDriver.onFileChange (FileSelect "image-select")
                        ]
                        [ label
                            [ class "input-group-text", for "inputGroupFile01" ]
                            [ text "Choose image" ]
                        ]
                    ]
                ]
            ]



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
