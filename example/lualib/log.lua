local util = require("util")
local c = require("moon_core")
local string_format     = string.format
local string_len        = string.len
local debug_traceback   = debug.traceback
local string_rep        = string.rep
local string_split      = util.string_split
local string_trim       = util.string_trim
local M = {}

---------------------------------------------------------------------------
-- log level
M.LOG_ERROR = 1
M.LOG_WARN = 2
M.LOG_INFO = 3
M.LOG_DEBUG = 4

-- 设置当前日志等级,低于这个等级的日志不会输出
M.LOG_LEVEL = M.LOG_DEBUG

-----------------------------------------------------------------------
function M.throw(fmt, ...)
    local msg
    if #{...} == 0 then
        msg = fmt
    else
        msg = string_format(fmt, ...)
    end
    if M.DEBUG then
        error(msg, 2)
    else
        error(msg, 0)
    end
end

local logV = c.LOGV

local function do_log(bcle,level,fmt, ... )
    local str = string_format(fmt, ...)
    local traceback = string_split(debug_traceback("", 2), "\n")
    logV(bcle, level, table.concat({str,"(",string_trim(traceback[2]),")"}))
end

print = function(...)
    local tb = table.pack(...)
    local len = #tb
    for i=1,len do
        tb[i] = tostring(tb[i])
        -- if tb[i] == nil then
        --     tb[i] = "nil"
        -- else

        -- end
    end
    logV(true, M.LOG_INFO, table.concat(tb,"    "))
end

local print = print

local function _dump_value(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function M.dump(value, desciption, nesting, _print)
    if type(nesting) ~= "number" then nesting = 3 end
    _print = _print or print

    local dumpstr = ""
    local lookup = {}
    local result = {}
    local traceback = string_split(debug_traceback("", 2), "\n")
    dumpstr = "\ndump from: " .. string_trim(traceback[2]).."\n"

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string_rep(" ", keylen - string_len(_dump_value(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1] = string_format("%s%s%s = %s", indent, _dump_value(desciption), spc, _dump_value(value))
        elseif lookup[tostring(value)] then
            result[#result + 1] = string_format("%s%s%s = *REF*", indent, _dump_value(desciption), spc)
        else
            lookup[tostring(value)] = true
            if nest > nesting then
                result[#result + 1] = string_format("%s%s = *MAX NESTING*", indent, _dump_value(desciption))
            else
                result[#result + 1] = string_format("%s%s = {", indent, _dump_value(desciption))
                local indent2 = indent .. "    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _dump_value(k)
                    local vkl = string_len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for _, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = string_format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for _, line in ipairs(result) do
        dumpstr = dumpstr..tostring(line).."\n"
    end

    _print(dumpstr)
end

function M.error(fmt, ...)
    do_log(true, M.LOG_ERROR,fmt,...)
end

function M.warn(fmt, ...)
    do_log(true, M.LOG_WARN,fmt,...)
end

function M.debug(fmt, ...)
    if M.LOG_DEBUG <= M.LOG_LEVEL then
        do_log(false, M.LOG_DEBUG,fmt,...)
    end
end

function M.info(fmt, ...)
    if M.LOG_INFO <= M.LOG_LEVEL then
        do_log(true, M.LOG_INFO,fmt,...)
    end
end

return M
