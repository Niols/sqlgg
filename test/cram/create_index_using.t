CREATE INDEX with a PostgreSQL access method and operator class

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "person" ("id" INTEGER NOT NULL, "name" TEXT NOT NULL);
  > CREATE INDEX "idx_person_name" ON "person" USING GIN ("name" "public"."gin_trgm_ops");
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_person db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE \"person\" (\"id\" INTEGER NOT NULL, \"name\" TEXT NOT NULL)") ~name:"create_person" ~kind:Sqlgg_traits.Query.(Create "person") ())
  
    let create_index_idx_person_name db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE INDEX \"idx_person_name\" ON \"person\" USING GIN (\"name\" \"public\".\"gin_trgm_ops\")") ~name:"create_index_idx_person_name" ~kind:Sqlgg_traits.Query.(CreateIndex "idx_person_name") ())
  
  end (* module Sqlgg *)

The access method is optional and may name any method, and the operator class
may be schema-qualified or bare, per column

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "person" ("id" INTEGER NOT NULL, "name" TEXT NOT NULL);
  > CREATE INDEX i1 ON "person" USING GIN ("name");
  > CREATE INDEX i2 ON "person" USING btree ("name");
  > CREATE INDEX i3 ON "person" USING gist ("name" "public"."gist_trgm_ops");
  > CREATE INDEX i4 ON "person" ("name" gin_trgm_ops);
  > CREATE INDEX i5 ON "person" USING btree ("id", "name" text_pattern_ops);
  > CREATE UNIQUE INDEX IF NOT EXISTS i6 ON "person" USING btree ("name" text_pattern_ops DESC);
  > EOF

Ordered after COLLATE, as PostgreSQL spells it

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "person" ("name" TEXT NOT NULL);
  > CREATE INDEX i ON "person" ("name" COLLATE "C" text_pattern_ops DESC);
  > EOF

Neither the method nor the operator class is recorded, but the indexed columns
still are: an operator class is not mistaken for a column, and a column that
does not exist is still an error

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE "person" ("id" INTEGER NOT NULL);
  > CREATE INDEX i ON "person" USING GIN ("nope" "public"."gin_trgm_ops");
  > EOF
  Failed : CREATE INDEX i ON "person" USING GIN ("nope" "public"."gin_trgm_ops")
  Fatal error: exception Sqlgg.Sql.Schema.Error(_, "missing attribute : nope")
  [2]

MySQL spells USING too, and the existing forms are unaffected

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE person (id INTEGER NOT NULL, name TEXT NOT NULL);
  > CREATE INDEX i1 ON person USING BTREE (name);
  > CREATE INDEX i2 ON person (name(10) DESC);
  > CREATE INDEX i3 ON person (id, name);
  > EOF
