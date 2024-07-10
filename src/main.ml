external is_dev : bool = "DEV" [@@mel.scope "import", "meta", "env"]

external is_hot : bool = "hot" [@@mel.scope "import", "meta"]

external hot_accept : (unit -> unit) -> unit = "accept"
[@@mel.scope "import", "meta", "hot"]

external hot_accept_dep : string -> (string -> unit) -> unit = "accept"
[@@mel.scope "import", "meta", "hot"]

external hot_accept_deps : string array -> (string array -> unit) -> unit
  = "accept"
[@@mel.scope "import", "meta", "hot"]

external hot_dispose : (unit -> unit) -> unit = "dispose"
[@@mel.scope "import", "meta", "hot"]

let document = Webapi.Dom.document

let container =
  Webapi.Dom.Document.getElementById "main" document
  |> Option.map Webapi.Dom.Element.asNode

let run () =
  if is_dev then
    if is_hot then
      let shutdown_fun = ref (App.start_hot_debug_app container None) in
      hot_accept_dep "app.ml" (fun _mods ->
          let new_start_fun :
              Dom.node option -> App.model option -> unit -> App.model option =
            [%raw {|_mods[0].start_hot_debug_app|}]
          in
          shutdown_fun := new_start_fun container (!shutdown_fun ()) ;
          () )
    else App.start_debug_app container |. ignore
  else App.start_app container |. ignore

let _ = Js.Global.setTimeout ~f:(fun _ -> run ()) 0
