-- Copyright 2026 Joe Blubaugh
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Beads plugin entry point
-- This file is loaded automatically by Neovim

if vim.fn.has("nvim-0.5") == 0 then
  vim.notify("beads requires Neovim >= 0.5", vim.log.levels.ERROR)
  return
end

-- Avoid loading the plugin twice
if vim.g.loaded_beads == 1 then
  return
end
vim.g.loaded_beads = 1

-- Initialize beads plugin with defaults
require("beads").setup()
