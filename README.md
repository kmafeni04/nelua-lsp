# Nelua LSP

This is an early implementation of writing an LSP server the for [nelua](https://nelua.io) programming language

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
  nelua -L /path/to/nelua-lsp /path/to/nelua-lsp/main.lua
```
