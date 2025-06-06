-- parse arguments
local arg = {...}
local opt_y = false
local opt_id
local opt_title
local opt_region
local opt_raphnet
local opt_disable_controller_remappings
local opt_wad
while arg[1] do
  if arg[1] == "-y" then
    opt_y = true
    table.remove(arg, 1)
  elseif arg[1] == "-i" or arg[1] == "--channelid" then
    opt_id = arg[2]
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "-t" or arg[1] == "--channeltitle" then
    opt_title = arg[2]
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "-r" or arg[1] == "--region" then
    opt_region = arg[2]
    table.remove(arg, 1)
    table.remove(arg, 1)
  elseif arg[1] == "--raphnet" then
    opt_raphnet = true
    table.remove(arg, 1)
  elseif arg[1] == "--disable-controller-remappings" then
    opt_disable_controller_remappings = true
    table.remove(arg, 1)
  elseif arg[1] == "-w" then
    opt_wad = arg[2]
    table.remove(arg, 1)
    table.remove(arg, 1)
  else
    break
  end
end

function quit(code)
  if not opt_y then
    print("press enter to continue")
    io.read()
  end
  os.exit(code)
end

if #arg < 1 then
  print("usage: \n"
        .. "  `patch-wad [-y] [<gzinject-arg>...] <wad-file>...`\n"
        .. "  `patch-wad [-y] [<gzinject-arg>...] -w <wad-file>"
        .. " <rom-file>...`\n(or drag and drop a wad onto the patch script)")
  if opt_y then return 0 end
  local line = io.read()
  if line ~= nil and line:sub(1, 1) == "\"" and line:sub(-1, -1) == "\"" then
    line = line:sub(2, -2)
  end
  if line == nil or line == "" then return end
  arg[1] = line
end

local gzinject = os.getenv("GZINJECT")
if gzinject == nil or gzinject == "" then
  gzinject = "gzinject"
end

wiivc = true
require("lua/rom_table")

local n_patched = 0
for i = 1, #arg do
  local input_rom
  local input_wad
  if opt_wad ~= nil then
    input_rom = arg[i]
    input_wad = opt_wad
    io.write("making patched wad from `" .. input_wad .. "` with `"
             .. input_rom .. "`...")
  else
    input_rom = "wadextract/content5/rom"
    input_wad = arg[i]
    io.write("making patched wad from `" .. input_wad .. "`...")
  end
  -- extract wad
  gru.os_rm("wadextract")
  local _,_,gzinject_result = os.execute(gzinject ..
                                         " -a extract" ..
                                         " -k common-key.bin" ..
                                         " -d wadextract" ..
                                         " -w \"" .. input_wad .. "\"")
  if gzinject_result ~= 0 then
    print(" unpacking failed")
    quit(1)
  end
  -- check rom id
  local rom = gru.n64rom_load(input_rom)
  local rom_info = rom_table[rom:crc32()]
  if rom_info == nil then
    print(" unrecognized rom, skipping")
  else
    -- patch rom
    local patch = gru.ups_load("ups/" .. rom_info.gz_name .. ".ups")
    patch:apply(rom)
    rom:save_file("wadextract/content5/rom")
    -- build gzinject pack command string
    local gzinject_cmd = gzinject ..
                         " -a pack" ..
                         " -k common-key.bin" ..
                         " -d wadextract"
    if opt_id then
      gzinject_cmd = gzinject_cmd .. " -i \"" .. opt_id .. "\""
    else
      gzinject_cmd = gzinject_cmd .. " -i " .. rom_info.title_id
    end
    if opt_title then
      gzinject_cmd = gzinject_cmd .. " -w \"" .. opt_title .. ".wad\""
      gzinject_cmd = gzinject_cmd .. " -t \"" .. opt_title .. "\""
    else
      gzinject_cmd = gzinject_cmd .. " -w " .. rom_info.gz_name .. ".wad"
      gzinject_cmd = gzinject_cmd .. " -t " .. rom_info.gz_name
    end
    if opt_region then
      gzinject_cmd = gzinject_cmd .. " -r \"" .. opt_region .. "\""
    else
      gzinject_cmd = gzinject_cmd .. " -r 3"
    end
    if opt_disable_controller_remappings then
      gzinject_cmd = gzinject_cmd .. " -p gzi/gz_noremap.gzi"
    elseif opt_raphnet then
      gzinject_cmd = gzinject_cmd .. " -p gzi/gz_raphnet.gzi"
    else
      gzinject_cmd = gzinject_cmd .. " -p gzi/gz.gzi"
    end
    -- execute
    local _,_,gzinject_result = os.execute(gzinject_cmd)
    if gzinject_result ~= 0 then
      print(" packing failed")
      quit(1)
    end
    n_patched = n_patched + 1
    print(" done, saved as " .. rom_info.gz_name .. ".wad")
  end
end

if n_patched == 0 then
  print("no wads were patched")
elseif n_patched == 1 then
  print(n_patched .. " wad was patched")
else
  print(n_patched .. " wads were patched")
end

quit(0)
