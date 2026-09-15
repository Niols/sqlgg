(** Global registry of user-defined types (CREATE TYPE) *)

open Printf

type registry = (string, Sql.Type.kind) Hashtbl.t

let registry : registry = Hashtbl.create 8

let add name kind =
  match Hashtbl.mem registry name with
  | true -> failwith (sprintf "duplicate type declaration for %S" name)
  | false -> Hashtbl.add registry name kind

let drop ~if_exists name =
  match Hashtbl.mem registry name, if_exists with
  | true, _ -> Hashtbl.remove registry name
  | false, true -> ()
  | false, false -> failwith (sprintf "no such type %S" name)

let get_opt = Hashtbl.find_opt registry

let get = Hashtbl.find registry

let snapshot () = Hashtbl.copy registry
let restore = Prelude.hashtbl_restore registry

let rename old_name new_name =
  match Hashtbl.find_opt registry old_name with
  | None -> failwith (sprintf "no such type %S" old_name)
  | Some _ when Hashtbl.mem registry new_name ->
    failwith (sprintf "duplicate type declaration for %S" new_name)
  | Some kind ->
    Hashtbl.remove registry old_name;
    Hashtbl.add registry new_name kind
