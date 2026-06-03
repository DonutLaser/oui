package oui

import "core:mem"

Container_Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

Container_Alignment :: enum {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER_LEFT,
	CENTER,
	CENTER_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
}

Container_Options :: struct {
	direction:      Container_Direction,
	padding:        f32,
	content_gap:    f32,
	content_sizes:  []f32,
	alignment:      Container_Alignment,
	global:         bool,
	list:           bool,
	list_item_size: f32,
	width:          f32,
	height:         f32,
}

@(private)
Container :: struct {
	direction:        Container_Direction,
	content_area:     Rect,
	padding:          f32,
	content_gap:      f32,
	content_sizes:    [dynamic]f32,
	content_autosize: f32,
	width:            f32,
	height:           f32,
	list:             bool,
	list_item_size:   f32,
	cursor:           Position,
	index:            int,
}

@(private = "file")
Layout :: struct {
	container_stack: Container_Stack,
	allocator:       mem.Allocator,
}

Rect :: struct {
	x, y, w, h: f32,
}

Position :: struct {
	x, y: f32,
}

// @(private = "file")
// layout: Layout

new_layout :: proc(allocator: mem.Allocator) -> (result: Layout) {
	result.allocator = allocator

	return result
}

begin :: proc(layout: ^Layout, width, height: f32) {
	container := Container {
		direction     = .VERTICAL,
		content_sizes = make([dynamic]f32, allocator = layout.allocator),
		content_area  = {0, 0, width, height},
	}
	append(&container.content_sizes, height)
	stack_push(&layout.container_stack, container)
}

end :: proc(layout: ^Layout) {
	stack_pop(&layout.container_stack)
}

// begin :: proc(width, height: f32, allocator: mem.Allocator) {
// 	layout.allocator = allocator

// 	container := Container {
// 		direction     = .VERTICAL,
// 		content_sizes = make([dynamic]f32, allocator = layout.allocator),
// 		content_area  = {0, 0, width, height},
// 	}
// 	append(&container.content_sizes, height)
// 	stack_push(&layout.container_stack, container)
// }

// end :: proc() {
// 	stack_pop(&layout.container_stack)
// }

begin_container :: proc(layout: ^Layout, options: Container_Options) {
	rect: Rect
	if options.global {
		rect = align_container(stack_root(&layout.container_stack)^, options.width, options.height, options.alignment)
	} else {
		rect = next(layout)
	}

	container := Container {
		direction      = options.direction,
		content_area   = rect,
		padding        = options.padding,
		content_gap    = options.content_gap,
		width          = options.width,
		height         = options.height,
		list           = options.list,
		list_item_size = options.list_item_size,
		content_sizes  = make([dynamic]f32, allocator = layout.allocator),
	}

	if !options.list {
		auto_size_count := 0
		for size in options.content_sizes {
			append(&container.content_sizes, size)
			if size == -1 {
				auto_size_count += 1
			}
		}

		axis := container.content_area.h
		if options.direction == .HORIZONTAL {
			axis = container.content_area.w
		}

		usable_size := axis - f32(len(options.content_sizes) - 1) * options.content_gap - options.padding * 2
		for size in options.content_sizes {
			if size != -1 {
				usable_size -= size
			}
		}

		container.content_autosize = usable_size / f32(auto_size_count)
	}

	stack_push(&layout.container_stack, container)
}

end_container :: proc(layout: ^Layout) {
	stack_pop(&layout.container_stack)
}

spacing :: proc(layout: ^Layout) {
	_ = next(layout)
}

next :: proc(layout: ^Layout) -> (result: Rect) {
	parent := stack_peek(&layout.container_stack)

	result.x = parent.content_area.x + parent.padding + parent.cursor.x
	result.y = parent.content_area.y + parent.padding + parent.cursor.y

	axis_size := parent.list_item_size
	if !parent.list {
		axis_size = parent.content_sizes[parent.index]
		parent.index += 1
	}

	if parent.direction == .HORIZONTAL {
		result.w = axis_size
		result.h = parent.content_area.h - parent.padding * 2
	} else if parent.direction == .VERTICAL {
		result.w = parent.content_area.w - parent.padding * 2
		result.h = axis_size
	}

	if result.w == -1 { result.w = parent.content_autosize }
	if result.h == -1 { result.h = parent.content_autosize }

	if parent.direction == .HORIZONTAL {
		parent.cursor.x += result.w + parent.content_gap
	} else if parent.direction == .VERTICAL {
		parent.cursor.y += result.h + parent.content_gap
	}

	return result
}

get_container_bounds :: proc(layout: ^Layout) -> Rect {
	parent := stack_peek(&layout.container_stack)
	return parent.content_area
}

@(private = "file")
align_container :: proc(root_container: Container, width: f32, height: f32, alignment: Container_Alignment) -> (result: Rect) {
	usable_area := Rect {
		x = root_container.content_area.x + root_container.padding,
		y = root_container.content_area.y + root_container.padding,
		w = root_container.content_area.w - root_container.padding * 2,
		h = root_container.content_area.h - root_container.padding * 2,
	}

	switch alignment {
		case .TOP_LEFT:
			result.x = usable_area.x
			result.y = usable_area.y
		case .TOP_CENTER:
			result.x = usable_area.x + usable_area.w / 2 - width / 2
			result.y = usable_area.y
		case .TOP_RIGHT:
			result.x = usable_area.x + usable_area.w - width
			result.y = usable_area.y
		case .CENTER_LEFT:
			result.x = usable_area.x
			result.y = usable_area.y + usable_area.h / 2 - height / 2
		case .CENTER:
			result.x = usable_area.x + usable_area.w / 2 - width / 2
			result.y = usable_area.y + usable_area.h / 2 - height / 2
		case .CENTER_RIGHT:
			result.x = usable_area.x + usable_area.w - width
			result.y = usable_area.y + usable_area.h / 2 - height / 2
		case .BOTTOM_LEFT:
			result.x = usable_area.x
			result.y = usable_area.y + usable_area.h - height
		case .BOTTOM_CENTER:
			result.x = usable_area.x + usable_area.w / 2 - width / 2
			result.y = usable_area.y + usable_area.h - height
		case .BOTTOM_RIGHT:
			result.x = usable_area.x + usable_area.w - width
			result.y = usable_area.y + usable_area.h - height
	}

	result.w = width
	result.h = height

	return result
}

