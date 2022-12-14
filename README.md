# wgc-nvim-utils

A lua module with some utils for writing other lua modules or plugins. The are three sub-modules:

 - file_path
 - cache
 - utils

## file_path
Used to build file paths and has some async methods for handling files

### new()
Constructs new file_paths
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two")
local path2 = file_path:new("three.txt")

--equality
local equals = path == path2
--concatentation
path = path + path2 --or path = path..path2 
print tostring(path) --prints /one/two/three.txt

--Note: You cannot concat an absolute path to a relative path
```
### is_absolute()
Returns true is path is absolute
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two")
local var = path:is_absolute() -- var is true here
path = path:new("one/two.txt")
var = path:is_absolute() -- var is false here
```
### name()
Returns file name.
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")
print(path:name()) -- prints 'three.txt'
```
### extension()
Returns file extension
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")
print(path:extension()) -- prints 'txt'
```
### parent()
Return parent file_path.
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")
local parent = path:parent()
print(parent) -- prints '/one/two'
```
### exists(success [, failure])
Async method to check if file exists.
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")

path:exists(function()
 print("Exists")
end,
function()
 print("Does not exist")
end)
```
### is_file(success [, failure])
Async method to check if path is a file
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")

path:is_file(function()
 print("Path is a file")
end,
function()
 print("Path is not a file")
end)
```
### is_directory(success [, failure])
Async method to check if path is a file
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")

path:is_directory(function()
 print("Path is a directory")
end,
function()
 print("Path is not a directory")
end)
```
### read(callback)
Async method to read a file
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("/one/two/three.txt")
path:read(function(data)
  --here data contains contents of file
  print(data)
end)
```
### search_up(name, callback)
Async method to search up from path for a file or folder. Useful for finding things like path to .git or .config. Callback is called with path is name is found otherwise it is called with nil.

Example: Let's say we have folder structure:

```markdown
????????? project
???   ?????????.git
???   ????????? src
???   ???   ????????? main.rs
```
```lua
local file_path=require('wgc-nvim-utils').file_path
local  path = file_path:new("project/src/main.rs")
path:search_up(file_path:new(".git"), function(git_dir)
 --here git_dir will be a file_path for the .git folder
end)
```

## cache()
A very simple in-memory cache utility
### get(key [, callback])
Retrieve value from cache. If key does not exist and callback is provided then callback will be called and result will be cached under key. If callback returns cache_constants.NO_VALUE then
key will be considered to have cached nil for key.
```lua
local cache, cache_constants=require('wgc-nvim-utils').cache()
local my_cache = cache:new()
local function get_key(key)
  return my_cache:get(key, function()
    print "Callback invoked"
    return key == "key" and "val" or cache_constants.NO_VALUE
  end)
end
local v = get_key("key")
-- prints "Callback invoked" and v = "val"
local v1 = get_key("key")
-- does not print "Callback invoked" and v1="val"

local x = get_key("no_key")
-- prints "Callback invoked" and x = nil
local x1 = get_key("no_key")
-- does not print "Callback invoked" and x1 = nil

-- Cache can also be used without callback
local v2 = my_cache:get("key")
-- v3 = "val"

local x2 = my_cache:get("no_key")
-- x2 = cache_contants.NO_VALUE because no_key was cached with NO_VALUE

local x3 = my_cache:get("not_in_cache")
-- x3 = nil
```
### set(key, value)
Caches value with key
```lua
local cache, cache_constants=require('wgc-nvim-utils').cache()
local my_cache = cache:new()
my_cache:set("key", "value")
local v = my_cache:get("key") -- v = "value"
```
### remove(key)
Removes key from cache.
```lua
local cache, cache_constants=require('wgc-nvim-utils').cache()
local my_cache = cache:new()
my_cache:set("key", "value")
local v = my_cache:remove("key") -- v = "value"
v = my_cache:get("key") -- v = nil
```
## utils
Some utils for string, tables and also helpers for nvim options and key mapping.

### string submodule
#### is_empty(str) 
Returns true is str is nil or string.len(str) = 0
#### empty_val(str, val)
Returns str if str is not empty, otherwise returns val

### table submodule
#### append(tb1, ...)
Appends tables to tb1. Returns modified tb1.
```lua
local utils=require('wgc-nvim-utils').utils
local tb1 = {1,2,3}
utils.table.append(tb1,{4,5},{6})
-- tb1 = {1,2,3,4,5,6}

-- Note
-- If you don't want to modify tb1 you can do this
tb1 = {1,2,3}
local tb2 utils.table.append({},tb1,{4,5})
-- Here tb1 = {1,2,3} and tb2 = {1,2,3,4,5}
```
#### pop()
Pops last val from table. Returns popped val and new table with last item removed. Original table is untouched.
```lua
local utils=require('wgc-nvim-utils').utils
local tb1 = {1,2,3}
local popped, tb2 = utils.table.pop(tb1)
-- Here tb1 = {1,2,3}, tb2 = {1,2} and popped = 3
```

#### protect(tbl)
Returns a new table that contains all entries from tbl. New table is unmodifiable.  A good way to make a table of constants.

### Some nvim helpers
#### make_mapper(opts) -> fn(mode,keys,action)
Returns a function to to map keys. The opts passed in are concatenated with {noremap =true} and used as the opts to nvim_set_keymap (or nvim_buf_set_keymap if opts contains buffer = \<bufnr\> ) Note: the buffer entry is removed from opts
```lua
-- Usual way to map keys
vim.api.nvim_set_key_map('n','<leader>u','gUiw',{noremap=true, silent=true})
vim.api.nvim_set_key_map('n','<leader>p','"0p',{noremap=true, silent=true})

--with helper
local utils = require('wgc-nvim-utils').utils
local map = utils.make_mapper({silent=true})

map('n','<leader>u','gUiw')
map('n','<leader>p','"0p')

-- Buffer maps example
local buf_map = utils.make_mapper({silent=true, buffer=0})
--these maps are only for buffer 0
buf_map('n','<leader>u','gUiw')
buf_map('n','<leader>p','"0p')
```
#### options
A simple set of helpers to set, append, prepend or remove nvim options
```lua
local utils = require('wgc-nvim-utils').utils

utils.options.set({
  tabstop = 2,
  softtabstop = 2,
  shiftwidth = 2,  
})

utils.options.append({
  path = {'.','**'},
  wildignore = {'**/debug/**', '**/release/**','**/.git/**'},
})

```

> Written with [StackEdit](https://stackedit.io/).

