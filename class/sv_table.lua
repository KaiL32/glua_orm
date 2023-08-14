Table = {}
Table.__index = Table

setmetatable(Table, {
    __call = function(self, name, columns)
        local tbl = {
            name = name,
            columns = columns
        }

        local primary_keys = {}
        local create_query = 'CREATE TABLE IF NOT EXISTS `' .. name .. '`'
        local column_query = ' (\n'
        local columns_count = #columns
        local i = 1

        for _, column in ipairs(columns) do
            local generator = column:generateQueryString()
            local _str = generator.str
            local primary = generator.primary

            if primary ~= nil then
                table.insert(primary_keys, primary)
            end

            column_query = column_query .. _str

            if i ~= columns_count then
                column_query = column_query .. ',\n'
            end

            i = i + 1
        end

        local primary_str = ''
        local primary_keys_count = table.Count(primary_keys)

        if primary_keys_count > 0 then
            primary_str = ',\nPRIMARY KEY ('
            local i = 1

            for _, name in ipairs(primary_keys) do
                primary_str = primary_str .. '`' .. name .. '`'

                if primary_keys_count ~= i then
                    primary_str = primary_str .. ','
                end

                i = i + 1
            end

            primary_str = primary_str .. ')'
        end

        local final_query = create_query .. column_query .. primary_str .. ')'
        ORM.Query(final_query)
        print("[ORM] Creating table " .. name)

        return setmetatable(tbl, Table)
    end
})

local function insert_replace(table_name, args, _type)
    local insert_query = _type .. ' INTO `' .. table_name .. '`( '
    local column_names = ''
    local values = ''
    local args_count = table.Count(args)
    local i = 1

    for index, value in pairs(args) do
        column_names = column_names .. '`' .. index .. '`'
        local val = value

        if type(val) == "boolean" then
            val = value == true and 1 or 0
        end

        values = values .. SQLStr(tostring(val))

        if i ~= args_count then
            column_names = column_names .. ','
            values = values .. ','
        end

        i = i + 1
    end

    local final_query = insert_query .. column_names .. ' )' .. ' VALUES ( ' .. values .. ' )'
    local promise = kPromise.new()

    ORM.Query(final_query):next(function(id)
        promise:resolve(id)
    end)

    return promise
end

function Table:insert(args)
    local table_name = self.name

    return insert_replace(table_name, args, 'INSERT')
end

function Table:replace(args)
    local table_name = self.name

    return insert_replace(table_name, args, 'REPLACE')
end

local function nice_str(val)
    if type(val) == 'boolean' then
        val = val == true and 1 or 0
    end

    return "'" .. val .. "'"
end

local function __op(name, args, _type)
    local _str = '\n'

    if _type == 'NE' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' != ' .. args
    elseif _type == 'EQ' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' = ' .. args
    elseif _type == 'IS' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' IS ' .. args
    elseif _type == 'NOT' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' NOT ' .. args
    elseif _type == 'OR' then
        local args_count = table.Count(args)
        local i = 1

        for _, v in pairs(args) do
            local val = nice_str(v)
            _str = _str .. '( ' .. '`' .. name .. '`' .. ' = ' .. v .. ' )'

            if i ~= args_count then
                _str = _str .. ' OR '
            end

            i = i + 1
        end
    elseif _type == 'GT' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' > ' .. val
    elseif _type == 'GTE' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' >= ' .. val
    elseif _type == 'LT' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' < ' .. val
    elseif _type == 'LTE' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' >= ' .. val
    elseif _type == 'BETWEEN' then
        local a, b = nice_str(args[1]), nice_str(args[2])
        _str = _str .. '`' .. name .. '`' .. ' BETWEEN ' .. a .. ' AND ' .. b
    elseif _type == 'NOTBETWEEN' then
        local a, b = nice_str(args[1]), nice_str(args[2])
        _str = _str .. '`' .. name .. '`' .. ' NOT BETWEEN ' .. a .. ' AND ' .. b
    elseif _type == 'LIKE' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' LIKE ' .. "'" .. val .. "'"
    elseif _type == 'NOTLIKE' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' NOT LIKE ' .. "'" .. val .. "'"
    elseif _type == 'STARTSWITH' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' LIKE ' .. "'" .. val .. '%' .. "'"
    elseif _type == 'ENDWITH' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' LIKE ' .. "'" .. '%' .. val .. "'"
    elseif _type == 'SUBSTRING' then
        local val = nice_str(args)
        _str = _str .. '`' .. name .. '`' .. ' LIKE ' .. "'" .. '%' .. val .. '%' .. "'"
    end

    return _str
end

local function _op(args, _type)
    local global_i = 1
    local _str = ''
    local noOpCount = 0
    local opCount = 0

    for _, v in pairs(args) do
        if istable(v) and v._op then
            opCount = opCount + 1
        else
            noOpCount = noOpCount + 1
        end
    end

    for key, value in pairs(args) do
        if type(value) == 'table' then
            for _, v in pairs(value) do
                _str = _str .. __op(key, v.args, v._op)
            end
        else
            local val = nice_str(value)
            _str = _str .. '`' .. key .. '`' .. ' = ' .. val
        end

        if (opCount + noOpCount) ~= global_i then
            _str = _str .. ' AND '
        end

        global_i = global_i + 1
    end

    return _str
end

local function where(args)
    local _str = ''
    local where = args
    local opList = {}
    local noOpList = {}

    for k, v in pairs(where) do
        if istable(v) and v._op then
            table.insert(opList, v)
        else
            noOpList[k] = v
        end
    end

    local opListCount = table.Count(opList)
    local noOpListCount = table.Count(noOpList)

    if noOpListCount > 0 then
        _str = _str .. _op(noOpList, 'AND')

        if opListCount > 0 then
            _str = _str .. ' AND \n'
        end
    end

    if opListCount > 0 then
        for _, v in pairs(opList) do
            _str = _str .. _op(v.args, v._op)
        end
    end

    return _str
end

function Table:findAll(args)
    local table_name = self.name
    local find_query = 'SELECT *\n FROM `' .. table_name .. '`\n'
    local where_string = ''

    if args and args.where then
        where_string = where_string .. ' WHERE'
        where_string = where_string .. where(args.where)
    end

    local final_query = find_query

    if where_string then
        final_query = final_query .. where_string
    end

    local promise = kPromise.new()

    ORM.Query(final_query):next(function(data)
        if istable(data) then
            promise:resolve(data)
        else
            promise:reject(false)
        end
    end)

    return promise
end

function Table:select(args, options)
    local table_name = self.name
    local args_count = table.Count(args)
    local args_str = ''

    if args_count < 1 then
        error('[ORM] Trying to select without args', 2)

        return
    end

    local i = 1

    for _, value in pairs(args) do
        args_str = args_str .. ' ' .. '`' .. value .. '`'

        if args_count ~= i then
            args_str = args_str .. ','
        end

        i = i + 1
    end

    local where_string

    if options and options.where then
        local _where = options.where
        where_string = 'WHERE\n'
        where_string = where_string .. where(_where)
    end

    local select_query = 'SELECT' .. args_str .. ' FROM `' .. table_name .. '`\n'
    local final_query = select_query .. where_string
    local promise = kPromise.new()

    ORM.Query(final_query):next(function(data)
        promise:resolve(data)
    end)

    return promise
end

function Table:update(args, options)
    local table_name = self.name
    local update_query = 'UPDATE `' .. table_name .. '` SET\n'
    local args_count = table.Count(args)
    local args_str = ''

    if args_count < 1 then
        error('[ORM] Trying to update a table without args', 2)

        return
    end

    local i = 1

    for name, value in pairs(args) do
        args_str = args_str .. '`' .. name .. '`' .. ' = ' .. "'" .. value .. "'"

        if args_count ~= i then
            args_str = args_str .. ',\n'
        end

        i = i + 1
    end

    local where_string

    if options and options.where then
        local _where = options.where
        where_string = '\nWHERE\n'
        where_string = where_string .. where(_where)
    end

    local final_query = update_query .. args_str .. where_string
    local promise = kPromise.new()

    ORM.Query(final_query):next(function(data)
        promise:resolve(data)
    end)

    return promise
end

function Table:delete(options)
    local table_name = self.name
    local delete_query = 'DELETE FROM `' .. table_name .. '`\n'
    local where_string

    if options and options.where then
        local _where = options.where
        where_string = '\nWHERE\n'
        where_string = where_string .. where(_where)
    end

    local final_query = delete_query .. where_string
    local promise = kPromise.new()

    ORM.Query(final_query):next(function(data)
        promise:resolve(data)
    end)

    return promise
end
