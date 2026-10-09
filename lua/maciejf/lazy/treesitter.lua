return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			local ts = require("nvim-treesitter")

			ts.install({
				"vimdoc",
				"javascript",
				"typescript",
				"c",
				"lua",
				"rust",
				"jsdoc",
				"bash",
				"go",
			})

			local max_filesize = 100 * 1024 -- 100 KB

			local function attach(buf, lang)
				if not vim.api.nvim_buf_is_valid(buf) then
					return
				end
				if not pcall(vim.treesitter.start, buf, lang) then
					return
				end
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("MaciejFTreesitter", {}),
				callback = function(args)
					local buf = args.buf
					local lang = vim.treesitter.language.get_lang(args.match)
					if not lang or lang == "html" then
						return
					end

					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						vim.notify(
							"File larger than 100KB treesitter disabled for performance",
							vim.log.levels.WARN,
							{ title = "Treesitter" }
						)
						return
					end

					if vim.list_contains(ts.get_installed(), lang) then
						attach(buf, lang)
					elseif vim.list_contains(ts.get_available(), lang) then
						-- auto_install replacement
						ts.install(lang):await(function()
							vim.schedule(function()
								attach(buf, lang)
							end)
						end)
					end
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				multiwindow = false, -- Enable multiwindow support.
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
