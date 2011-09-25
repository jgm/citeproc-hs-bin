-- test citeproc + lunamark

local json = require("json")
local lunamark = require("lunamark")

-- runs cmd on file containing inp and returns result
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " < " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end


local cites =
{ { { id = "item1", suffix = "passim" }
  , { id = "item2", prefix = {'see also'}, author_in_text = false}
  }
, { { id = "item3", author_in_text = true, locator = "15", label = "page" } }
}

local jsoncites = json.encode(cites)
local jsonout = pipe("./citeproc chicago-author-date.csl biblio.bib", jsoncites)
local out = json.decode(jsonout)

local function write(writer,t)
  local buffer = {}
  local function add(x)
    buffer[#buffer + 1] = x
  end
  for _,v in ipairs(t) do
    if v == " " then
      add(writer.space)
    elseif type(v) == "string" then
      add(writer.string(v))
    else -- table
      local ty = v[1]
      if ty == "EMPH" then
        add(writer.emphasis(v[2]))
      elseif ty == "STRONG" then
        add(writer.strong(v[2]))
      else -- unrecognized or not handled by writer
        add(v[2] or v[1])
      end
    end
  end
  return lunamark.util.rope_to_string(buffer)
end

local html = lunamark.writer.html.new()
local latex = lunamark.writer.latex.new()
for i,cite in ipairs(out.citations) do
  io.write(tostring(i), '. ', write(latex,cite), '\n')
end
for i,cite in ipairs(out.bibliography) do
  io.write(tostring(i), '. ', write(latex,cite), '\n')
end

