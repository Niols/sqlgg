ALTER COLUMN ... TYPE ... USING

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" TEXT NOT NULL);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE "kind_new" USING "kind";
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_type_kind_new db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TYPE \"kind_new\" AS ENUM ('Jig', 'Reel', 'Air')") ~name:"create_type_kind_new" ~kind:Sqlgg_traits.Query.(CreateType "kind_new") ())
  
    let create_tune db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"tune\" (\"id\" INTEGER NOT NULL, \"kind\" TEXT NOT NULL)") ~name:"create_tune" ~kind:Sqlgg_traits.Query.(Create "tune") ())
  
    let alter_tune_2 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TABLE \"tune\" ALTER COLUMN \"kind\" TYPE \"kind_new\" USING \"kind\"") ~name:"alter_tune_2" ~kind:Sqlgg_traits.Query.(Alter ["tune"]) ())
  
  end (* module Sqlgg *)

The new type takes effect, exactly as it does without a USING clause: the
column is an enum afterwards, so a literal outside it is rejected

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" TEXT NOT NULL);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE "kind_new" USING "kind";
  > SELECT "id" FROM "tune" WHERE "kind" = 'Air';
  > EOF

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TYPE "kind_new" AS ENUM ('Jig', 'Reel', 'Air');
  > CREATE TABLE "tune" ("id" INTEGER NOT NULL, "kind" TEXT NOT NULL);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE "kind_new" USING "kind";
  > SELECT "id" FROM "tune" WHERE "kind" = 'Nope';
  > EOF
  Failed : SELECT "id" FROM "tune" WHERE "kind" = 'Nope'
  Fatal error: exception Failure("types Union (Air| Jig| Reel) and StringLiteral (Nope) for 'a do not match in 'a -> 'a -> Bool?? applied to (Union (Air| Jig| Reel), StringLiteral (Nope))")
  [2]

Any expression is accepted

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "tune" ("kind" TEXT NOT NULL);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE TEXT USING CAST("kind" AS TEXT);
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE TEXT USING UPPER("kind");
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE TEXT USING COALESCE("kind", 'Jig');
  > ALTER TABLE "tune" ALTER COLUMN "kind" TYPE TEXT USING 'Jig';
  > EOF

It is parsed, so a syntax error inside it is still reported

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (c TEXT NOT NULL);
  > ALTER TABLE t ALTER COLUMN c TYPE TEXT USING UPPER(;
  > EOF
  ==> ALTER TABLE t ALTER COLUMN c TYPE TEXT USING UPPER(
  Error: syntax error
  Errors encountered, no code generated
  [1]

...but it is not resolved against the table, so a column that does not exist in
the USING expression goes unnoticed

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (c TEXT NOT NULL);
  > ALTER TABLE t ALTER COLUMN c TYPE TEXT USING nonexistent_column;
  > EOF

USING belongs to TYPE only, not to the other ALTER COLUMN specs

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (c TEXT);
  > ALTER TABLE t ALTER COLUMN c SET NOT NULL USING c;
  > EOF
  ==> ALTER TABLE t ALTER COLUMN c SET NOT NULL USING c
  Position 1:47 Tokens: USING c
  Error: syntax error
  Errors encountered, no code generated
  [1]

Still behind the AlterColumn dialect feature, clause included

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (c TEXT);
  > ALTER TABLE t ALTER COLUMN c TYPE TEXT USING c;
  > EOF
  Feature AlterColumn is not supported for dialect MySQL (supported by: PostgreSQL) at TYPE TEXT USING c
  Errors encountered, no code generated
  [1]

A USING clause in a replayed schema does not disturb diffing: the column type
is the post-ALTER one, so only the genuine difference is reported

  $ cat > using_base.sql <<'EOF'
  > CREATE TABLE tune (id INTEGER NOT NULL, kind TEXT NOT NULL);
  > ALTER TABLE tune ALTER COLUMN kind TYPE VARCHAR(50) USING kind;
  > EOF
  $ cat > using_target.sql <<'EOF'
  > CREATE TABLE tune (id INTEGER NOT NULL, kind VARCHAR(50) NOT NULL, extra INTEGER);
  > EOF
  $ sqlgg -no-header -dialect postgresql -diff -now 20260101000000 -gen sql -base using_base.sql -target using_target.sql
  -- [sqlgg] generated
  -- [sqlgg] id=20260101000000_alter_tune_add_col_extra
  ALTER TABLE `tune` ADD COLUMN `extra` INT;
  ALTER TABLE `tune` DROP COLUMN `extra`;

  $ cat > using_same.sql <<'EOF'
  > CREATE TABLE tune (id INTEGER NOT NULL, kind VARCHAR(50) NOT NULL);
  > EOF
  $ sqlgg -no-header -dialect postgresql -diff -now 20260101000000 -gen sql -base using_base.sql -target using_same.sql
