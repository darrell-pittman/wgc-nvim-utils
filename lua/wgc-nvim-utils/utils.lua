local M = {}

local unpack = table.unpack or unpack

local protect = function(tbl)
  return setmetatable({}, {
    __index = tbl,
    __newindex = function(t,k,v)
      error(string.format("Attempting to change constant '%s' to %s",k,v))
    end
  })
end

M.constants = protect({
  HOME = vim.env.HOME,
  TRIM = "^[%s%c\n]*(.*[^%s%c\n])[%s%c\n]*$",
})

M.string = {
  is_empty = function(s)
    return (not s) or (string.len(s) == 0)
  end,
  empty_val = function(s,v)
    return M.string.is_empty(s) and v or s
  end,
  trim = function(s)
    return s:match(M.constants.TRIM)
  end,
  split = function(s,r)
    local vals = {}
    for val in string.gmatch(s,r) do
      table.insert(vals, val)
    end
    return vals
  end,
}

local function slice(tbl, start, _end)
  return {unpack(tbl, start,_end)}
end

local function pop(tbl)
  if not tbl then return end
  if #tbl > 0 then
    local popped = tbl[#tbl]
    return popped, slice(tbl,1,#tbl -1)
  end
end

M.table = {
  protect = protect,
  slice = slice,
  pop = pop,
  append = function(tbl1, ...)
    local tbls = {...}
    if tbls and #tbls > 0 then
      local tbl = tbls[1]
      tbls = M.table.slice(tbls, 2,#tbls)
      for _,v in ipairs(tbl) do
        table.insert(tbl1, v)
      end
      tbl1 = M.table.append(tbl1,unpack(tbls))
    end
    return tbl1
  end,
}

M.t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.make_mapper = function(key)
  local options = { noremap = true }

  if key then
    for i,v in pairs(key) do
      if type(i) == 'string' then options[i] = v end
    end
  end

  local buffer = options.buffer
  options.buffer = nil

  local map_fn = buffer and vim.api.nvim_buf_set_keymap or vim.api.nvim_set_keymap

  return function(mode, lhs, rhs)
    local args = {
      mode,
      lhs,
      rhs,
      options,
    }
    if buffer then
      table.insert(args, 1, buffer)
    end
    map_fn(unpack(args))
  end
end

local set_options = function(setter)
  return function(opts)
    for k,v in pairs(opts) do
      setter(k, v)
    end
  end
end

local option_setters = {
  set = function(k,v)
    vim.opt[k] = v
  end,
  append = function(k,v)
    vim.opt[k] = vim.opt[k] + v
  end,
  prepend = function(k,v)
    vim.opt[k] = vim.opt[k] ^ v
  end,
  remove = function (k,v)
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

