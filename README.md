# Simple GraphQL API for managing spaces in Tarantool Cartridge

Tarantool Cartirdge have builtin GraphQL implementation which may be used for many purposes. This tiny library gets the power of GraphQL to space management in Tarantool Cartridge.

As for now it supports only CR_D of CRUD for all spaces avaible for current user (U will be avaible a bit later).

For test you can use [GrpahiQLIDE](https://github.com/no1seman/graphiqlide) for Tarantool Cartridge

ATTENTION NOW DO NOT USE IN PRODUCTION ENVIRONMENTS CAUSE ITS MAYBE UNSTABLE!!!

## Prequisities

- [Tarantool 2.4.2](https://www.tarantool.io/en/download/?v=2.4)
- [Tarantool Cartridge 2.3.0](https://github.com/tarantool/cartridge)
- [GrpahiQLIDE 0.0.1](https://github.com/no1seman/graphiqlide) (recomended)

## Build

Clone repo and use tarantoolctl to build and pack lua rock:

```bash
https://github.com/no1seman/spaceapi
cd spaceapi
tarantoolctl rocks make
tarantoolctl rocks pack spaceapi scm-1
```

## Install

### 1. Install LUA rock

```bash
cd YOUR_TARANTOOL_CARTRIDGE_DIR
tarantoolctl rocks install PATH_TO_ROCK/spaceapi-scm-1.all.rock
```

### 2. Add in the bottom of init.lua the folowing line to add API to every server in cluster

```bash
require("spaceapi").init(require("cartridge.graphql"))
```

## Examples

Examples needs [GrpahiQLIDE 0.0.1](https://github.com/no1seman/graphiqlide)

### 1. Get space(s) definitions

To get space(s) definition data you can use "space()" query. For eample to get all spaces definitions execute the following query:

```graphql
query {
  space {
    name
    id
    engine
    size
    field_count
    temporary
    is_local
    enabled
    format {
      name
      type
      is_nullable
    }
    index {
      id
      name
      unique
      parts {
        fieldno
        type
        is_nullable
      }
      page_size
      run_size_ratio
      run_count_per_level
      dimension
      bloom_fpr
      distance
      range_size
    }
    ck_constraint {
      name
      is_enabled
      expr
    }
  }
}
```

Query "space" has 2 arguments: "name" and "id" so you can query single space definition by its "name" or by "id". If name is empty - query returns ALL avaible spaces. If "name" and "id" provided simultaneously error will be raised.

### 2. Create space

To create a new space you have to use "space_add()" mutation:

```graphql
mutation SpaceAdd($name: String, $engine: SpaceEngine, $is_local: Boolean, $temporary: Boolean, $format: [SpaceFieldInput], $index: [SpaceIndexInput], $ck_constraint: [SpaceCkConstraintInput]) {
  space_add(name: $name, engine: $engine, is_local: $is_local, temporary: $temporary, format: $format, index: $index, ck_constraint: $ck_constraint) {
    id
    name
    engine
    is_local
    temporary
    format {
      name
      type
      is_nullable
    }
    index {
      id
      name
      type
      unique
      parts {
        type
        fieldno
        is_nullable
      }
    }
    ck_constraint {
      name
      is_enabled
      expr
    }
  }
}
```

Variables:

```json
{
  "name": "t",
  "engine": "memtx",
  "is_local": false,
  "temporary": false,
  "format": [
    {
      "name": "f1",
      "type": "unsigned"
    },
    {
      "name": "f2",
      "type": "string"
    },
    {
      "name": "f3",
      "type": "string"
    }
  ],
  "index": [
    {
      "unique": true,
      "parts": [
        {
          "type": "unsigned",
          "is_nullable": false,
          "fieldno": 1
        }
      ],
      "id": 0,
      "type": "TREE",
      "name": "i"
    }
  ],
  "ck_constraint": [
    {
      "is_enabled": true,
      "name": "c1",
      "expr": "\"f2\" > 'A'"
    },
    {
      "is_enabled": true,
      "name": "c2",
      "expr": "\"f2\"=UPPER(\"f3\") AND NOT \"f2\" LIKE '__'"
    }
  ]
}
```

### 3. Delete space

To delete space use "space_remove()" mutation:

```graphql
mutation {
  space_remove(name: "t") {
    name
  }
}
```

Like query "space()" mutation "space_remove()" has 2 arguments: "name" and "id". You can delete space its "name" or by "id". If "name" and "id" provided simultaneously error will be raised.

## Test

Use "test/test.sh" (GNU bash) script to test
Attention, don't forget to specify server URI and login/password in "test.sh"
