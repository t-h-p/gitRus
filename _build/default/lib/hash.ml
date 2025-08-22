let obj_hash obj =
  match obj with
  | Git_object.Blob content ->
    let len = String.length content in
    let raw = (Printf.sprintf "blob %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | Git_object.Tree items ->
    let f   (acc:string) (tree_item: Git_object.tree_entry) = acc ^ (Int.to_string tree_item.mode) ^ " " ^ tree_item.name ^ "\000" ^ tree_item.hash in
    let content = List.fold_left f "" items in
    let len = String.length content in
    let raw = (Printf.sprintf "tree %d\000" len) ^ content in
    Ok (raw |> Sha1.string)
  | _ ->
    Error "Wrong object type"

let obj_hex obj =
  match obj_hash obj with
  | Ok digest -> Ok (Sha1.to_hex digest)
  | Error _ -> Error "obj_hash_hex didn't work"

let obj_bin obj =
  match obj_hash obj with
  | Ok digest -> Ok (Sha1.to_bin digest)
  | Error _ -> Error "obj_hash_bin didn't work"

