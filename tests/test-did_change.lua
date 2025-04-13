local did_change = require("methods.did_change")
local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect

describe("did_change tests", function()
  it("Same line", function()
    local content = "local x = 10"
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = #content - 2 },
            ["end"] = { line = 0, character = #content },
          },
          text = "12",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x = 12"
    expect.truthy(new_content == expected)
  end)

  it("Multiple changes", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local content = table.concat({ line1, line2 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = #line1 - 2 },
            ["end"] = { line = 0, character = #line1 },
          },
          text = "12",
        },
        [2] = {
          range = {
            start = { line = 1, character = #line2 - 2 },
            ["end"] = { line = 1, character = #line2 },
          },
          text = "12",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x = 12\nlocal y = 12"
    expect.truthy(new_content == expected)
  end)

  it("Multiple lines and multiple changes", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local line3 = "local z = 14"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = #line1 - 5 },
            ["end"] = { line = 1, character = 0 },
          },
          text = "",
        },
        [2] = {
          range = {
            start = { line = 0, character = #line1 - 5 },
            ["end"] = { line = 0, character = #line1 - 5 + #line2 },
          },
          text = "",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x\nlocal z = 14"
    expect.truthy(new_content == expected)
  end)

  it("Multiple lines", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local line3 = "local z = 14"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = #line1 - 5 },
            ["end"] = { line = 2, character = #line3 },
          },
          text = "",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x"
    expect.truthy(new_content == expected)
  end)

  it("Multiple lines", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local line3 = "local z = 14"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = 0 },
            ["end"] = { line = 2, character = #line3 },
          },
          text = "",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = ""
    expect.truthy(new_content == expected)
  end)

  it("Insert at the beginning", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local content = table.concat({ line1, line2 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = 0 },
            ["end"] = { line = 0, character = 0 },
          },
          text = "-- inserted comment\n",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "-- inserted comment\nlocal x = 10\nlocal y = 12"
    expect.truthy(new_content == expected)
  end)

  it("Change at EOL", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local content = table.concat({ line1, line2 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 1, character = 10 },
            ["end"] = { line = 1, character = 11 },
          },
          text = "99",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x = 10\nlocal y = 99"
    expect.truthy(new_content == expected)
  end)

  it("Insertion inbetween lines", function()
    local line1 = "local x = 10"
    local line2 = "local y = 12"
    local line3 = "local z = 14"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 1, character = 0 },
            ["end"] = { line = 1, character = 0 },
          },
          text = "-- new line\n",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "local x = 10\n-- new line\nlocal y = 12\nlocal z = 14"
    expect.truthy(new_content == expected)
  end)

  it("Multiline", function()
    local line1 = "print('one')"
    local line2 = "print('two')"
    local line3 = "print('three')"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = 7 },
            ["end"] = { line = 2, character = 11 },
          },
          text = "1')\nprint('2')\nprint('3",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "print('1')\nprint('2')\nprint('3')"
    expect.truthy(new_content == expected)
  end)

  it("Multi-cursor", function()
    local line1 = "print('one')"
    local line2 = "print('two')"
    local line3 = "print('three')"
    local content = table.concat({ line1, line2, line3 }, "\n")
    local request_params = {
      contentChanges = {
        [1] = {
          range = {
            start = { line = 0, character = 7 },
            ["end"] = { line = 0, character = 9 },
          },
          text = "1",
        },
        [2] = {
          range = {
            start = { line = 1, character = 7 },
            ["end"] = { line = 1, character = 9 },
          },
          text = "2",
        },
        [3] = {
          range = {
            start = { line = 2, character = 7 },
            ["end"] = { line = 2, character = 11 },
          },
          text = "3",
        },
      },
    }
    local new_content = did_change(request_params, content)
    local expected = "print('1')\nprint('2')\nprint('3')"
    expect.truthy(new_content == expected)
  end)
end)
lester.report()
lester.exit()
