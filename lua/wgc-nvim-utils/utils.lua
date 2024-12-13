local M = {}

local _iter

local protect = function(tbl)
  return setmetatable({}, {
    __index = tbl,
    __newindex = function(_, k, v)
      error(string.format("Attempting to change constant '%s' to %s", k, v))
    end,
    __metatable = 'Not Allowed',
  })
end

_iter = function(f, tbl1, ...)
  tbl1 = tbl1 or {}
  local tbls = { ... }
  if not tbls or #tbls == 0 then
    return tbl1
  end
  local tbl = tbls[1]
  tbls = vim.list_slice(tbls, 2, #tbls)
  tbl1 = f(tbl1, tbl)
  return _iter(f, tbl1, unpack(tbls))
end

M.constants = protect({
  HOME = vim.env.HOME,
})

M.string = {
  center = function(str, width)
    local padding = math.floor((width - string.len(str)) / 2)
    return M.string.pad(str, padding)
  end,
  pad = function(str, n)
    return string.rep(' ', n) .. str
  end,
  is_empty = function(s)
    return (not s) or (string.len(s) == 0)
  end,
  is_not_empty = function(s)
    return not M.string.is_empty(s)
  end,
  empty_val = function(s, v)
    return M.string.is_empty(s) and v or s
  end,
}

local function pop(tbl)
  if not tbl then return end
  if #tbl > 0 then
    local popped = tbl[#tbl]
    return popped, vim.list_slice(tbl, 1, #tbl - 1)
  end
end

M.table = {
  protect = protect,
  pop = pop,

  is_array = function(tbl)
    local i = 0
    for _ in pairs(tbl) do
      i = i + 1
      if tbl[i] == nil then
        return false
      end
    end
    return true
  end,

  append = function(...)
    local f = function(dest, src)
      for _, v in ipairs(src) do
        table.insert(dest, v)
      end
      return dest
    end
    return _iter(f, {}, ...)
  end,

  merge = function(...)
    local f = function(dest, src)
      for k, v in pairs(src) do
        dest[k] = v
      end
      return dest
    end
    return _iter(f, {}, ...)
  end
}

M.t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.make_mapper = function(defaults)
  defaults = defaults or {}

  return function(mode, lhs, rhs, opts)
    opts = opts or {}
    vim.keymap.set(mode, lhs, rhs, M.table.merge(defaults, opts))
  end
end

local set_options = function(setter)
  return function(opts)
    for k, v in pairs(opts) do
      setter(k, v)
    end
  end
end

local option_setters = {
  set = function(k, v)
    vim.opt[k] = v
  end,
  append = function(k, v)
    vim.opt[k] = vim.opt[k] + v
  end,
  prepend = function(k, v)
    vim.opt[k] = vim.opt[k] ^ v
  end,
  remove = function(k, v)
    vim.opt[k] = vim.opt[k] - v
  end,
}

M.options = {
  set = set_options(option_setters.set),
  append = set_options(option_setters.append),
  prepend = set_options(option_setters.prepend),
  remove = set_options(option_setters.remove),
}

return M
