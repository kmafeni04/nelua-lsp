local ansicolors = {
  Reset = 0,
  Clear = 0,
  Default = 0,
  Bright = 1,
  Dim = 2,
  Underscore = 4,
  Blink = 5,
  Reverse = 7,
  Hidden = 8,

  Black = 30,
  Red = 31,
  Green = 32,
  Yellow = 33,
  Blue = 34,
  Magenta = 35,
  Cyan = 36,
  White = 37,

  OnBlack = 40,
  OnRed = 41,
  OnGreen = 42,
  OnYellow = 43,
  OnBlue = 44,
  OnMagenta = 45,
  OnCyan = 46,
  OnWhite = 4,
}

---@alias ColorFunc fun(self: AnsiColor): AnsiColor

---@class AnsiColor
---@field data string
---@field Reset ColorFunc
---@field Clear ColorFunc
---@field Default ColorFunc
---@field Bright ColorFunc
---@field Dim ColorFunc
---@field Underscore ColorFunc
---@field Blink ColorFunc
---@field Reverse ColorFunc
---@field Hidden ColorFunc
---@field Black ColorFunc
---@field Red ColorFunc
---@field Green ColorFunc
---@field Yellow ColorFunc
---@field Blue ColorFunc
---@field Magenta ColorFunc
---@field Cyan ColorFunc
---@field White ColorFunc
---@field OnBlack ColorFunc
---@field OnRed ColorFunc
---@field OnGreen ColorFunc
---@field OnYellow ColorFunc
---@field OnBlue ColorFunc
---@field OnMagenta ColorFunc
---@field OnCyan ColorFunc
---@field OnWhite ColorFunc
local AnsiColor = {}

---@param str string
---@return AnsiColor
function AnsiColor.new(str)
  for color, code in pairs(ansicolors) do
    ---@param self AnsiColor
    ---@return AnsiColor
    AnsiColor[color] = function(self)
      self.data = "\27[" .. code .. "m" .. self.data .. "\27[0m"
      return self
    end
  end
  local ansi_color = {}
  for k, v in pairs(AnsiColor) do
    ansi_color[k] = v
  end
  ansi_color.data = str
  return ansi_color
end

function AnsiColor:tostring()
  return self.data
end

return AnsiColor
