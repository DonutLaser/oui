package oui

import "core:mem"
import vmem "core:mem/virtual"

Arena_Allocator :: struct {
	arena:     vmem.Arena,
	allocator: mem.Allocator,
}

arena_allocator_init :: proc(allocator: ^Arena_Allocator) {
	_ = vmem.arena_init_growing(&allocator.arena)
	allocator.allocator = vmem.arena_allocator(&allocator.arena)
}

arena_allocator_destroy :: proc(allocator: ^Arena_Allocator) {
	vmem.arena_destroy(&allocator.arena)
}

arena_allocator_free_all :: proc(allocator: ^Arena_Allocator) {
	vmem.arena_free_all(&allocator.arena)
}

