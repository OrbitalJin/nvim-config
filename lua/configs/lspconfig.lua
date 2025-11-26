-- nv-lsp.lua (Neovim 0.11+)

-- NVChad helpers (keep using them if you want)
local nv_on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init

-- Capabilities (ex: with nvim-cmp)
local capabilities = (function()
  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end)()

-- 1) Global/buffer LSP-only keymaps and behavior via LspAttach (recommended)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local bufnr = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    -- If you previously used on_attach for keymaps, do them here:
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    map("n", "gd", vim.lsp.buf.definition, "LSP: Go to definition")
    map("n", "gr", vim.lsp.buf.references, "LSP: References")
    map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
    -- Add more as needed.

    -- If you still want NVChad’s on_attach extras, you can invoke them here:
    if type(nv_on_attach) == "function" then
      pcall(nv_on_attach, client, bufnr)
    end
  end,
})

-- 2) Define per-server config with vim.lsp.config
local servers = {
  "cssls",
  "tailwindcss",
  "ts_ls",
  "eslint",
  "pyright",
  "gopls",
  "clangd",
}

-- Optional per-server overrides
local server_opts = {
  ts_ls = {
    -- example: disable formatting if you use external formatters
    on_init = function(client)
      -- keep your own on_init too
      if type(on_init) == "function" then pcall(on_init, client) end
    end,
    on_attach = function(client, bufnr)
      -- keep per-client toggles here (use LspAttach for mappings)
      if client.server_capabilities then
        client.server_capabilities.documentFormattingProvider = false
      end
    end,
  },

  gopls = {
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
        analyses = { unusedparams = true },
      },
    },
  },

  pyright = {
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoImportCompletions = true,
        },
      },
    },
  },

  eslint = {
    settings = {
      workingDirectories = { mode = "auto" },
    },
  },
}

-- Apply a base config for all servers, then merge overrides
for _, name in ipairs(servers) do
  local base = {
    capabilities = capabilities,
    on_init = on_init,
    -- Avoid using on_attach for mappings; use it only for per-client toggles.
  }
  local extra = server_opts[name] or {}
  -- Shallow-merge is fine for most cases; use deep extend if needed
  local opts = vim.tbl_deep_extend("force", base, extra)

  vim.lsp.config(name, opts)
end

-- 3) Arduino language server (bootstrap with cmd)
local MY_FQBN = "rp2040:rp2040:rpipico"
vim.lsp.config("arduino_language_server", {
  cmd = {
    "arduino-language-server",
    "-cli-config",
    "/path/to/arduino-cli.yaml",
    "-fqbn",
    MY_FQBN,
  },
  capabilities = capabilities,
  on_init = on_init,
})

-- 4) Enable all
vim.lsp.enable(servers)
vim.lsp.enable("arduino_language_server")
