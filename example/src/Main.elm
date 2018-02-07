module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import PortsDriver exposing (Driver)


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = ( model, Cmd.none )
        , update = update
        , view = view
        , subscriptions = always driver.subscriptions
        }


driver : Driver Msg
driver =
    PortsDriver.install
        { output = Ports.output
        , input = Ports.input
        , lift = PortsMsg
        , fail = Fail
        }



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
    = Fail String
    | SetTitle
    | FileSelect ID
    | PortsMsg PortsDriver.Msg
    | UpdateCss String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Fail str ->
            ( model, driver.log str )

        SetTitle ->
            ( model, driver.setTitle "AWESOME!!!" )

        FileSelect id ->
            ( model, driver.file.readAsDataURL id )

        PortsMsg pMsg ->
            case pMsg of
                PortsDriver.File id filename (PortsDriver.TextFile contents) ->
                    ( { model | fileContents = Just contents }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        UpdateCss css ->
            ( model, driver.updateCss css )



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
              div [ class "row" ]
                [ div [ class "col-12" ]
                    [ div [ class "jumbotron" ]
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
