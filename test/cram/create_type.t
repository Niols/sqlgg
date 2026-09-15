CREATE TYPE
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > CREATE TABLE "shirt" ("id" INTEGER NOT NULL, "color" "color" NOT NULL);
  > SELECT "id" FROM "shirt" WHERE "color" = 'red';
  > DROP TYPE "color";
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_color db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"color\" AS ENUM ('red', 'green', 'blue')") ~name:"create_type_color" ~kind:Sqlgg_traits.Query.(CreateType "color") ())
  
    let create_shirt db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"shirt\" (\"id\" INTEGER NOT NULL, \"color\" \"color\" NOT NULL)") ~name:"create_shirt" ~kind:Sqlgg_traits.Query.(Create "shirt") ())
  
    let select_2 db  callback =
      let invoke_callback stmt =
        callback
          ~id:(T.get_column_Int stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'red'") ~name:"select_2" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    let drop_type_color db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("DROP TYPE \"color\"") ~name:"drop_type_color" ~kind:Sqlgg_traits.Query.(DropType "color") ())
  
    module Fold = struct
      let select_2 db  callback acc =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'red'") ~name:"select_2" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_2 db  callback =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'red'") ~name:"select_2" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)

Duplicate CREATE TYPE
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > CREATE TYPE "color" AS ENUM ('black', 'white');
  > EOF
  Failed : CREATE TYPE "color" AS ENUM ('black', 'white')
  Fatal error: exception Failure("duplicate type declaration for \"color\"")
  [2]

DROP TYPE IF EXISTS is idempotent
  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > DROP TYPE IF EXISTS "color";
  > DROP TYPE IF EXISTS "color";
  > EOF

Duplicate DROP TYPE
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > DROP TYPE "color";
  > DROP TYPE "color";
  > EOF
  Failed : DROP TYPE "color"
  Fatal error: exception Failure("no such type \"color\"")
  [2]

CREATE DROP CREATE
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > DROP TYPE "color";
  > CREATE TYPE "color" AS ENUM ('black', 'white');
  > CREATE TABLE "shirt" ("id" INTEGER NOT NULL, "color" "color" NOT NULL);
  > SELECT "id" FROM "shirt" WHERE "color" = 'black';
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_color db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"color\" AS ENUM ('red', 'green', 'blue')") ~name:"create_type_color" ~kind:Sqlgg_traits.Query.(CreateType "color") ())
  
    let drop_type_color db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("DROP TYPE \"color\"") ~name:"drop_type_color" ~kind:Sqlgg_traits.Query.(DropType "color") ())
  
    let create_type_color db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"color\" AS ENUM ('black', 'white')") ~name:"create_type_color" ~kind:Sqlgg_traits.Query.(CreateType "color") ())
  
    let create_shirt db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"shirt\" (\"id\" INTEGER NOT NULL, \"color\" \"color\" NOT NULL)") ~name:"create_shirt" ~kind:Sqlgg_traits.Query.(Create "shirt") ())
  
    let select_4 db  callback =
      let invoke_callback stmt =
        callback
          ~id:(T.get_column_Int stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'black'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_4 db  callback acc =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'black'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_4 db  callback =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"shirt\" WHERE \"color\" = 'black'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)


CREATE TYPE misuse
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > CREATE TABLE "shirt" ("id" INTEGER NOT NULL, "color" "color" NOT NULL);
  > SELECT "id" FROM "shirt" WHERE "color" = 'black';
  > EOF
  Failed : SELECT "id" FROM "shirt" WHERE "color" = 'black'
  Fatal error: exception Failure("types Union (blue| green| red) and StringLiteral (black) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (blue| green| red), StringLiteral (black))")
  [2]

Only in PostgreSQL dialect
  $ sqlgg -gen caml -no-header -dialect=mysql - <<'EOF' 2>&1
  > CREATE TYPE "color" AS ENUM ('red', 'green', 'blue');
  > CREATE TABLE "shirt" ("id" INTEGER NOT NULL, "color" "color" NOT NULL);
  > EOF
  Feature UserDefinedType is not supported for dialect MySQL (supported by: PostgreSQL) at 
  Errors encountered, no code generated
  [1]

DROP TYPE is gated per-dialect too
  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TYPE color AS ENUM ('red');
  > DROP TYPE color;
  > EOF
  Feature UserDefinedType is not supported for dialect MySQL (supported by: PostgreSQL) at 
  Feature UserDefinedType is not supported for dialect MySQL (supported by: PostgreSQL) at 
  Errors encountered, no code generated
  [1]

ALTER COLUMN ... TYPE is gated per-dialect (AlterColumn feature)
  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (a INT NOT NULL);
  > ALTER TABLE t ALTER COLUMN a TYPE BIGINT;
  > EOF
  Feature AlterColumn is not supported for dialect MySQL (supported by: PostgreSQL) at TYPE BIGINT
  Errors encountered, no code generated
  [1]

TYPE is unreserved: still usable as a column name, even next to the TYPE keyword
  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE kw (type INTEGER NOT NULL, val TEXT);
  > SELECT type FROM kw WHERE type = 1;
  > ALTER TABLE kw ALTER COLUMN type TYPE SMALLINT;
  > EOF

Unquoted CREATE TYPE / DROP TYPE
  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE color AS ENUM ('red', 'green', 'blue');
  > CREATE TABLE shirt (id INTEGER NOT NULL, c color NOT NULL);
  > SELECT id FROM shirt WHERE c = 'red';
  > DROP TYPE color;
  > EOF

Diff mode: the type registry is reset per schema replay, so the same
CREATE TYPE in both schemas must not clash as a duplicate
  $ cat > diff_initial.sql <<'EOF'
  > CREATE TYPE color AS ENUM ('red');
  > CREATE TABLE t (id INTEGER NOT NULL, c color NOT NULL);
  > EOF
  $ cat > diff_target.sql <<'EOF'
  > CREATE TYPE color AS ENUM ('red');
  > CREATE TABLE t (id INTEGER NOT NULL, c color NOT NULL, extra INTEGER);
  > EOF
  $ sqlgg -no-header -dialect postgresql -diff -now 20260101000000 -gen sql -base diff_initial.sql -target diff_target.sql
  -- [sqlgg] generated
  -- [sqlgg] id=20260101000000_alter_t_add_col_extra
  ALTER TABLE `t` ADD COLUMN `extra` INT;
  ALTER TABLE `t` DROP COLUMN `extra`;

A column declared with a user-defined type records the type by name, so a
migration that adds it re-emits the type instead of inlining its definition
  $ cat > enum_base.sql <<'EOF'
  > CREATE TYPE kind AS ENUM ('Jig', 'Reel');
  > CREATE TABLE tune (id INTEGER NOT NULL);
  > EOF
  $ cat > enum_target.sql <<'EOF'
  > CREATE TYPE kind AS ENUM ('Jig', 'Reel');
  > CREATE TABLE tune (id INTEGER NOT NULL, k kind NOT NULL);
  > EOF
  $ sqlgg -no-header -dialect postgresql -diff -now 20260101000000 -gen sql -base enum_base.sql -target enum_target.sql
  -- [sqlgg] generated
  -- [sqlgg] id=20260101000000_alter_tune_add_col_k
  ALTER TABLE `tune` ADD COLUMN `k` kind NOT NULL;
  ALTER TABLE `tune` DROP COLUMN `k`;

Recording the name does not change how the column is typed: it is still the
enum it resolved to at declaration time
  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a', 'b');
  > CREATE TABLE t (c k NOT NULL);
  > SELECT c FROM t WHERE c = 'a';
  > EOF

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a', 'b');
  > CREATE TABLE t (c k NOT NULL);
  > SELECT c FROM t WHERE c = 'z';
  > EOF
  Failed : SELECT c FROM t WHERE c = 'z'
  Fatal error: exception Failure("types Union (a| b) and StringLiteral (z) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (a| b), StringLiteral (z))")
  [2]

A user-defined type is a valid CAST target, which is how an enum is converted
through text in PostgreSQL
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind" AS ENUM ('Jig', 'Reel');
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" "kind" NOT NULL);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE "kind_new" USING CAST(CAST("kind" AS TEXT) AS "kind_new");
  > SELECT "id" FROM "tune" WHERE "kind" = 'Air';
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_kind db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"kind\" AS ENUM ('Jig', 'Reel')") ~name:"create_type_kind" ~kind:Sqlgg_traits.Query.(CreateType "kind") ())
  
    let create_type_kind_new db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"kind_new\" AS ENUM ('Jig', 'Reel', 'Air')") ~name:"create_type_kind_new" ~kind:Sqlgg_traits.Query.(CreateType "kind_new") ())
  
    let create_tune db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"tune\" (\"id\" INTEGER NOT NULL, \"kind\" \"kind\" NOT NULL)") ~name:"create_tune" ~kind:Sqlgg_traits.Query.(Create "tune") ())
  
    let alter_tune_3 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TABLE \"tune\" ALTER COLUMN \"kind\" TYPE \"kind_new\" USING CAST(CAST(\"kind\" AS TEXT) AS \"kind_new\")") ~name:"alter_tune_3" ~kind:Sqlgg_traits.Query.(Alter ["tune"]) ())
  
    let select_4 db  callback =
      let invoke_callback stmt =
        callback
          ~id:(T.get_column_Int stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"tune\" WHERE \"kind\" = 'Air'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_4 db  callback acc =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"tune\" WHERE \"kind\" = 'Air'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_4 db  callback =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT \"id\" FROM \"tune\" WHERE \"kind\" = 'Air'") ~name:"select_4" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)

Casting to a type that does not exist says so
  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (x TEXT NOT NULL);
  > SELECT CAST(x AS bogus_type) FROM t;
  > EOF
  ==> SELECT CAST(x AS bogus_type) FROM t
  Position 1:28 Tokens: ) FROM t
  Error: no such type "bogus_type"
  Errors encountered, no code generated
  [1]

Integer CAST targets, with their signedness
  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (x TEXT NOT NULL);
  > SELECT CAST(x AS INTEGER), CAST(x AS SMALLINT), CAST(x AS BIGINT), CAST(x AS BIGINT UNSIGNED) FROM t;
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_t db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE t (x TEXT NOT NULL)") ~name:"create_t" ~kind:Sqlgg_traits.Query.(Create "t") ())
  
    let select_1 db  callback =
      let invoke_callback stmt =
        callback
          ~r:(T.get_column_Int stmt 0)
          ~r0:(T.get_column_Int stmt 1)
          ~r1:(T.get_column_Int stmt 2)
          ~r2:(T.get_column_UInt64 stmt 3)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT CAST(x AS INTEGER), CAST(x AS SMALLINT), CAST(x AS BIGINT), CAST(x AS BIGINT UNSIGNED) FROM t") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_1 db  callback acc =
        let invoke_callback stmt =
          callback
            ~r:(T.get_column_Int stmt 0)
            ~r0:(T.get_column_Int stmt 1)
            ~r1:(T.get_column_Int stmt 2)
            ~r2:(T.get_column_UInt64 stmt 3)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT CAST(x AS INTEGER), CAST(x AS SMALLINT), CAST(x AS BIGINT), CAST(x AS BIGINT UNSIGNED) FROM t") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_1 db  callback =
        let invoke_callback stmt =
          callback
            ~r:(T.get_column_Int stmt 0)
            ~r0:(T.get_column_Int stmt 1)
            ~r1:(T.get_column_Int stmt 2)
            ~r2:(T.get_column_UInt64 stmt 3)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT CAST(x AS INTEGER), CAST(x AS SMALLINT), CAST(x AS BIGINT), CAST(x AS BIGINT UNSIGNED) FROM t") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)
