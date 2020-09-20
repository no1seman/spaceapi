local types = require("cartridge.graphql.types")
local db_api = require("spaceapi.dbapi")
local module_name = "spaceapi"

local space_field_type = types.enum({
    name = "SpaceFieldType",
    description = "Space field type",
    values = {
        unsigned = "unsigned",
        string = "string",
        varbinary = "varbinary",
        integer = "integer",
        number = "number",
        double = "double",
        boolean = "boolean",
        decimal = "decimal",
        map = "map",
        array = "array",
        scalar = "scalar"
    }
})

local space_engine = types.enum({
    name = "SpaceEngine",
    description = "Space engine",
    values = {
        memtx = "memtx",
        vinyl = "vinyl",
        blackhole = "blackhole",
        sysview = "sysview",
        service = "service"
    }
})

local space_index_type = types.enum({
    name = "SpaceIndexType",
    description = "Space index type",
    values = {
        tree = "TREE",
        hash = "HASH",
        bitset = "BITSET",
        rtree = "RTREE"
    }
})

local space_index_dimention = types.enum({
        name = "SpaceIndexDimention",
        description = "Space index dimention",
        values = {
            euclid = "euclid",
            manhattan = "manhattan"
        }
    })

local space_field_fields = {
    name = types.string,
    type = space_field_type,
    is_nullable = types.boolean
}

local space_field = types.object({
    name = "SpaceField",
    description = "Space field",
    fields = space_field_fields
})

local space_field_input = types.inputObject({
    name = "SpaceFieldInput",
    description = "Space field",
    fields = space_field_fields
})

local space_index_part_fields = {
    type = space_field_type,
    fieldno = types.int,
    is_nullable = types.boolean
}

local space_index_part = types.object({
    name = "SpaceIndexPart",
    description = "Space index part",
    fields = space_index_part_fields
})

local space_index_part_input = types.inputObject({
    name = "SpaceIndexPartInput",
    description = "Space index part",
    fields = space_index_part_fields
})

local space_index = types.object({
    name = "SpaceIndex",
    description = "Space Index",
    fields = {
        name = types.string,
        type = space_index_type,
        id = types.int,
        unique = types.boolean,
        if_not_exists = types.boolean,
        parts = types.list(space_index_part),
        dimension = types.int,
        distance = space_index_dimention,
        bloom_fpr = types.float,
        page_size = types.int,
        range_size = types.int,
        run_count_per_level = types.int,
        run_size_ratio = types.float
    }
})

local space_index_input = types.inputObject({
    name = "SpaceIndexInput",
    description = "Space Index",
    fields = {
        name = types.string,
        type = space_index_type,
        id = types.int,
        unique = types.boolean,
        if_not_exists = types.boolean,
        parts = types.list(space_index_part_input),
        dimension = types.int,
        distance = space_index_dimention,
        bloom_fpr = types.float,
        page_size = types.int,
        range_size = types.int,
        run_count_per_level = types.int,
        run_size_ratio = types.float
    }
})

local space_ck_constraint_fields = {
    name = types.string,
    is_enabled = types.boolean,
    space_id = types.int,
    expr = types.string
}

local space_ck_constraint = types.object({
        name = "SpaceCkConstraint",
        description = "Space check constraint",
        fields = space_ck_constraint_fields
    })

local space_ck_constraint_input = types.inputObject({
    name = "SpaceCkConstraintInput",
    description = "Space check constraint",
    fields = space_ck_constraint_fields
})

local space = types.object({
    name = "Space",
    description = "Space",
    fields = {
        format = types.list(space_field),
        id = types.int,
        name = types.string,
        engine = space_engine,
        field_count = types.int,
        temporary = types.boolean,
        is_local = types.boolean,
        enabled = types.boolean,
        size = types.int,
        user = types.string,
        index = types.list(space_index),
        ck_constraint = types.list(space_ck_constraint)
    }
})

local function space_get(_, args, _) return db_api:space_get(args) end

local function space_remove(_, args, _) return db_api:space_remove(args) end

local function space_add(_, args) return db_api:space_add(args) end

local function init(graphql)
    graphql.add_callback({
        name = "space",
        doc = "Get space(s) definition",
        args = {name = types.string, id = types.int},
        kind = types.list(space),
        callback = module_name .. ".space_get"
    })

    graphql.add_mutation({
        name = "space_remove",
        doc = "Remove space",
        args = {name = types.string, id = types.int},
        kind = space,
        callback = module_name .. ".space_remove"
    })
    graphql.add_mutation({
        name = "space_add",
        doc = "Add new space",
        args = {
            format = types.list(space_field_input),
            id = types.int,
            name = types.string,
            engine = space_engine,
            field_count = types.int,
            temporary = types.boolean,
            is_local = types.boolean,
            enabled = types.boolean,
            size = types.int,
            user = types.string,
            index = types.list(space_index_input),
            ck_constraint = types.list(space_ck_constraint_input)
        },
        kind = space,
        callback = module_name .. ".space_add"
    })
end

return {
    init = init,
    space_get = space_get,
    space_remove = space_remove,
    space_add = space_add
}
