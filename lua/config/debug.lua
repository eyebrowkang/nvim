local M = {}

function M.simpleLog(message)
    local file_path = os.getenv("HOME") .. "/.config/nvim/log" -- 指定日志文件路径
    local file = io.open(file_path, "a") -- 以追加模式打开文件
    if not file then
        vim.notify("无法打开日志文件: " .. file_path, vim.log.levels.ERROR)
        return
    end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- 获取当前时间，格式为YYYY-MM-DD HH:MM:SS
    file:write(string.format("[%s] %s\n", timestamp, message)) -- 写入消息
    file:close() -- 关闭文件
end

return M
