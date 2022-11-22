local utils = require('wgc-nvim-utils.utils')

local constants = utils.table.protect {
  SEP = package.config:sub(1,1),
  DIR_TYPE = "directory",
  FILE_TYPE = "file",
}

local M = {}

M.__index = M

M.__eq = function(fp1, fp2)
  return tostring(fp1) == tostring(fp2)
end

local regexes = utils.table.protect {
  ROOTS = {
    constants.SEP == "/" and ("^(%s)"):format(constants.SEP) or ("^([A-Za-z]:%s)"):format(constants.SEP),
    constants.SEP == "\\" and ("^(%s%s)"):format(constants.SEP, constants.SEP),
  },
  EXTENSION = "^%.*.*%.([^%s]+)$",
}

local function verify(...)
  local verified = ... and true
  for _,fp in ipairs{...} do
    verified = verified and getmetatable(fp) == M
  end
  return verified
end

local function concat(fp1, fp2)
  if verify(fp1, fp2) then
    if fp2:is_absolute() then
      error("fp2 must be relative")
    end
    return M:new(utils.table.append({},fp1.path,fp2.path), fp1.root)
  else
    error("Error: file_path can only concat another file_path")
  end
end

M.__tostring = function(fp)
  return (fp.root or "")..table.concat(fp.path, constants.SEP)
end

M.__add = concat

M.__concat = concat

local function parse_root(str_path)
  local root
  for _,regex in ipairs(regexes.ROOTS) do
    if regex then
      root = str_path:match(regex)
    end
    if root then break end
  end
  return root
end

function M:is_absolute()
  return self.root and true
end

function M:new(path, root)
  local path_type = type(path)

  if path_type == "table" then
    if verify(path) then
      root = path.root
      path = path.path
    end
  elseif path_type == "string" then
    --trim whitespace
    path = vim.trim(path)

    --trim trailing /
    while path and vim.endswith(path, constants.SEP) do
      path = path:sub(1, #path - 1)
    end

    root = parse_root(path)
    if root then
      path = path:sub(#root + 1, #path)
    end
    path = vim.split(path, constants.SEP)
  else
    error("Invalid path")
  end

  return setmetatable({path = path, root = root},self)
end

function M:parent()
  local _, parent = utils.table.pop(self.path)
  if parent then
    return M:new(parent, self.root)
  end
end

function M:name()
  if #self.path > 0 then
    return M:new(self.path[#self.path])
  end
end

function M:extension()
  local name = self:name()
  if name then
    return string.match(tostring(name), regexes.EXTENSION)
  end
end

function M:exists(success, failure)
  vim.loop.fs_stat(tostring(self), function(err, stat)
    local ok = not err and stat
    if ok then
      success(stat)
    else
      if failure then failure(err) end
    end
  end)
end

function M:is_directory(success, failure)
  self:exists(function(stat)
    if stat.type == constants.DIR_TYPE then
      success()
    else
      if failure then failure() end
    end
  end,
  failure)
end

function M:is_file(success, failure)
  self:exists(function(stat)
    if stat.type == constants.FILE_TYPE then
      success()
    else
      if failure then failure() end
    end
  end,
  failure)
end

function M:search_up(name, callback)
  self:exists(function()
    local needle = self..name
    needle:exists(function()
      callback(needle)
    end,
    function()
      local path = self:parent()
      if path then
        path:search_up(name, callback)
      else
        callback()
      end
    end)
  end)
end

function M:read(callback)
  vim.loop.fs_open(tostring(self), "r", 438, function(err, fd)
    assert(not err, err)
    vim.loop.fs_fstat(fd, function(err, stat)
      assert(not err, err)
      vim.loop.fs_read(fd, stat.size, 0, function(err, data)
        assert(not err, err)
        vim.loop.fs_close(fd, function(err)
          assert(not err, err)
          callback(data)
        end)
      end)
    end)
  end)
end

return M

