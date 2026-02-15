package oui

import rl "vendor:raylib"

MAX_RENDER_COMMANDS :: 16_384

Render_Command :: union {
	Rect_Command,
}

Rect_Command :: struct {
	x, y, w, h:   f32,
	color:        rl.Color,
	border_size:  f32,
	border_color: rl.Color,
}

render_queue: [MAX_RENDER_COMMANDS]Render_Command
render_queue_size: u16

draw_rect :: proc(x, y, w, h: f32, color: rl.Color, border_size: f32, border_color: rl.Color) {
	render_queue[render_queue_size] = Rect_Command {
		x            = x,
		y            = y,
		w            = w,
		h            = h,
		color        = color,
		border_size  = border_size,
		border_color = border_color,
	}

	render_queue_size += 1
}

flush_render_queue :: proc() {
	rl.BeginDrawing()
	{
		rl.ClearBackground({0, 0, 0, 255})

		for i in 0 ..< render_queue_size {
			switch _ in render_queue[i] {
				case Rect_Command:
					command := render_queue[i].(Rect_Command)
					rect := rl.Rectangle{command.x, command.y, command.w, command.h}
					rl.DrawRectangleRec(rect, command.color)

					if command.border_size > 0 {
						rl.DrawRectangleLinesEx(rect, command.border_size, command.border_color)
					}
			}
		}
	}
	rl.EndDrawing()

	render_queue_size = 0
}

