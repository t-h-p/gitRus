(*open Hash*)

type t =
  | Blob of string
  | Tree of tree_entry list
  | Commit of {
    tree_hash : string;
    parents : string list;
    author : string;
    committer : string;
    message : string;
  }
  | Tag of {
    object_hash : string;
    object_type : string;
    tag_name : string;
    tagger : string;
    message : string;
  }
and tree_entry = {
  mode : int;
  name : string;
  (* Hash should be 20 byte representation, as opposed to hexidecimal *)
  hash : string;
}

let with_in_channel filename f =
  let ic = open_in filename in
  try
    let result = f ic in
    close_in ic;
    result
  with e ->
    close_in_noerr ic;
    raise e

let blob_of_file filename =
  Blob (with_in_channel filename (fun ic ->
    let len  = in_channel_length ic in
    really_input_string ic len
  ))

(*
Directory (040000) -- (Unix.S_DIR, 0o755)
Regular file (100644) -- (Unix.S_REG, 0o644)
Executable file (100755) -- (Unix.S_REG, 0o755)
Symlink (120000) -- (Unix.S_LNK, 0o777)
*)

exception UnsupportedGitMode of (Unix.file_kind * int)

let kind_and_perms filename =
  let stats = Unix.stat filename in
  (stats.Unix.st_kind, stats.Unix.st_perm)

let filemode filename =
  let kp = kind_and_perms filename in
  match kp with
  | (Unix.S_DIR, _) -> 0o040000
  | (Unix.S_REG, 0o644) -> 0o100644
  | (Unix.S_REG, 0o755) -> 0o100755
  | (Unix.S_LNK, _) -> 0x120000
  | _ -> raise (UnsupportedGitMode kp)

let get_files dirname =
  let handle = Unix.opendir dirname in
  let rec read entries =
    try
      let entry = Unix.readdir handle in
      match entry with
      | "." | ".." | ".git" -> read entries
      | _ -> read (entry :: entries)
    with
    | End_of_file ->
      Unix.closedir handle;
      entries
    in
    read []

(*
let rec tree_of_directory dirname =
  let files = get_files dirname in
  let modes = List.map filemode files in
  let hashes =
*)