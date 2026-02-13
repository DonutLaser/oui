package oui

import rl "vendor:raylib"

MAX_RENDER_COMMANDS :: 16_384

Render_Command :: union {
	Rect_Command,
}

Rect_Command :: struct {
	rect:  rl.Rectangle,
	color: rl.Color,
}

render_queue: [MAX_RENDER_COMMANDS]Render_Command
render_queue_size: u16

draw_rect :: proc(x, y, w, h: f32, color: rl.Color) {
	render_queue[render_queue_size] = Rect_Command {
		rect  = {x, y, w, h},
		color = color,
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
					rl.DrawRectangleRec(command.rect, command.color)
			}
		}
	}
	rl.EndDrawing()

	render_queue_size = 0
}

