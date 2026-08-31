return {
	{
		"bjarneo/aether.nvim",
		branch = "v3",
		name = "aether",
		priority = 1000,
		opts = {
			colors = {
				bg = "#0c0a0d",
				dark_bg = "#080608",
				darker_bg = "#050406",
				lighter_bg = "#1a1218",

				fg = "#e8dcc8",
				dark_fg = "#8a7a6e",
				light_fg = "#f0e6d6",
				bright_fg = "#fff6ea",
				muted = "#3d2a24",

				red = "#C41E3A",
				yellow = "#F5C518",
				orange = "#FF6A00",
				green = "#A8FF3E",
				cyan = "#00E5FF",
				blue = "#3D6BFF",
				magenta = "#E85D04",
				brown = "#6B3A2A",

				bright_red = "#FF3B5C",
				bright_yellow = "#FFD54A",
				bright_green = "#C8FF7A",
				bright_cyan = "#7AFFFF",
				bright_blue = "#7A9CFF",
				bright_magenta = "#FF8A3D",

				accent = "#FF6A00",
				cursor = "#fff6ea",
				foreground = "#e8dcc8",
				background = "#0c0a0d",
				selection = "#2a1510",
				selection_foreground = "#fff6ea",
				selection_background = "#2a1510",
			},
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "aether",
		},
	},
}
