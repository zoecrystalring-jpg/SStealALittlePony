--!strict
local DataTypes = require(script.Parent.DataTypes)
local Validate = require(script.Parent.Validate)
type ErrorResult = DataTypes.ErrorResult

local ErrorCodes = {}
ErrorCodes.Codes = table.freeze({
    SUCCESS = 0,
    UNKNOWN_ERROR = 1000,
    INVALID_PARAMETER = 1001,
    PERMISSION_DENIED = 1002,
    OPERATION_TIMEOUT = 1003,
    SERVICE_UNAVAILABLE = 1004,
    INTERNAL_ERROR = 1005,
})

ErrorCodes.Messages = table.freeze({
    [0] = "操作成功",
    [1000] = "未知错误",
    [1001] = "无效参数",
    [1002] = "权限不足",
    [1003] = "操作超时",
    [1004] = "服务不可用",
    [1005] = "服务器内部错误",
})

function ErrorCodes.getMessage(code: number): string
    if not Validate.args("ErrorCodes.getMessage", {
        { name = "code", value = code, expected = "number", integer = true },
    }) then
        return ErrorCodes.Messages[1000]
    end
    return ErrorCodes.Messages[code] or ErrorCodes.Messages[1000]
end

function ErrorCodes.result(code: number, data: any?): ErrorResult
    if not Validate.args("ErrorCodes.result", {
        { name = "code", value = code, expected = "number", integer = true },
    }) then
        return { code = ErrorCodes.Codes.INVALID_PARAMETER }
    end
    return { code = code, data = data }
end

return table.freeze(ErrorCodes)
