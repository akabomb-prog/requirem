--
-- requirem.lua
--
-- Written by [aka]bomb, 2022
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local REQUIREM_BEGIN = [[local _REQUIREM_MODULES={}]]
local MODULE_BEGIN = [[_REQUIREM_MODULES["%s"]=function()]]
local MODULE_END = "\nend "
local REQUIREM_END = [[_REQUIREM_REQUIRE=require require=function(module,...)if _REQUIREM_MODULES[module]~=nil then return _REQUIREM_MODULES[module]()else return _REQUIREM_REQUIRE(...)end end
]]

local function printfln(f,...)print(f:format(...))end
local function errorf(f,...)error(f:format(...))end

local function rmain(mainf, libs)
    local outfile = mainf:match("[^/\\]+$")
    if not outfile then
        error("could not construct outfile string!")
    end
    outfile = "requirem_" .. outfile

    -- open main file
    local fmainf = io.open(mainf, 'r')
    if not fmainf then
        errorf("could not open file '%s' for reading, abort", mainf)
    end

    -- open output file
    local foutf = io.open(outfile, 'w')
    if not foutf then
        fmainf:close()
        errorf("could not open file '%s' for writing, abort", outfile)
    end

    -- now that we have everything, print banner and info
    -- print("+---------------------------------+")
    print("requirem v1.0\n")
    printfln("main file: '%s'\noutput file: '%s'", mainf, outfile)

    print("included files:")
    for i = 1, #libs do
        printfln("\t%s", libs[i])
    end
    print()
    -- print("+---------------------------------+")

    -- track time
    local time = os.clock
    local tstart = time()

    foutf:write(REQUIREM_BEGIN)

    -- open libraries
    local sz = #libs
    for i = 1, sz do
        local f = io.open(libs[i], 'r')
        if not f then
            io.stderr:write(("could not open file '%s' for reading, continuing"):format(fname), '\n')
        else
            local modname = libs[i]:gsub("%.[/\\]", ''):gsub("%.%w+$", ''):gsub("[/\\]", '.')
            printfln("reading module '%s'", modname)
            foutf:write(MODULE_BEGIN:format(modname))
            foutf:write(f:read('a'))
            foutf:write(MODULE_END)
            f:close()
        end
    end

    foutf:write(REQUIREM_END)

    -- write main file
    foutf:write(fmainf:read('a'))

    -- everything's done, print time taken
    -- print("+---------------------------------+")
    printfln("\ndone, written %d bytes in %s", foutf:seek(), time() - tstart)
    -- print("+---------------------------------+")

    -- close files
    fmainf:close()
    foutf:close()
end

local usagef = "usage: %s [--help] <main.lua> <lib1.lua> [lib2.lua...]"

local function main(args)
    if #args == 0 then
        errorf(usagef, args[0])
    end
    
    local mainf, libs = nil, {}

    -- read arguments
    local i = 1
    while args[i] do
        if args[i] == "--help" then
            printfln(usagef, args[0])
            return 0
        elseif i > 1 then
            libs[#libs + 1] = args[i]
        elseif i == 1 then
            mainf = args[i]
        end
        i = i + 1
    end

    if #libs == 0 then
        error("no libraries specified")
    end

    return rmain(mainf, libs)
end

-- run main
local ok, result = pcall(main, arg)
if not ok and type(result) == "string" then
    io.stderr:write(result, '\n')
    os.exit(1)
end
os.exit(result)
