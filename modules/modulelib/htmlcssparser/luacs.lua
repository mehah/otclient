local parser = {}
parser.__index = parser

parser.new = function()
  parser.imports = {}
  parser.objects = {
    type = "cssroot",
    children = {}
  }
  parser.strings = {}
  return setmetatable({}, parser)
end

-- what to get the correct result
-- call parser:parse on all input names
-- check for imported files using parser:get_imports
-- recursively load all imported files until you get no more imports
-- load imported files using parser:import
function parser:parse(text, filename)
  -- parse the CSS text
  self.text = text
  -- list of imported CSS files
  self:parse_blocks()
  return self.cssom
end

function parser:get_imports()
  -- get list of imported CSS files. each of them should be parsed by a separate parser and imported using parser:import()
  local imports = {}
  for filename, _ in pairs(self.imports) do
    imports[#imports + 1] = filename
  end
  return imports
end

--- Import CSS declarations from another file
-- The CSS file should be another instacte of the CSS parser
function parser:import(filename, CSS)
  self.imports[filename] = CSS:get_objects()
end

function parser:get_objects()
  return self.objects
end

function parser:parse_blocks()
  -- for efficiency
  local objects = self.objects
  -- first parse "" and '' strings
  self.text = self:parse_strings(self.text)
  -- then delete comments
  self.text = self:delete_comments(self.text)
  local newobjects = self:parse_statements(self.text)
  for _, obj in ipairs(newobjects) do
    table.insert(objects, obj)
  end
end

function parser:parse_strings(text)
  -- delete strings from the CSS in order to safely remove the comments
  -- strings will be saved to a table, where they will be retrieved lately
  local function replace_string(s)
    local count = #self.strings + 1
    -- save the string and remove the quotations
    self.strings[count] = s:sub(2, -2)
    return "%%" .. count
  end
  local text = text:gsub("(%b'')", replace_string)
  text = text:gsub('(%b"")', replace_string)
  return text
end

function parser:delete_comments(text)
  return text:gsub("/%*.-%*/", " ")
end

function parser:parse_statements(text)
  local pos = 0
  local objects = {}
  local startpos, obj, at
  while pos do
    -- find start of the next statement and detect whether it is an at-rule
    startpos, pos, at = string.find(text, "(@?)%w+", pos + 1)
    if startpos then
      -- these parse commands should parse next statement and return object representing it and
      -- the end position of the statement in the parsed text
      if at == "@" then
        obj, pos = self:parse_at_rule(text, startpos - 1)
      else
        obj, pos = self:parse_rule(text, startpos - 1)
      end
      table.insert(objects, obj)
    end
  end
  return objects
end

function parser:parse_at_rule(text, startpos)
  -- detect if the statement contains block or is ended just by semicolon
  local _, _, brace_or_semicolon = string.find(text, "([;{])", startpos)
  if brace_or_semicolon == ";" then
    local startpos, pos, statement = string.find(text, "(.-);", startpos)
    return { type = "at_statement", statement = statement }, pos
  else
    local startpos, pos, statement, block = string.find(text, "(.-)(%b{})", startpos)
    return { type = "at_statement", statement = statement, block = block }, pos
  end
end

function parser:parse_rule(text, startpos)
  local startpos, pos, selector, block = string.find(text, "(.-)(%b{})", startpos)
  local obj = {
    type = "rule",
    selector = self:parse_selector(selector),
    declarations = self:parse_declarations(block:sub(2, -2)) -- remove the brackets using string.sub
  }
  return obj, pos
end

function parser:parse_selector(selector)
  return selector
end

function parser:parse_declarations(declarations)
  local rules = string.explode(declarations, ";")
  local properties = {}
  for _, rule in ipairs(rules) do
    local property, value = rule:match("%s*(.+)%s*:%s*(.+)%s*")
    if property then
      properties[property] = value
    end
  end
  return properties
end

CssParse = parser
