#+private
package oui

STACK_CAPACITY :: 16

Container_Stack :: struct {
	data:  [STACK_CAPACITY]Container,
	index: int,
}

stack_push :: proc(stack: ^Container_Stack, item: Container) {
	stack.data[stack.index] = item
	stack.index += 1
}

stack_pop :: proc(stack: ^Container_Stack) -> Container {
	result := stack.data[stack.index - 1]
	stack.index -= 1

	return result
}

stack_peek :: proc(stack: ^Container_Stack) -> ^Container {
	return &stack.data[stack.index - 1]
}

stack_root :: proc(stack: ^Container_Stack) -> ^Container {
	return &stack.data[0]
}

