local lfs = require("lfs")
local ansicolors = require("libs.ansicolor")

local parent_dir, parent_dir_err = lfs.currentdir()
if not parent_dir then
  error(("Failed to get parent_dir, %s"):format(parent_dir_err))
end

local changed_path, changed_path_err = lfs.chdir("tests")

if not changed_path then
  error(("Failed to changed path to tests directory, %s"):format(changed_path_err))
end

local current_dir, current_dir_err = lfs.currentdir()
if not current_dir then
  error(("Failed to get current_dir, %s"):format(current_dir_err))
end

---@param dir string
---@param failed_tests table
---@return table failed_tests
local function run_tests(dir, failed_tests)
  for file in lfs.dir(dir) do
    if file ~= "." and file ~= ".." then
      local f = dir .. "/" .. file
      local attr = lfs.attributes(f)
      if attr.mode == "directory" then
        lfs.chdir(f)
        run_tests(f, failed_tests)
        lfs.chdir("..")
      else
        local success = os.execute(("LESTER_SHOW_TRACEBACK='false' nelua -L %s --script %s"):format(parent_dir, file))
        if not success then
          table.insert(failed_tests, f:sub(#parent_dir + 1))
        end
      end
    end
  end
  return failed_tests
end

local failed_tests = run_tests(current_dir, {})

print()
if next(failed_tests) then
  for _, failed_test in ipairs(failed_tests) do
    io.stderr:write(("%s Test `%s` failed\n"):format(ansicolors.new("[ERROR]"):Red():tostring(), failed_test))
  end
  os.exit(1)
end

print(("%s All tests passed"):format(ansicolors.new("[SUCCESS]"):Green():tostring()))
