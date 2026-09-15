ALTER TYPE ... RENAME TO

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > ALTER TYPE "kind_new" RENAME TO "kind";
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_kind_new db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"kind_new\" AS ENUM ('Jig', 'Reel', 'Air')") ~name:"create_type_kind_new" ~kind:Sqlgg_traits.Query.(CreateType "kind_new") ())
  
    let alter_type_kind_new_1 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TYPE \"kind_new\" RENAME TO \"kind\"") ~name:"alter_type_kind_new_1" ~kind:Sqlgg_traits.Query.(AlterType "kind_new") ())
  
  end (* module Sqlgg *)

The type is usable under its new name afterwards

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a', 'b');
  > ALTER TYPE k1 RENAME TO k2;
  > CREATE TABLE t (c k2 NOT NULL);
  > SELECT c FROM t WHERE c = 'a';
  > EOF

...and the old name no longer names a type

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a');
  > ALTER TYPE k1 RENAME TO k2;
  > CREATE TABLE t (c k1 NOT NULL);
  > EOF
  ==> CREATE TABLE t (c k1 NOT NULL)
  Position 1:24 Tokens: NOT NULL)
  Error: Not_found
  Errors encountered, no code generated
  [1]

Columns declared before the rename keep the same constructors, since a rename
does not change the definition, but they now name the type under its new name

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a', 'b');
  > CREATE TABLE t (c k1 NOT NULL);
  > ALTER TYPE k1 RENAME TO k2;
  > SELECT c FROM t WHERE c = 'a';
  > EOF

The rename is reported against the old name, the way RENAME TABLE is

  $ sqlgg -gen xml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a');
  > ALTER TYPE k1 RENAME TO k2;
  > EOF
  <?xml version="1.0"?>
  
  <sqlgg>
   <stmt name="create_type_k1" sql="CREATE TYPE k1 AS ENUM ('a')" category="DDL" kind="create_type" target="k1" cardinality="0">
    <in/>
    <out/>
   </stmt>
   <stmt name="alter_type_k1_1" sql="ALTER TYPE k1 RENAME TO k2" category="DDL" kind="alter_type" target="k1" cardinality="0">
    <in/>
    <out/>
   </stmt>
  </sqlgg>

Renaming a type that does not exist

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > ALTER TYPE nope RENAME TO other;
  > EOF
  Failed : ALTER TYPE nope RENAME TO other
  Fatal error: exception Failure("no such type \"nope\"")
  [2]

Renaming onto a name that is already taken

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE a AS ENUM ('x');
  > CREATE TYPE b AS ENUM ('y');
  > ALTER TYPE a RENAME TO b;
  > EOF
  Failed : ALTER TYPE a RENAME TO b
  Fatal error: exception Failure("duplicate type declaration for \"b\"")
  [2]

Round trip: renaming back and forth

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k AS ENUM ('a');
  > ALTER TYPE k RENAME TO k_old;
  > CREATE TYPE k AS ENUM ('a', 'b');
  > CREATE TABLE t (old k_old NOT NULL, new k NOT NULL);
  > SELECT old, new FROM t WHERE new = 'b';
  > EOF

Behind the same user_defined_type dialect gate as CREATE/DROP TYPE

  $ sqlgg -gen none -dialect=mysql -no-check user_defined_type - <<'EOF' 2>&1
  > CREATE TYPE a AS ENUM ('x');
  > ALTER TYPE a RENAME TO b;
  > EOF
  Warning: Feature UserDefinedType is not supported for dialect MySQL, proceeding anyway at 
  Warning: Feature UserDefinedType is not supported for dialect MySQL, proceeding anyway at 

Because the column follows the rename, a later ADD VALUE on the new name still
reaches it

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a');
  > CREATE TABLE t (c k1 NOT NULL);
  > ALTER TYPE k1 RENAME TO k2;
  > ALTER TYPE k2 ADD VALUE 'b';
  > SELECT c FROM t WHERE c = 'b';
  > EOF

...and the schema records the new name, so DDL emitted for the table does not
mention a type that no longer exists

  $ cat > ren_base.sql <<'EOF'
  > CREATE TYPE k1 AS ENUM ('a');
  > EOF
  $ cat > ren_target.sql <<'EOF'
  > CREATE TYPE k1 AS ENUM ('a');
  > CREATE TABLE t (c k1 NOT NULL);
  > ALTER TYPE k1 RENAME TO k2;
  > EOF
  $ sqlgg -no-header -dialect postgresql -diff -now 20260101000000 -gen sql -ddl-as-migration -base ren_base.sql -target ren_target.sql
  -- [sqlgg] generated
  -- [sqlgg] id=20260101000000_create_t
  CREATE TABLE `t` (`c` k2 NOT NULL);
  DROP TABLE `t`;

Columns of a different named type are left alone by the rename

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE k1 AS ENUM ('a');
  > CREATE TYPE other AS ENUM ('a');
  > CREATE TABLE t (c k1 NOT NULL, o other NOT NULL);
  > ALTER TYPE k1 RENAME TO k2;
  > ALTER TYPE k2 ADD VALUE 'b';
  > SELECT o FROM t WHERE o = 'b';
  > EOF
  Failed : SELECT o FROM t WHERE o = 'b'
  Fatal error: exception Failure("types Union (a) and StringLiteral (b) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (a), StringLiteral (b))")
  [2]

The whole enum migration dance: add a new type, convert the column to it, drop
the old type, rename the new one into its place, then extend it

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind" AS ENUM ('Jig', 'Reel');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" "kind" NOT NULL);
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE "kind_new" USING "kind";
  > DROP TYPE "kind";
  > ALTER TYPE "kind_new" RENAME TO "kind";
  > ALTER TYPE "kind" ADD VALUE IF NOT EXISTS 'March';
  > SELECT "id" FROM "tune" WHERE "kind" = 'March';
  > EOF
