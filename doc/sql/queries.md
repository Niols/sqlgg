---
sidebar_position: 2
title: Queries
description: SELECT, INSERT, UPDATE, DELETE statements in sqlgg
---

# Queries

## Overview

DML (Data Manipulation Language) and DQL (Data Query Language) statements in sqlgg generate typed functions for database operations. sqlgg analyzes your queries against the schema defined in DDL to automatically infer:

- **Parameter types** — from usage context
- **Return types** — from SELECT column lists and nullability
- **Function signatures** — complete types for type-safe database access

## Function Naming

All statements can be annotated with function names:

```sql
-- @function_name
SELECT/INSERT/UPDATE/DELETE statement
```

Function names are auto-generated if no annotation is provided.

## SELECT

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER
);

-- @get_all_users
SELECT name, email, age FROM users;
```

**Inferred types:**
- `name`: Text (strict)
- `email`: Text (nullable)
- `age`: Int (nullable)

## INSERT

```bnf
INSERT INTO table [(columns)] VALUES (values) [, (values) ...]
INSERT INTO table [(columns)] VALUES @list_param
INSERT INTO table SET column = value [, ...]
REPLACE INTO table [(columns)] VALUES (values)

-- conflict handling
  ON DUPLICATE KEY UPDATE column = value [, ...]
  ON CONFLICT (columns) DO UPDATE SET column = value [, ...]
  ON CONFLICT (columns) DO NOTHING
```

```sql
INSERT INTO users (name, email) VALUES (@name, @email);
INSERT INTO users (name, email) VALUES @values;  -- @values: (string * string option) list
INSERT INTO users SET name = @name, email = @email;
INSERT INTO users (id, name) VALUES (@id, @name) ON DUPLICATE KEY UPDATE name = @upd;
REPLACE INTO users (id, name) VALUES (@id, @name);
```

## UPDATE

```sql
-- Basic UPDATE
UPDATE users SET email = @new_email WHERE id = @user_id;

-- Multiple columns
UPDATE users SET name = @name, email = @email, age = @age WHERE id = @id;

-- UPDATE with JOIN (MySQL)
UPDATE users u
JOIN profiles p ON p.user_id = u.id
SET u.name = @name, p.bio = @bio
WHERE u.id = @id;

-- UPDATE ... FROM (PostgreSQL, SQLite)
UPDATE entry SET created_at = person.created_at
FROM person
WHERE entry.id = person.id;

-- UPDATE with expressions
UPDATE users SET age = age + @increment WHERE id = @id;
```

In `UPDATE ... FROM`, only the target table is assignable; the `FROM` tables just
supply values. An unqualified name on the left of `=` therefore always means a column
of the target, even when a `FROM` table has one of the same name, and assigning to a
`FROM` table is an error. PostgreSQL has no `ORDER BY` or `LIMIT` on `UPDATE`, so
neither is accepted alongside `FROM`.

## DELETE

```sql
-- Basic DELETE
DELETE FROM users WHERE id = @user_id;

-- DELETE with table name (MySQL)
DELETE users FROM users WHERE id = @id;

-- Multi-table DELETE (MySQL)
DELETE u, p
FROM users u
JOIN profiles p ON p.user_id = u.id
WHERE u.id = @id;

-- DELETE with JOIN
DELETE u
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL;
```

## VALUES as Table Expression

`VALUES` can be used as a table in JOINs:

```sql
-- With typed parameter
SELECT entitlement, product_name
FROM products p
JOIN ( VALUES @values :: (Text, Int) ) AS x (product_name, entitlement)
ON p.name = x.product_name;
-- @values: (string * int) list

-- With literal ROW values
INSERT INTO entitlements (product_id, entitlement)
SELECT p.id, x.entitlement
FROM products p
JOIN ( VALUES ROW('a', 1), ROW('b', 2), ROW('c', 3) ) AS x (product_name, entitlement)
ON p.name = x.product_name;
```

