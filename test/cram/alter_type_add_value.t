ALTER TYPE ... ADD VALUE

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind" AS ENUM ('Jig', 'Reel');
  > ALTER TYPE "kind" ADD VALUE IF NOT EXISTS 'Air';
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_kind db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"kind\" AS ENUM ('Jig', 'Reel')") ~name:"create_type_kind" ~kind:Sqlgg_traits.Query.(CreateType "kind") ())
  
    let alter_type_kind_1 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TYPE \"kind\" ADD VALUE IF NOT EXISTS 'Air'") ~name:"alter_type_kind_1" ~kind:Sqlgg_traits.Query.(AlterType "kind") ())
  
  end (* module Sqlgg *)

A column declared before the ALTER follows its type and accepts the new value

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind" AS ENUM ('Jig', 'Reel');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" "kind" NOT NULL);
  > ALTER TYPE "kind" ADD VALUE IF NOT EXISTS 'Air';
  > SELECT "id" FROM "tune" WHERE "kind" = 'Air';
  > EOF

...while a value that is still not in the type stays rejected

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind" AS ENUM ('Jig', 'Reel');
  > CREATE TABLE "tune" ("kind" "kind" NOT NULL);
  > ALTER TYPE "kind" ADD VALUE IF NOT EXISTS 'Air';
  > SELECT "kind" FROM "tune" WHERE "kind" = 'Nope';
  > EOF
  Failed : SELECT "kind" FROM "tune" WHERE "kind" = 'Nope'
  Fatal error: exception Failure("types Union (Air| Jig| Reel) and StringLiteral (Nope) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (Air| Jig| Reel), StringLiteral (Nope))")
  [2]

The generated enum picks up the new constructor

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a', 'b');
  > CREATE TABLE t (c k NOT NULL);
  > ALTER TYPE k ADD VALUE 'zz';
  > SELECT c FROM t;
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
      module Enum_0 = T.Make_enum(struct
        type t = [`A | `B | `Zz]
        let inj = function | "a" -> `A | "b" -> `B | "zz" -> `Zz | s -> failwith (Printf.sprintf "Invalid enum value: %s" s)
        let proj = function  | `A -> "a"| `B -> "b"| `Zz -> "zz"
      end)
  
    let create_type_k db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE k AS ENUM ('a', 'b')") ~name:"create_type_k" ~kind:Sqlgg_traits.Query.(CreateType "k") ())
  
    let create_t db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE t (c k NOT NULL)") ~name:"create_t" ~kind:Sqlgg_traits.Query.(Create "t") ())
  
    let alter_type_k_2 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TYPE k ADD VALUE 'zz'") ~name:"alter_type_k_2" ~kind:Sqlgg_traits.Query.(AlterType "k") ())
  
    let select_3 db  callback =
      let invoke_callback stmt =
        callback
          ~c:(Enum_0.get_column stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT c FROM t") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_3 db  callback acc =
        let invoke_callback stmt =
          callback
            ~c:(Enum_0.get_column stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT c FROM t") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_3 db  callback =
        let invoke_callback stmt =
          callback
            ~c:(Enum_0.get_column stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT c FROM t") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)

Only columns declared with that named type follow it: another user-defined
type with the same constructors, and an inline ENUM column, are untouched

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > CREATE TYPE other AS ENUM ('a');
  > CREATE TABLE t (viak k NOT NULL, viaother other NOT NULL);
  > ALTER TYPE k ADD VALUE 'new';
  > SELECT viaother FROM t WHERE viaother = 'new';
  > EOF
  Failed : SELECT viaother FROM t WHERE viaother = 'new'
  Fatal error: exception Failure("types Union (a) and StringLiteral (new) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (a), StringLiteral (new))")
  [2]

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > CREATE TABLE t (viak k NOT NULL, inline ENUM('a') NOT NULL);
  > ALTER TYPE k ADD VALUE 'new';
  > SELECT inline FROM t WHERE inline = 'new';
  > EOF
  Failed : SELECT inline FROM t WHERE inline = 'new'
  Fatal error: exception Failure("types Union (a) and StringLiteral (new) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (a), StringLiteral (new))")
  [2]

Adding a value the type already has needs IF NOT EXISTS

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > ALTER TYPE k ADD VALUE 'a';
  > EOF
  Failed : ALTER TYPE k ADD VALUE 'a'
  Fatal error: exception Failure("type \"k\" already contains value \"a\"")
  [2]

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > ALTER TYPE k ADD VALUE IF NOT EXISTS 'a';
  > EOF

Adding to a type that does not exist

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > ALTER TYPE nope ADD VALUE 'x';
  > EOF
  Failed : ALTER TYPE nope ADD VALUE 'x'
  Fatal error: exception Failure("no such type \"nope\"")
  [2]

value stays unreserved: still usable as a column name, even next to ADD VALUE

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE value AS ENUM ('a');
  > CREATE TABLE t (value value NOT NULL);
  > SELECT value FROM t WHERE value = 'a';
  > ALTER TYPE value ADD VALUE 'b';
  > SELECT value FROM t WHERE value = 'b';
  > ALTER TABLE t RENAME COLUMN value TO value2;
  > EOF

Behind the user_defined_type dialect gate

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > ALTER TYPE k ADD VALUE 'b';
  > EOF
  Feature UserDefinedType is not supported for dialect MySQL (supported by: PostgreSQL) at 
  Feature UserDefinedType is not supported for dialect MySQL (supported by: PostgreSQL) at 
  Errors encountered, no code generated
  [1]

A new value may be placed relative to an existing one

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE kind AS ENUM ('Jig', 'Jig_9_8');
  > ALTER TYPE kind ADD VALUE IF NOT EXISTS 'Air' BEFORE 'Jig';
  > ALTER TYPE kind ADD VALUE IF NOT EXISTS 'March_2_4' AFTER 'Jig_9_8';
  > EOF

The position is discarded: constructors are an unordered set, so the value is
added but not placed. 'Zebra' asked to go before 'Jig' and still comes last.

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE kind AS ENUM ('Jig', 'Reel');
  > CREATE TABLE tune (k kind NOT NULL);
  > ALTER TYPE kind ADD VALUE 'Zebra' BEFORE 'Jig';
  > SELECT k FROM tune;
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
      module Enum_0 = T.Make_enum(struct
        type t = [`Jig | `Reel | `Zebra]
        let inj = function | "Jig" -> `Jig | "Reel" -> `Reel | "Zebra" -> `Zebra | s -> failwith (Printf.sprintf "Invalid enum value: %s" s)
        let proj = function  | `Jig -> "Jig"| `Reel -> "Reel"| `Zebra -> "Zebra"
      end)
  
    let create_type_kind db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE kind AS ENUM ('Jig', 'Reel')") ~name:"create_type_kind" ~kind:Sqlgg_traits.Query.(CreateType "kind") ())
  
    let create_tune db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE tune (k kind NOT NULL)") ~name:"create_tune" ~kind:Sqlgg_traits.Query.(Create "tune") ())
  
    let alter_type_kind_2 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TYPE kind ADD VALUE 'Zebra' BEFORE 'Jig'") ~name:"alter_type_kind_2" ~kind:Sqlgg_traits.Query.(AlterType "kind") ())
  
    let select_3 db  callback =
      let invoke_callback stmt =
        callback
          ~k:(Enum_0.get_column stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT k FROM tune") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_3 db  callback acc =
        let invoke_callback stmt =
          callback
            ~k:(Enum_0.get_column stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT k FROM tune") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_3 db  callback =
        let invoke_callback stmt =
          callback
            ~k:(Enum_0.get_column stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT k FROM tune") ~name:"select_3" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)

The value is still added, and still reaches columns declared earlier

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE kind AS ENUM ('Jig');
  > CREATE TABLE tune (k kind NOT NULL);
  > ALTER TYPE kind ADD VALUE 'Air' BEFORE 'Jig';
  > SELECT k FROM tune WHERE k = 'Air';
  > EOF

Since the position is not interpreted, it may name a value that does not exist

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE kind AS ENUM ('Jig');
  > ALTER TYPE kind ADD VALUE 'Air' AFTER 'NoSuchValue';
  > EOF

before stays unreserved

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (before TEXT NOT NULL, id INTEGER);
  > SELECT before FROM t WHERE before = 'x';
  > ALTER TABLE t RENAME COLUMN before TO after_;
  > EOF
