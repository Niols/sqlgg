ORDER BY ... NULLS FIRST | NULLS LAST

  $ sqlgg -gen caml -no-header -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS FIRST;
  > EOF
  module Sqlgg (T : Sqlgg_traits.M) = struct
  
    module IO = Sqlgg_io.Blocking
  
    let create_t db  =
      T.execute_unprepared db (Sqlgg_traits.Query.make ~sql:("CREATE TABLE t (id INTEGER NOT NULL, name TEXT)") ~name:"create_t" ~kind:Sqlgg_traits.Query.(Create "t") ())
  
    let select_1 db  callback =
      let invoke_callback stmt =
        callback
          ~id:(T.get_column_Int stmt 0)
      in
      T.select db (Sqlgg_traits.Query.make ~sql:("SELECT id FROM t ORDER BY name NULLS FIRST") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params invoke_callback
  
    module Fold = struct
      let select_1 db  callback acc =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref acc in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT id FROM t ORDER BY name NULLS FIRST") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x !r_acc))
        (fun () -> IO.return !r_acc)
  
    end (* module Fold *)
    
    module List = struct
      let select_1 db  callback =
        let invoke_callback stmt =
          callback
            ~id:(T.get_column_Int stmt 0)
        in
        let r_acc = ref [] in
        IO.(>>=) (T.select db (Sqlgg_traits.Query.make ~sql:("SELECT id FROM t ORDER BY name NULLS FIRST") ~name:"select_1" ~kind:Sqlgg_traits.Query.(Select Nat) ()) T.no_params (fun x -> r_acc := invoke_callback x :: !r_acc))
        (fun () -> IO.return (List.rev !r_acc))
  
    end (* module List *)
  end (* module Sqlgg *)

With and without a direction, on several sort keys, and with sqlgg's dynamic
direction parameter

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS LAST;
  > SELECT id FROM t ORDER BY name DESC NULLS LAST;
  > SELECT id FROM t ORDER BY name ASC NULLS FIRST, id DESC NULLS LAST;
  > SELECT id FROM t ORDER BY name @dir NULLS FIRST;
  > EOF

It is a placement, not a direction, so it does not replace ASC/DESC and the
plain forms keep working

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name;
  > SELECT id FROM t ORDER BY name DESC, id ASC;
  > EOF

Also on an UPDATE's ORDER BY, and on the row order of a VALUES source

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > UPDATE t SET name = 'x' ORDER BY name NULLS FIRST;
  > SELECT x FROM (VALUES ROW(1), ROW(2) ORDER BY 1 NULLS LAST) AS v(x);
  > EOF

PostgreSQL and SQLite only: MySQL and TiDB have no such clause, and the error
points at it

  $ sqlgg -gen none -dialect=sqlite - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS LAST;
  > EOF

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name DESC NULLS LAST;
  > EOF
  Feature NullsOrder is not supported for dialect MySQL (supported by: PostgreSQL, SQLite) at NULLS LAST
  Errors encountered, no code generated
  [1]

  $ sqlgg -gen none -dialect=tidb - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS FIRST;
  > EOF
  Feature NullsOrder is not supported for dialect TiDB (supported by: PostgreSQL, SQLite) at NULLS FIRST
  Errors encountered, no code generated
  [1]

  $ sqlgg -gen none -dialect=mysql -no-check nulls_order - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS LAST;
  > EOF
  Warning: Feature NullsOrder is not supported for dialect MySQL, proceeding anyway at NULLS LAST

One check is reported per sort key that carries the clause

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id FROM t ORDER BY name NULLS FIRST, id NULLS LAST;
  > EOF
  Feature NullsOrder is not supported for dialect MySQL (supported by: PostgreSQL, SQLite) at NULLS LAST
  Feature NullsOrder is not supported for dialect MySQL (supported by: PostgreSQL, SQLite) at NULLS FIRST
  Errors encountered, no code generated
  [1]

On an index column, where sqlgg records neither the direction nor the
placement, so it is only checked for syntax

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > CREATE INDEX i1 ON t (name NULLS FIRST);
  > CREATE INDEX i2 ON t (name DESC NULLS LAST);
  > CREATE INDEX i3 ON t (name COLLATE "C" text_pattern_ops DESC NULLS FIRST);
  > EOF

A window's ORDER BY accepts it, but window_spec keeps nothing of that order,
so unlike the clauses above it is not dialect-checked

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id, SUM(id) OVER (ORDER BY name NULLS LAST) FROM t;
  > EOF

  $ sqlgg -gen none -dialect=mysql - <<'EOF' 2>&1
  > CREATE TABLE t (id INTEGER NOT NULL, name TEXT);
  > SELECT id, SUM(id) OVER (ORDER BY name NULLS LAST) FROM t;
  > EOF

last stays unreserved, nulls does not: an operator class in a CREATE INDEX
column is a bare identifier, so leaving NULLS unreserved would make `nulls`
there ambiguous with the clause

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE kw (last TEXT, id INTEGER NOT NULL);
  > SELECT last FROM kw ORDER BY last NULLS FIRST;
  > CREATE INDEX i ON kw (last NULLS LAST);
  > EOF

  $ sqlgg -gen none -dialect=postgresql - <<'EOF' 2>&1
  > CREATE TABLE kw (nulls TEXT);
  > EOF
  ==> CREATE TABLE kw (nulls TEXT)
  Position 1:22 Tokens: nulls TEXT)
  Error: syntax error
  Errors encountered, no code generated
  [1]
