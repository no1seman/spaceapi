local log = require("log")
local checks = require("checks")
local errors = require("errors")

local DBAPIError = errors.new_class("SpaceAPIError")

local db_api = {}
db_api.___index = db_api

local function _space_get(space_name)
    local space = {}

    for k, v in pairs(box.space[space_name]) do
        if type(v) ~= 'table' then space[k] = v end
    end

    space.size = box.space[space_name]:bsize()
    space.format = box.space[space_name]:format()

    space.index = {}
    for i = 0, #box.space[space_name].index do
        local index = box.space[space_name].index[i]
        if index ~= nil then
            index.id = i
            table.insert(space.index, index)
        end
    end

    space.ck_constraint = {}

    for _, v in pairs(box.space[space_name].ck_constraint) do
        table.insert(space.ck_constraint, v)
    end

    return space
end

local function _space_get_all()
    local spaces = {}
    for _, space in box.space._space:pairs() do
        local _space = _space_get(space.name)
        table.insert(spaces, _space)
    end

    return spaces
end

function db_api:space_get(args)
    local space_name = args.name
    local space_id = tonumber(args.id)

    -- if both space name and space id is provided - return an error
    if (space_name and space_id) then
        local err = DBAPIError:new(
                        "Both space name and space id in request is not supported")
        return nil, err
    end

    -- if not space name nor space id is provided or id space_name = "" - return all spaces
    if (not space_name and not space_id) or (space_name == '') then
        return _space_get_all()
    end

    if space_name and space_name ~= '' then
        if box.space[space_name] then
            return {_space_get(space_name)}
        else
            local err =
                DBAPIError:new("Space: '%s' - doesn't exist", space_name)
            return nil, err
        end
    end

    if space_id and box.space['_space']:select(space_id) then
        return {_space_get(box.space['_space']:select(space_id)[1][3])}
    else
        local err = DBAPIError:new("Space: '%s' - doesn't exist", space_name)
        return nil, err
    end

end

local function _space_remove_by_id(space_id)
    checks('number')

    local space = _space_get(box.space['_space']:select(space_id)[1][3])

    log.info(space)
    local ok, err = pcall(box.schema.space.drop, space_id)

    if ok then
        return space
    else
        return nil,
               DBAPIError:new("Space id='%s' delete error: %s", space_id, err)
    end
end

local function _space_remove_by_name(space_name)
    checks('string')

    if box.space[space_name] then
        local space_id = box.space[space_name].id
        return _space_remove_by_id(space_id)
    else
        return nil, DBAPIError:new("Space '%s' doesn't exist", space_name)
    end
end

function db_api:space_remove(args)
    local space_name = args.name
    local space_id = tonumber(args.id)

    -- if both space name and space id is provided - return an error
    if (space_name and space_id) then
        local err = DBAPIError:new("Both space name and space id is provided in request")
        return nil, err
    end

    if space_name and space_name ~= '' then
        return _space_remove_by_name(space_name)
    end

    if space_id and space_id ~= '' then
        return _space_remove_by_id(space_id)
    end
    local err = DBAPIError:new("No space name nor space id is provided in request")
    return nil, err
end

function db_api:space_add(args)
    local space_name = args.name
    local space_index = args.index
    local space_ck_constraints = args.ck_constraint

    if box.space[space_name] then
        return nil, DBAPIError:new('Space "%s" already exists', space_name)
    end

    local space_options = {
        engine = args.engine and args.engine or 'memtx',
        field_count = args.field_count and
            tonumber(args.field_count) or 0,
        id = args.id and args.id or nil,
        if_not_exists = args.if_not_exists and args.if_not_exists or
            false,
        is_local = args.is_local and args.is_local or false,
        temporary = args.temporary and args.temporary or false,
        user = args.user and args.user or box.session.user()
    }

    local format = {}
    for _, field in pairs(args.format) do
        table.insert(format, {
            name = field.name,
            type = field.type,
            is_nullable = field.is_nullable and field.is_nullable or false
        })
    end

    space_options.format = format

    local ok, err = pcall(box.schema.space.create, space_name, space_options)

    if not ok then
        return nil, DBAPIError:new("Space creation error: %s", err)
    end

    for _, index in pairs(space_index) do
        local index_name = index.name
        local index_options = {
            type = index.type and index.type or 'TREE',
            id = index.id and index.id or nil,
            unique = index.unique and index.unique or true,
            if_not_exists = index.if_not_exists and index.if_not_exists or true
        }

        index_options.parts = {}

        if index.parts then
            for _, part in pairs(index.parts) do
                table.insert(index_options.parts, {
                    field = part.fieldno,
                    type = part.type,
                    is_nullable = part.is_nullable
                })
            end
        else
            index_options.parts = {1, 'unsigned'}
        end

        ok = box.space[space_name]:create_index(index_name, index_options)

        if not ok then
            return nil, DBAPIError:new('Index "%s" creation error: %s', index_name, err)
        end
    end

    for _, check_constraint in pairs(space_ck_constraints) do
        local check_constraint_name = check_constraint.name
        local check_constraint_expr = check_constraint.expr
        local check_constraint_is_enabled = check_constraint.is_enabled
        box.space[space_name]:create_check_constraint(check_constraint_name,
                                                      check_constraint_expr)
        box.space[space_name].ck_constraint[check_constraint_name]:enable(
            check_constraint_is_enabled)
    end

    return _space_get(space_name)
end

return db_api
