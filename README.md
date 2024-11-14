# Nelua LSP

This is an early implementation of writing an LSP server the for [nelua](https://nelua.io) programming language

## Note
I've only tested this on my machine running arch linux and I'm pretty sure it currently won't work correctly on windows. Please report errors when you discover and if possible help me get it working on windows

## Goals

- [x] Go to Definition
- [x] Hover
- [x] Diagnostics
- [x] Completions (partial)
  - TODO:
    - Completions for dot indexes, methods and types

## Dependencies
- [nelua](https://nelua.io)
- [git](https://git-scm.com): Required for go to definition on `require` paths

## How to Run
```sh
  nelua -L /path/to/nelua-lsp --script /path/to/nelua-lsp/main.lua
```
