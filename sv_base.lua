ORM = {}

ORM.DataTypes = {
    STRING = {
        _str = 'varchar'
    },
    TEXT = {
        _str = 'text'
    },
    BOOLEAN = {
        _str = 'BOOLEAN'
    },
    INT = {
        _str = 'int'
    },
    FLOAT = {
        _str = 'float',
    },
    DOUBLE = {
        _str = 'double'
    },
    JSON = {
        _str = 'longtext'
    },
    BLOB = {
        _str = 'blob'
    },
}

ORM.Op = {
        --[[
        Basics
    ]]
    AND = function(args)
        return {
            _op = 'AND',
            args = args
        }
    end,
    OR = function(args)
        return {
            _op = 'OR',
            args = args
        }
    end,
    EQ = function(args)
        return {
            _op = 'EQ',
            args = args
        }
    end,
    NE = function(args)
        return {
            _op = 'NE',
            args = args
        }
    end,
    IS = function(args)
        return {
            _op = 'IS',
            args = args
        }
    end,
    NOT = function(args)
        return {
            _op = 'NOT',
            args = args
        }
    end,
        --[[
        Number comparisons
    ]]
    GT = function(args)
        return {
            _op = 'GT',
            args = args
        }
    end,
    GTE = function(args)
        return {
            _op = 'GTE',
            args = args
        }
    end,
    LT = function(args)
        return {
            _op = 'LT',
            args = args
        }
    end,
    LTE = function(args)
        return {
            _op = 'LTE',
            args = args
        }
    end,
    BETWEEN = function(args)
        return {
            _op = 'BETWEEN',
            args = args
        }
    end,
    NOTBETWEEN = function(args)
        return {
            _op = 'NOTBETWEEN',
            args = args
        }
    end,
        --[[
        Other operators
    ]]
    LIKE = function(args)
        return {
            _op = 'LIKE',
            args = args
        }
    end,
    NOTLIKE = function(args)
        return {
            _op = 'NOTLIKE',
            args = args
        }
    end,
    STARTSWITH = function(args)
        return {
            _op = 'STARTSWITH',
            args = args
        }
    end,
    ENDWITH = function(args)
        return {
            _op = 'ENDWITH',
            args = args
        }
    end,
    SUBSTRING = function(args)
        return {
            _op = 'SUBSTRING',
            args = args
        }
    end,
}

function ORM.Query(str)
    local promise = kPromise.new()

    --print( str )
    MySQLite.query(str, function(data, last)
        local ret = data ~= nil and data or tonumber(last)
        promise:resolve(ret)
    end, function(err)
        print("ORM ERROR: " .. err)
    end)

    return promise
end
