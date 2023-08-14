Column = {}
Column.__index = Column

local confings_WhiteList = {
    ['max_length'] = true,
    ['unique'] = true,
    ['null'] = true,
    ['default'] = true,
    ['primary_key'] = true,
    ['escape_value'] = true,
    ['auto_increment'] = true
}

setmetatable(Column, {
    __call = function(self, name, type, configs)
        local tbl = {
            name = name,
            type = type,
            configs = configs
        }

        if not name then
            error('[ORM] Trying to create a column without a name', 2)

            return
        end

        if not type._str then
            error('[ORM] Trying to create a column with invalid type', 2)

            return
        end

        if configs then
            for name, _ in pairs(configs) do
                if not confings_WhiteList[name] then
                    error('[ORM] Trying to create a column with a non-existent config: "' .. name .. '"', 2)

                    return
                end
            end
        end

        return setmetatable(tbl, Column)
    end
})

function Column:generateQueryString()
    local str = ''
    local name = self.name
    local configs = self.configs
    local _type = self.type
    local primary

    if name then
        str = str .. '`' .. name .. '`'
    end

    if _type then
        str = str .. ' ' .. _type._str

        if _type == ORM.DataTypes.JSON then
            str = str .. ' ' .. 'CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`' .. name .. '`))'
        end
    end

    if configs ~= nil then
        if configs.max_length then
            str = str .. '(' .. configs.max_length .. ')'
        end

        if configs.primary_key then
            primary = name
        end

        if configs.unique then
            str = str .. ' UNIQUE'
        end

        if configs.default then
            str = str .. ' DEFAULT ' .. configs.default
        end
    end

    if configs ~= nil and configs.auto_increment then
        str = str .. ' AUTO_INCREMENT'
    end

    if _type._str ~= 'longtext' then
        str = str .. (configs and configs.null and ' NULL' or ' NOT NULL')
    end

    return {
        str = str,
        primary = primary
    }
end
