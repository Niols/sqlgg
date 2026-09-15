UPDATE ... FROM

  $ cat > uf_schema.sql <<'EOF'
  > CREATE TABLE "person" (id INT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT, modified_at TEXT);
  > CREATE TABLE "entry" (id INT PRIMARY KEY, created_at TEXT, modified_at TEXT);
  > EOF

  $ sqlgg -gen caml -no-header -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE "entry" SET "created_at" = "person"."created_at", "modified_at" = "person"."modified_at" FROM "person" WHERE "entry"."id" = "person"."id";
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let update_entry_0 db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("UPDATE \"entry\" SET \"created_at\" = \"person\".\"created_at\", \"modified_at\" = \"person\".\"modified_at\" FROM \"person\" WHERE \"entry\".\"id\" = \"person\".\"id\"") ~name:"update_entry_0" ~kind:Sqlgg_traits.Query.(Update (Some "entry")) ())
  
  end (* module Sqlgg *)

Only the target table is written, so this is a single-table UPDATE as far as
statement metadata is concerned

  $ sqlgg -gen xml -no-header -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id;
  > EOF
  <?xml version="1.0"?>
  
  <sqlgg>
   <stmt name="update_entry_0" sql="UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id" category="DML" kind="update" target="entry" cardinality="0">
    <in/>
    <out/>
   </stmt>
   <table name="entry">
    <schema>
     <value name="id" type="Int"/>
     <value name="created_at" type="Text" nullable="true"/>
     <value name="modified_at" type="Text" nullable="true"/>
    </schema>
   </table>
   <table name="person">
    <schema>
     <value name="id" type="Int"/>
     <value name="name" type="Text"/>
     <value name="created_at" type="Text" nullable="true"/>
     <value name="modified_at" type="Text" nullable="true"/>
    </schema>
   </table>
  </sqlgg>

An unqualified assignment names a target column even when a FROM table has a
column of the same name, so created_at above is not ambiguous. Qualifying it
with the target is allowed too.

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET entry.created_at = person.created_at FROM person WHERE entry.id = person.id;
  > EOF

Assigning to a FROM table is rejected: PostgreSQL only updates the target

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET person.created_at = 'x' FROM person WHERE entry.id = person.id;
  > EOF
  Failed : UPDATE entry SET person.created_at = 'x' FROM person WHERE entry.id = person.id
  Fatal error: exception Failure("UPDATE ... FROM assigns to entry only, not to person")
  [2]

...and so is assigning a column the target does not have, even though the FROM
table does have it

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET name = person.name FROM person WHERE entry.id = person.id;
  > EOF
  Failed : UPDATE entry SET name = person.name FROM person WHERE entry.id = person.id
  At : name
  Fatal error: exception Sqlgg.Sql.Schema.Error(_, "missing attribute : name")
  [2]

Parameters are collected from the assignments and the WHERE clause, and typed
against the columns they meet

  $ sqlgg -gen caml -no-header -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = @ts FROM person WHERE person.name = @nm AND entry.id = person.id;
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let update_entry_0 db ~ts ~nm =
      let set_params stmt =
        let p = T.start_params stmt (2) in
        begin match ts with None -> T.set_param_null p | Some v -> T.set_param_Text p v end;
        T.set_param_Text p nm;
        T.finish_params p
      in
      T.execute db (Sqlgg_traits.Query.make ~sql:("UPDATE entry SET created_at = $1 FROM person WHERE person.name = $2 AND entry.id = person.id") ~name:"update_entry_0" ~kind:Sqlgg_traits.Query.(Update (Some "entry")) ()) set_params
  
  end (* module Sqlgg *)

Aliases and joins in the FROM list

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = p.created_at FROM person p WHERE entry.id = p.id;
  > UPDATE entry SET created_at = p.created_at FROM person p JOIN person q ON q.id = p.id WHERE entry.id = p.id;
  > UPDATE entry SET created_at = p.created_at FROM person p, person q WHERE entry.id = p.id AND q.id = p.id;
  > EOF

PostgreSQL has no ORDER BY or LIMIT on UPDATE, so they are refused next to FROM

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id ORDER BY entry.id;
  > EOF
  ==> UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id ORDER BY entry.id
  Error: UPDATE ... FROM does not support ORDER BY or LIMIT
  Errors encountered, no code generated
  [1]

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id LIMIT 1;
  > EOF
  ==> UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id LIMIT 1
  Error: UPDATE ... FROM does not support ORDER BY or LIMIT
  Errors encountered, no code generated
  [1]

FROM updates one target, not MySQL's comma-separated list

  $ sqlgg -gen none -dialect=postgresql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry, person SET created_at = 'x' FROM person WHERE entry.id = person.id;
  > EOF
  ==> UPDATE entry, person SET created_at = 'x' FROM person WHERE entry.id = person.id
  Error: UPDATE ... FROM updates a single table
  Errors encountered, no code generated
  [1]

PostgreSQL and SQLite only

  $ sqlgg -gen none -dialect=sqlite -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id;
  > EOF

  $ sqlgg -gen none -dialect=mysql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id;
  > EOF
  Feature UpdateFrom is not supported for dialect MySQL (supported by: PostgreSQL, SQLite) at 
  Errors encountered, no code generated
  [1]

  $ sqlgg -gen none -dialect=mysql -no-check update_from -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry SET created_at = person.created_at FROM person WHERE entry.id = person.id;
  > EOF
  Warning: Feature UpdateFrom is not supported for dialect MySQL, proceeding anyway at 

The existing UPDATE forms are unaffected: MySQL's multi-table update, and a
plain single-table UPDATE with ORDER BY and LIMIT

  $ sqlgg -gen none -dialect=mysql -open uf_schema.sql - <<'EOF' 2>&1
  > UPDATE entry, person SET entry.created_at = person.created_at WHERE entry.id = person.id;
  > UPDATE entry SET created_at = 'x' WHERE id = 1 ORDER BY id LIMIT 1;
  > EOF
