-- tools/emerald_convert.lua
-- Simple, safe extractor to convert key tables from a local pokeemerald checkout into Lua tables
-- Usage: lua tools/emerald_convert.lua /path/to/pokeemerald /path/to/output_dir

local lfs = require('lfs')
local input_root = arg[1]
local out_root = arg[2]
if not input_root or not out_root then
  print("Usage: lua tools/emerald_convert.lua /path/to/pokeemerald /path/to/output_dir")
  os.exit(1)
end

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local c = f:read('*a')
  f:close()
  return c
end

local function write_file(path, contents)
  local dir = path:match('(.+)/[^/]+$')
  if dir then
    lfs.mkdir(dir)
  end
  local f = io.open(path, 'wb')
  f:write(contents)
  f:close()
end

-- Very conservative text extraction: pulls C arrays and constants and converts to Lua tables.
local function extract_array(csrc, array_name)
  -- finds "<type> array_name[] = { ... };" style blocks
  local pat = array_name:gsub('%-','%%-')
  local s, e = csrc:find(array_name)
  if not s then return nil end
  -- find nearest opening brace before semicolon
  local brace_s = csrc:find('{', s)
  local brace_e = csrc:find('}', brace_s)
  if not brace_s or not brace_e then return nil end
  local body = csrc:sub(brace_s+1, brace_e-1)
  return body
end

-- Example: convert a tiny species_info snippet and write a Lua file. For proper parity you will need
-- to run this on the full pokeemerald repo and extend the patterns below to the various headers/data files.

-- Convert sample species_info.h (fallback safe extraction)
local species_info_path = input_root .. '/src/data/pokemon/species_info.h'
local species_info_src = read_file(species_info_path)
if species_info_src then
  -- This is a heuristic: capture lines like "{BASE_HP, BASE_ATK, ...}, // SPECIES_X"
  local out = {}
  for line in species_info_src:gmatch('[^\n]+') do
    local entry = line:match('{([^}]+)}%s*,%s*//%s*SPECIES_(%w+)')
    if entry then
      local name = line:match('//%s*SPECIES_(%w+)')
      if name then
        table.insert(out, string.format('  ["%s"] = {%s},', name, entry))
      end
    end
  end
  if #out > 0 then
    local lua = 'return {\n' .. table.concat(out, '\n') .. '\n}\n'
    write_file(out_root .. '/data/emerald_species.lua', lua)
    print('Wrote data/emerald_species.lua (sample)')
  else
    print('species_info.h parsed but no entries matched the safe heuristic; extend the script for your exact input format')
  end
else
  print('species_info.h not found at ' .. species_info_path .. ' — ensure you passed the correct pokeemerald path')
end

print('\nNotes:\n- This script is intentionally conservative and safe: it uses text patterns and will not run or link any build steps.\n- For full parity, run the script on the full pokeemerald repo and extend extraction rules for level-up learnsets, moves, types, cries and palettes.\n- See README in repo for recommended extraction and asset conversion commands.')
