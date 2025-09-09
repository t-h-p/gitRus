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
  mode : string;
  name : string;
  (* Hash should be 20 byte representation, as opposed to hexidecimal *)
  hash : string;
}

let git_compare_entries e1 e2 =
  let name1 = if e1.mode = "40000" then e1.name ^ "/" else e1.name in
  let name2 = if e2.mode = "40000" then e2.name ^ "/" else e2.name in
  String.compare name1 name2

let obj_hash obj =
  match obj with
  | Blob content ->
    let len = String.length content in
    let raw = (Printf.sprintf "blob %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | Tree items ->
    let f   (acc:string) (tree_item: tree_entry) = acc ^ tree_item.mode ^ " " ^ tree_item.name ^ "\000" ^ tree_item.hash in
    let content = List.fold_left f "" items in
    let len = String.length content in
    let raw = (Printf.sprintf "tree %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | _ ->
    Error "Wrong object type"

let hash_hex obj =
  match obj_hash obj with
  | Ok digest -> Sha1.to_hex digest
  | Error _ -> failwith "hash_hex didn't work"

let hash_bin obj =
  match obj_hash obj with
  | Ok digest -> Sha1.to_bin digest
  | Error _ -> failwith "obj_hash_bin didn't work"

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

let blob_of_link linkname =
  Blob (Unix.readlink linkname)

(*
Directory (040000) -- (Unix.S_DIR, 0o755)
Regular file (100644) -- (Unix.S_REG, 0o644)
Executable file (100755) -- (Unix.S_REG, 0o755)
Symlink (120000) -- (Unix.S_LNK, 0o777)
*)

let kind_and_perms filename =
  let stats = Unix.stat filename in
  (stats.Unix.st_kind, stats.Unix.st_perm)


let filemode filename =
  let kp = kind_and_perms filename in
  match kp with
  | (Unix.S_DIR,_) -> 0o040000
  | (Unix.S_REG,0o644) -> 0o100644
  | (Unix.S_REG,0o755) -> 0o100755
  | (Unix.S_LNK,_) -> 0o120000
  | _ -> failwith "Wrong filemode"

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


(* This function is only useful for example purposes *)
let rec tree_of_directory dirname =
  let files = get_files dirname in
  let pairs = List.combine files (List.map (fun f -> filemode (Filename.concat dirname f)) files) in
  let fn item =
    match item with
    | (f, 0o100644) -> {mode = "100644"; name = f; hash = hash_bin (blob_of_file (Filename.concat dirname f))}
    | (f, 0o100755) -> {mode = "100755"; name = f; hash = hash_bin (blob_of_file (Filename.concat dirname f))}
    | (d, 0o040000) -> {mode = "40000"; name = d; hash = hash_bin (tree_of_directory (Filename.concat dirname d))}
    | (l, 0o120000) -> {mode = "120000"; name = l; hash = hash_bin (blob_of_link (Filename.concat dirname l))}
    | (_,_) -> failwith "Wrong filemode"
  in
  let items = List.sort git_compare_entries (List.map fn pairs) in
  Tree items