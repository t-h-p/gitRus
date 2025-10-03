open Core

(** Utilities that have been helpful in simplifying mutliple files *)

let from_root path = (Sys.getenv_exn "GITRUS") ^ path