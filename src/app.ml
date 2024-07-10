type model = int

type msg =
  | Increment
  | Decrement
  | Reset
  | LocationChanged of Tea_navigation.Location.t
  | Set of int
[@@deriving accessors]

let msg_to_string (msg : msg) =
  match msg with
  | Increment ->
      "Inc"
  | Decrement ->
      "Dec"
  | Reset ->
      "Reset"
  | LocationChanged _location ->
      "Location changed"
  | Set i ->
      "Set to " ^ string_of_int i

let update model = function
  | Increment ->
      (model + 1, Tea.Cmd.none)
  | Decrement ->
      (model - 1, Tea.Cmd.none)
  | Reset ->
      (0, Tea.Cmd.none)
  | Set v ->
      (v, Tea.Cmd.none)
  | LocationChanged _location ->
      (model, Tea.Cmd.none)

let init () _location = (0, Tea.Cmd.none)

let view_button button_text msg =
  let open Tea.Html in
  button [Events.onClick msg] [text button_text]

let view model =
  let open Tea.Html in
  div []
    [ span [Attributes.style "text-weight" "bold"] [text (string_of_int model)]
    ; br []
    ; view_button "Increment" Increment
    ; br []
    ; view_button "Decrement" Decrement
    ; br []
    ; view_button "Set to 42" (Set 42)
    ; br []
    ; (if model <> 0 then view_button "Reset" Reset else noNode) ]

let subscriptions _model = Tea.Sub.none

let shutdown _model = Tea.Cmd.none

let start_app container =
  Tea.Navigation.navigationProgram locationChanged
    {init; update; view; subscriptions; shutdown}
    container ()

let start_debug_app ?(init = init) ?(shutdown = shutdown) container =
  Tea.Debug.navigationProgram locationChanged
    {init; update; view; subscriptions; shutdown}
    msg_to_string container ()

let start_hot_debug_app container cachedModel =
  (* Replace the existing shutdown function with one that returns the current
   * state of the app, for hot module replacement purposes *)
  (* inspired by https://github.com/walfie/ac-tune-maker *)
  let modelRef = ref None in
  let shutdown model =
    modelRef := Some model ;
    Tea.Cmd.none
  in
  let init =
    match cachedModel with
    | None ->
        init
    | Some model ->
        fun flags location ->
          let _model, cmd = init flags location in
          (model, cmd)
  in
  let app = start_debug_app ~init ~shutdown container in
  let oldShutdown = app##shutdown in
  let newShutdown () = oldShutdown () ; !modelRef in
  let _ = Js.Obj.assign app [%obj {shutdown= newShutdown}] in
  newShutdown
