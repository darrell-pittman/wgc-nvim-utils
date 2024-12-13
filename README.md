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
├── project
│   ├──.git
│   ├── src
│   │   ├── main.rs
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
Also has a func submodule which has useful functions

### func submodule
#### fold_left(f, acc, list)
Accepts a function f(acc, entry) which takes in acc and entry from the list and
returns a new value for acc.

fold_left iterates over list and calls acc = f(acc, entry) for each item in 
list and returns acc when finished;

Example:

```lua
local func = require('wgc-nvim-utils').utils.func
local function sum(...)
  local f = function(acc, n)
    return acc + n
  end
  return func.fold_left(f, 0, {...})
end

local x = sum(1,4,7)
print(x) -- prints 12
```

### string submodule
#### is_empty(str) 
Returns true is str is nil or string.len(str) = 0
#### empty_val(str, val)
Returns str if str is not empty, otherwise returns val

### table submodule
#### append(...)
Accepts varargs of array-like tables and
non-destructively appends them tables together
```lua
local utils=require('wgc-nvim-utils').utils
t = utils.table.append({1,2,3},{4,5},{6})
-- t = {1,2,3,4,5,6}
```
#### merge(...)
Accepts varargs of map-like tables and
non-destructively merges them tables together

Note: 
  Values in later tables overwrite values in previous
  tables.

```lua
local utils=require('wgc-nvim-utils').utils
t = utils.table.merge({one = 1, two = 2}, { two = 'two', three = 3} )
-- t = {one = 1, two = 'two', three = 3}
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
Returns a function to to map keys with default opts.
```lua
-- Usual way to map keys
vim.keymap.set('n','<leader>u','gUiw',{noremap=true, silent=true, desc = 'desc 1'})
vim.keymap.set('n','<leader>p','"0p',{noremap=true, silent=true, desc = 'desc 2'})

--with helper
local utils = require('wgc-nvim-utils').utils
local map = utils.make_mapper({noremap = true, silent=true})

-- Note: any option set here will override any options passed to make_mapper.
map('n','<leader>u','gUiw', {desc = 'desc 1'})
map('n','<leader>p','"0p'), {desc = 'desc 2'})

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

