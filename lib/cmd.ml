open Core
open Git_object

let get_hash_hex name =
  let blob =
  match name with
  | "-" -> Blob (In_channel.input_all In_channel.stdin)
  | filename -> blob_of_file filename
in
hash_hex blob

let file_to_db = "todo"


let hash_object =
  Command.basic
    ~summary: "Generate SHA-1 object hash"
    (let%map_open.Command
      (*write = flag "-w" no_arg ~doc:"Write to object database."
      and*) from_stdin = flag "--stdin" no_arg ~doc:"Read from stdin"
      and file_name = anon (maybe ("filename" %: Filename_unix.arg_type))
    in
    fun() ->
      let hash =
      if from_stdin then
        get_hash_hex "-"
      else match file_name with
      | Some name -> get_hash_hex name
      | None -> failwith "No filename provided"
      in
      print_endline hash)

  let command =
    Command.group
      ~summary:"Git reimplementation for the people"
      ["hash-object", hash_object]