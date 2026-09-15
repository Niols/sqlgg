ALTER TABLE ... RENAME CONSTRAINT

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "entry" ("id" INTEGER NOT NULL);
  > ALTER TABLE "entry" RENAME CONSTRAINT "globally_unique_id_pkey" TO "pk_entry";
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_entry db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"entry\" (\"id\" INTEGER NOT NULL)") ~name:"create_entry" ~kind:Sqlgg_traits.Query.(Create "entry") ())
  
    let alter_entry_1 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("ALTER TABLE \"entry\" RENAME CONSTRAINT \"globally_unique_id_pkey\" TO \"pk_entry\"") ~name:"alter_entry_1" ~kind:Sqlgg_traits.Query.(Alter ["entry"]) ())
  
  end (* module Sqlgg *)

Constraints are not tracked by name, so the statement leaves the schema alone
and queries written after it still see the same columns

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "entry" ("id" INTEGER NOT NULL, "name" TEXT);
  > ALTER TABLE "entry" RENAME CONSTRAINT "a" TO "b";
  > SELECT "id", "name" FROM "entry";
  > EOF

Renaming a constraint that was never declared is accepted, for the same reason

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL);
  > ALTER TABLE t RENAME CONSTRAINT nonexistent TO other;
  > EOF

Alongside other actions in one ALTER TABLE

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL);
  > ALTER TABLE t RENAME CONSTRAINT a TO b, ADD COLUMN extra INTEGER;
  > SELECT id, extra FROM t;
  > EOF

PostgreSQL-only

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL);
  > ALTER TABLE t RENAME CONSTRAINT a TO b;
  > EOF
  Feature RenameConstraint is not supported for dialect MySQL (supported by: PostgreSQL) at RENAME CONSTRAINT a TO b
  Errors encountered, no code generated
  [1]

  $ sqlgg -gen none -dialect=mysql -no-check rename_constraint - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL);
  > ALTER TABLE t RENAME CONSTRAINT a TO b;
  > EOF
  Warning: Feature RenameConstraint is not supported for dialect MySQL, proceeding anyway at RENAME CONSTRAINT a TO b

The sibling RENAME forms are unaffected, and CONSTRAINT is still not an
identifier, so the table/column/index spellings keep working

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (a INTEGER NOT NULL, b INTEGER);
  > ALTER TABLE t RENAME COLUMN a TO c;
  > ALTER TABLE t RENAME INDEX i1 TO i2;
  > ALTER TABLE t RENAME KEY i2 TO i3;
  > ALTER TABLE t RENAME TO t2;
  > SELECT c, b FROM t2;
  > EOF
