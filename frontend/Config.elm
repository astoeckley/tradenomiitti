module Config exposing (..)

import Http
import Json.Decode as Json
import State.Config exposing (..)
import Util exposing (UpdateMessage(..))


type Msg
    = GetDomainOptions (List String)
    | GetPositionOptions (List String)
    | GetSpecialSkillOptions CategoriedOptions
    | GetEducationOptions Education


getDomainOptions : Cmd (UpdateMessage Msg)
getDomainOptions =
    Http.get "/api/toimialat" (Json.list Json.string)
        |> Util.errorHandlingSend GetDomainOptions


getPositionOptions : Cmd (UpdateMessage Msg)
getPositionOptions =
    Http.get "/api/tehtavaluokat" (Json.list Json.string)
        |> Util.errorHandlingSend GetPositionOptions


getSpecialSkillOptions : Cmd (UpdateMessage Msg)
getSpecialSkillOptions =
    Http.get "/api/osaaminen" categoriedOptionsDecoder
        |> Util.errorHandlingSend GetSpecialSkillOptions


getEducationOptions : Cmd (UpdateMessage Msg)
getEducationOptions =
    Http.get "/api/koulutus" (Json.dict categoriedOptionsDecoder)
        |> Util.errorHandlingSend GetEducationOptions


initTasks : Cmd (UpdateMessage Msg)
initTasks =
    Cmd.batch
        [ getPositionOptions
        , getDomainOptions
        , getSpecialSkillOptions
        , getEducationOptions
        ]


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        GetPositionOptions list ->
            { model | positionOptions = list } ! []

        GetDomainOptions list ->
            { model | domainOptions = list } ! []

        GetSpecialSkillOptions dict ->
            { model | specialSkillOptions = dict } ! []

        GetEducationOptions education ->
            { model | educationOptions = education } ! []
