port module Home exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Link
import ListAds
import ListUsers
import Maybe.Extra as Maybe
import Models.User exposing (User)
import Nav
import Removal
import State.Config as Config
import State.Home exposing (..)
import Util exposing (UpdateMessage(..), ViewMessage(..))


type Msg
    = ListAdsMessage ListAds.Msg
    | ListUsersMessage ListUsers.Msg
    | ClickCreateProfile
    | ScrollBelowFold
    | RemovalMessage Removal.Msg


port scrollHomeBelowFold :
    Bool
    -> Cmd msg -- param is ignored


update : Msg -> Model -> ( Model, Cmd (UpdateMessage Msg) )
update msg model =
    case msg of
        ListAdsMessage msg ->
            let
                ( listAdsModel, cmd ) =
                    ListAds.update msg model.listAds
            in
            { model | listAds = listAdsModel } ! [ Util.localMap ListAdsMessage cmd ]

        ListUsersMessage msg ->
            let
                ( listUsersModel, cmd ) =
                    ListUsers.update msg model.listUsers
            in
            { model | listUsers = listUsersModel } ! [ Util.localMap ListUsersMessage cmd ]

        ClickCreateProfile ->
            { model | createProfileClicked = True } ! []

        ScrollBelowFold ->
            model ! [ scrollHomeBelowFold True ]

        RemovalMessage msg ->
            let
                ( newRemoval, cmd ) =
                    Removal.update msg model.removal
            in
            { model | removal = newRemoval } ! [ Util.localMap RemovalMessage cmd ]


initTasks : Model -> Cmd (UpdateMessage Msg)
initTasks model =
    Cmd.batch
        [ Util.localMap ListAdsMessage (ListAds.initTasks model.listAds)
        , Util.localMap ListUsersMessage (ListUsers.initTasks model.listUsers)
        ]


view : Model -> Maybe User -> H.Html (ViewMessage Msg)
view model loggedInUserMaybe =
    H.div
        []
        [ introScreen loggedInUserMaybe
        , listLatestAds loggedInUserMaybe model
        , listUsers model loggedInUserMaybe
        , tradenomiittiSection
        ]



-- FIRST INFO SCREEN --


introScreen : Maybe User -> H.Html (ViewMessage Msg)
introScreen loggedInUserMaybe =
    H.div
        [ A.class "home__intro-screen" ]
        (introAnimation :: introBoxes loggedInUserMaybe)


introAnimation : H.Html msg
introAnimation =
    H.canvas
        [ A.id "home-intro-canvas"
        , A.class "home__intro-canvas"
        ]
        []


introBoxes : Maybe User -> List (H.Html (ViewMessage Msg))
introBoxes loggedInUserMaybe =
    let
        createProfile =
            case loggedInUserMaybe of
                Just _ ->
                    []

                Nothing ->
                    [ H.div
                        [ A.class "home__introbox home__introbox--button-container col-xs-11 col-sm-4 col-sm-offset-4" ]
                        [ Link.button "Luo oma profiili"
                            "home__introbox--button btn btn-primary"
                            (Nav.LoginNeeded (Nav.Profile |> Nav.routeToPath |> Just))
                        ]
                    ]
    in
    [ H.div
        [ A.class "home__introbox col-xs-11 col-sm-6 col-sm-offset-3" ]
        [ H.h2
            [ A.class "home__introbox--heading" ]
            [ H.text "Kohtaa tradenomi" ]
        ]
    , H.div
        [ A.class "home__introbox col-xs-11 col-sm-6 col-sm-offset-3" ]
        [ H.div
            [ A.class "home__introbox--content" ]
            [ H.text "Tradenomiitti on tradenomien oma kohtaamispaikka, jossa jäsenet löytävät toisensa yhteisten aiheiden ympäriltä ja hyötyvät toistensa kokemuksista." ]
        ]
    ]
        ++ createProfile
        ++ [ H.i
                [ A.class "fa fa-angle-double-down fa-3x home__introbox-check-more"
                , E.onClick (LocalViewMessage ScrollBelowFold)
                ]
                []
           ]



-- LIST LATEST ADS --


listLatestAds : Maybe User -> Model -> H.Html (ViewMessage Msg)
listLatestAds loggedInUserMaybe model =
    H.div
        [ A.class "home__latest-ads" ]
        [ H.div
            [ A.class "home__section--container" ]
            [ listAdsHeading
            , listFourAds loggedInUserMaybe model
            ]
        ]


listAdsHeading : H.Html (ViewMessage Msg)
listAdsHeading =
    H.div
        [ A.class "home__section--heading row" ]
        [ sectionHeader "Uusimmat ilmoitukset"
        , listAdsButtons
        ]


listAdsButtons : H.Html (ViewMessage Msg)
listAdsButtons =
    H.div
        [ A.class "home__section--heading--buttons col-sm-7" ]
        [ Link.button
            "katso kaikki ilmoitukset"
            "home__section--heading--buttons--inverse btn btn-primary"
            Nav.ListAds
        , Link.button
            "jätä ilmoitus"
            "home__section--heading--buttons--normal btn btn-primary"
            Nav.CreateAd
        ]


sectionHeader : String -> H.Html msg
sectionHeader title =
    H.div
        [ A.class "home__section--heading--text col-sm-5" ]
        [ H.text title ]


listFourAds : Maybe User -> Model -> H.Html (ViewMessage Msg)
listFourAds loggedInUserMaybe model =
    Util.localViewMap RemovalMessage <|
        H.div
            []
            (ListAds.viewAds loggedInUserMaybe model.removal (List.take 4 model.listAds.ads))



-- LIST USERS --


listUsers : Model -> Maybe User -> H.Html (ViewMessage msg)
listUsers model loggedInUserMaybe =
    H.div
        [ A.class "home__list-users" ]
        [ H.div
            [ A.class "home__section--container" ]
            [ listUsersHeading loggedInUserMaybe
            , listThreeUsers model
            ]
        ]


listUsersHeading : Maybe User -> H.Html (ViewMessage msg)
listUsersHeading loggedInUserMaybe =
    H.div
        [ A.class "home__section--heading row" ]
        [ sectionHeader "Löydä tradenomi"
        , listUsersButtons loggedInUserMaybe
        ]


listUsersButtons : Maybe User -> H.Html (ViewMessage msg)
listUsersButtons loggedInUserMaybe =
    H.div
        [ A.class "home__section--heading--buttons col-sm-7" ]
        [ Link.button
            "Katso kaikki tradenomit"
            "home__section--heading--buttons--inverse btn btn-primary"
            Nav.ListUsers
        , Link.button
            (if Maybe.isJust loggedInUserMaybe then
                "Muokkaa omaa profiilia"
             else
                "Luo oma profiili"
            )
            "home__section--heading--buttons--normal btn btn-primary"
            (if Maybe.isJust loggedInUserMaybe then
                Nav.Profile
             else
                Nav.LoginNeeded << Just << Nav.routeToPath <| Nav.Profile
            )
        ]


listThreeUsers : Model -> H.Html (ViewMessage msg)
listThreeUsers model =
    ListUsers.row
        (List.map ListUsers.viewUser (List.take 3 model.listUsers.users))



-- TRADENOMIITTI AD --


tradenomiittiSection : H.Html (ViewMessage msg)
tradenomiittiSection =
    H.div
        [ A.class "home__tradenomiitti--background" ]
        [ H.div
            [ A.class "home__tradenomiitti--container" ]
            [ tradenomiittiRow ]
        ]


tradenomiittiRow : H.Html (ViewMessage msg)
tradenomiittiRow =
    H.div
        [ A.class "row home__tradenomiitti-info-row" ]
        [ H.div [ A.class "home__tradenomiitti-info-container  col-md-6" ] [ tradenomiittiInfo ]
        , tradenomiImage
        ]


tradenomiittiInfo : H.Html (ViewMessage msg)
tradenomiittiInfo =
    H.div
        [ A.class "home__tradenomiitti-info" ]
        [ tradenomiittiHeader
        , tradenomiittiInfoText
        , readMoreButton
        ]


tradenomiittiHeader : H.Html msg
tradenomiittiHeader =
    H.h2
        [ A.class "home__tradenomiitti-info--header" ]
        -- \xad === &shy;, that is soft hyphen
        [ H.text "Ko\xADke\xADmuk\xADsel\xADla\xADsi on aina arvoa" ]


tradenomiittiInfoText : H.Html msg
tradenomiittiInfoText =
    H.div
        [ A.class "home__tradenomiitti-info-content" ]
        [ H.p
            [ A.class "home__tradenomiitti-info-text" ]
            [ H.text "Tradenomiitti on tradenomien oma kohtaamispaikka, jossa yhdistyvät inspiroivat kohtaamiset ja itsensä kehittäminen. Tradenomiitti tuo tradenomien osaamisen esille - olit sitten opiskelija tai kokenut konkari. Juuri sinulla voi olla vastaus toisen tradenomin kysymykseen, tai ehkä uusi työnantajasi etsii sinua jo?" ]
        , H.p
            [ A.class "home__tradenomiitti-info-text" ]
            [ H.text "Luomalla profiilin pääset alkuun, loput on itsestäsi kiinni." ]
        ]


readMoreButton : H.Html (ViewMessage msg)
readMoreButton =
    Link.link
        "lue lisää"
        "home__tradenomiitti-info--read-more-button btn btn-primary"
        Nav.Info


tradenomiImage : H.Html msg
tradenomiImage =
    H.div
        [ A.class "col-md-6" ]
        [ H.img
            [ A.class "home__tradenomiitti--image"
            , A.src "/static/home_image.jpg"
            ]
            []
        ]
