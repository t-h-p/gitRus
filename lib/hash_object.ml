let hash_blob obj =
  match obj with
  | Git_object.Blob content ->
    let len = String.length content in
    let raw = (Printf.sprintf "blob %d\000" len) ^ content in
    Some (Sha1.to_hex (Sha1.string raw))
  | _ ->
    None