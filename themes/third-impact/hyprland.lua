local active_border_color = { colors = { "rgba(ff6a00ee)", "rgba(c41e3aee)" }, angle = 45 }
local inactive_border_color = "rgba(3d2a24aa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
