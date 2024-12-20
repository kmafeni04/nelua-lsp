# Editors

## Helix

Folowing Helix's [languages](https://docs.helix-editor.com/languages.html) documentation, you can
use nelua-lsp by adding an entry to the `language-server` table, and be sure that the
`nelua-lsp` value is present on `language-servers` key of the nelua entry of the `language` array:

Here's an example: 

```toml
[[language]]
name = "nelua"
# [...]
language-servers = [ "nelua-lsp" ]

[language-server.nelua-lsp]
command = "nelua"
args = ["-L", "path/to/nelua-lsp", "--script", "path/to/nelua-lsp/main.lua"]
```

## VS code

Using the [vscode-lspconfig](https://marketplace.visualstudio.com/items?itemName=whtsht.vscode-lspconfig), add this to your settings.json

```json
"vscode-lspconfig.serverConfigurations": [
    {
      "name": "nelua",
      "document_selector": [
        {
          "language": "nelua"
        }
      ],
      "command": [
        "nelua",
        "-L",
        "/path/to/nelua-lsp",
        "--script",
        "/path/to/nelua-lsp/main.lua"
      ]
    }
  ]
```
