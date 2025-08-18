let hash_blob obj =
  match obj with
  | Git_object.Blob content ->
    Some (Sha1.to_hex (Sha1.string content))
  | _ ->
    None