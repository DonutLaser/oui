package oui

import "core:fmt"
import rl "vendor:raylib"

Direction :: enum {
	HORIZONTAL,
	VERTICAL,
}

Size_Type :: enum {
	FIT,
	GROW,
	FIXED,
}

Alignment :: enum {
	START,
	CENTER,
	END,
}

Position :: struct {
	x, y:     f32,
	absolute: bool,
}

Size_Value :: struct {
	value: f32,
	type:  Size_Type,
}

Padding :: struct {
	left, right: f32,
	top, bottom: f32,
}

GUI_Element :: struct {
	// Tree data
	parent:   ^GUI_Element,
	children: [dynamic]^GUI_Element,

	// Node data
	data:     GUI_Element_Data,
}

GUI_Element_Data :: struct {
	pos:            Position,
	width:          Size_Value,
	height:         Size_Value,
	layout_dir:     Direction,
	content_halign: Alignment,
	content_valign: Alignment,
	content_gap:    f32,
	padding:        Padding,
	bg_color:       rl.Color,
}

GUI :: struct {
	root:        ^GUI_Element,
	next_parent: ^GUI_Element,

	// Private data
	arena:       Arena_Allocator,
}

@(private = "file")
gui: GUI

init :: proc() {
	arena_allocator_init(&gui.arena)

	gui.root = nil
	gui.next_parent = nil
}

destroy :: proc() {
	arena_allocator_destroy(&gui.arena)
}

begin :: proc(data: GUI_Element_Data) {
	new_element := new(GUI_Element, allocator = gui.arena.allocator)
	new_element.parent = gui.next_parent
	new_element.children = make([dynamic]^GUI_Element, allocator = gui.arena.allocator)
	new_element.data = data

	if gui.root == nil {
		gui.root = new_element
	} else {
		append(&gui.next_parent.children, new_element)
	}

	gui.next_parent = new_element
}

end :: proc() {
	element := gui.next_parent

	if element.data.layout_dir == .HORIZONTAL {
		if element.data.width.type == .FIT {
			element.data.width.value += element.data.padding.left + element.data.padding.right
			for child in element.children {
				element.data.width.value += child.data.width.value
			}
			element.data.width.value += f32((len(element.children) - 1)) * element.data.content_gap
		}

		if element.data.height.type == .FIT {
			for child in element.children {
				element.data.height.value = max(child.data.height.value, element.data.height.value)
			}

			element.data.height.value += element.data.padding.top + element.data.padding.bottom
		}
	} else if element.data.layout_dir == .VERTICAL {
		if element.data.height.type == .FIT {
			element.data.height.value += element.data.padding.top + element.data.padding.bottom
			for child in element.children {
				element.data.height.value += child.data.height.value
			}
			element.data.height.value += f32((len(element.children) - 1)) * element.data.content_gap
		}

		if element.data.width.type == .FIT {
			for child in element.children {
				element.data.width.value = max(child.data.width.value, element.data.width.value)
			}

			element.data.width.value += element.data.padding.left + element.data.padding.right
		}
	}

	gui.next_parent = gui.next_parent.parent
}

relative :: proc(x, y: f32) -> Position {
	return {x, y, false}
}

absolute :: proc(x, y: f32) -> Position {
	return {x, y, true}
}

fixed :: proc(value: f32) -> Size_Value {
	return {value, .FIXED}
}

grow :: proc() -> Size_Value {
	return {0, .GROW}
}

fit :: proc() -> Size_Value {
	return {0, .FIT}
}

padding1 :: proc(value: f32) -> Padding {
	return {value, value, value, value}
}

padding2 :: proc(hor, vert: f32) -> Padding {
	return {hor, vert, hor, vert}
}

padding4 :: proc(left, top, right, bottom: f32) -> Padding {
	return {left, top, right, bottom}
}

padding :: proc {
	padding1,
	padding2,
	padding4,
}

render :: proc() {
	if gui.root == nil { return }

	grow_children(gui.root)
	position_elements(gui.root, 0, 0)

	render_elements(gui.root)

	// Actually draw things to screen
	flush_render_queue()

	// Since we are essentially in immediate mode, we reset the element tree and will recalculate everything each frame.
	// This might be a problem with bigger trees, but we'll fix that when we encounter the problem.
	arena_allocator_free_all(&gui.arena)
	gui.root = nil
	gui.next_parent = nil
}

@(private = "file")
grow_children :: proc(node: ^GUI_Element) {
	if node.data.layout_dir == .VERTICAL {
		space_remaining_along_axis := node.data.height.value
		grow_child_count := 0

		for child in node.children {
			if child.data.height.type == .GROW {
				grow_child_count += 1
			} else {
				if !child.data.pos.absolute {
					space_remaining_along_axis -= child.data.height.value
				}
			}
		}

		relative_children_count := 0
		for child in node.children {
			if !child.data.pos.absolute {
				relative_children_count += 1
			}
		}

		space_remaining_along_axis -= node.data.content_gap * f32(relative_children_count - 1)
		space_remaining_along_axis -= node.data.padding.top
		space_remaining_along_axis -= node.data.padding.bottom

		one_child_size := space_remaining_along_axis / f32(grow_child_count)

		space_remaining_across_axis := node.data.width.value - node.data.padding.left - node.data.padding.right

		for child in node.children {
			if child.data.height.type != .GROW { continue }

			child.data.height.value = one_child_size
		}

		for child in node.children {
			if child.data.width.type != .GROW { continue }

			child.data.width.value = space_remaining_across_axis
		}
	} else if node.data.layout_dir == .HORIZONTAL {
		space_remaining_along_axis := node.data.width.value
		grow_child_count := 0

		for child in node.children {
			if child.data.width.type == .GROW {
				grow_child_count += 1
			} else {
				if !child.data.pos.absolute {
					space_remaining_along_axis -= child.data.width.value
				}
			}
		}

		relative_children_count := 0
		for child in node.children {
			if !child.data.pos.absolute {
				relative_children_count += 1
			}
		}

		space_remaining_along_axis -= node.data.content_gap * f32(relative_children_count - 1)
		space_remaining_along_axis -= node.data.padding.left
		space_remaining_along_axis -= node.data.padding.right

		one_child_size := space_remaining_along_axis / f32(grow_child_count)

		space_remaining_across_axis := node.data.height.value - node.data.padding.top - node.data.padding.bottom

		for child in node.children {
			if child.data.width.type != .GROW { continue }

			child.data.width.value = one_child_size
		}

		for child in node.children {
			if child.data.height.type != .GROW { continue }

			child.data.height.value = space_remaining_across_axis
		}
	}

	for child in node.children {
		grow_children(child)
	}
}

@(private = "file")
position_elements :: proc(node: ^GUI_Element, local_x: f32, local_y: f32) {
	if node.parent != nil && !node.data.pos.absolute {
		node.data.pos.x = node.parent.data.pos.x + local_x + node.parent.data.padding.left
		node.data.pos.y = node.parent.data.pos.y + local_y + node.parent.data.padding.top
	}

	if node.data.layout_dir == .HORIZONTAL {
		cursor_x: f32 = 0.0
		cursor_y: f32 = 0.0

		full_width: f32 = 0.0

		// calculate cursor along axis
		if node.data.content_halign != .START {
			relative_children_count := 0
			for child in node.children {
				if child.data.pos.absolute { continue }

				full_width += child.data.width.value
				relative_children_count += 1
			}

			full_width += node.data.padding.left + node.data.padding.right + (node.data.content_gap * f32(relative_children_count - 1))

			cursor_x = node.data.width.value - full_width
		}

		if node.data.content_halign == .CENTER { cursor_x /= 2 }

		full_height := node.data.padding.top + node.data.padding.bottom + node.data.height.value
		for child in node.children {
			// calculate cursor across axis
			#partial switch node.data.content_valign {
				case .CENTER:
					cursor_y = (full_height - child.data.height.value) / 2
				case .END:
					cursor_y = full_height - child.data.height.value
			}

			position_elements(child, cursor_x + child.data.pos.x, cursor_y + child.data.pos.y)
			cursor_x += child.data.width.value + node.data.content_gap
		}
	} else if node.data.layout_dir == .VERTICAL {
		cursor_y: f32 = 0.0
		cursor_x: f32 = 0.0
		full_height: f32 = 0.0

		// calculate cursor along axis
		if node.data.content_valign != .START {
			relative_children_count := 0
			for child in node.children {
				if child.data.pos.absolute { continue }

				full_height += child.data.height.value
				relative_children_count += 1
			}

			full_height += node.data.padding.top + node.data.padding.bottom + (node.data.content_gap * f32(relative_children_count - 1))
			cursor_y = node.data.height.value - full_height
		}

		if node.data.content_valign == .CENTER { cursor_y /= 2 }

		full_width := node.data.padding.left + node.data.padding.right + node.data.width.value
		for child in node.children {
			// calculate cursor axis
			#partial switch node.data.content_halign {
				case .CENTER:
					cursor_x = (full_width - child.data.width.value) / 2
				case .END:
					cursor_x = full_width - child.data.width.value
			}

			position_elements(child, cursor_x + child.data.pos.x, cursor_y + child.data.pos.y)
			cursor_y += child.data.height.value + node.data.content_gap
		}
	}
}

@(private = "file")
render_elements :: proc(node: ^GUI_Element) {
	x := node.data.pos.x
	y := node.data.pos.y
	w := node.data.width.value
	h := node.data.height.value

	draw_rect(x, y, w, h, node.data.bg_color)

	for child in node.children {
		render_elements(child)
	}
}

