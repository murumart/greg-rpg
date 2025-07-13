class_name AutoscrollComponent extends Node


enum State {
	WAIT,
	SCROLL_DOWN,
	SCROLL_UP,
}

const SCROLL_SPEED_MULT := 16.0

var state: State
var next_state: State
var _delay: float

@export var target: RichTextLabel
@export var speed := 1.0
@export var read_time := 2.0


func _ready() -> void:
	assert(target, "no target set!")
	reset()


func _process(delta: float) -> void:
	if not target.is_visible_in_tree():
		return
	var scrollbar := target.get_v_scroll_bar() as VScrollBar
	match state:
		State.WAIT:
			_delay -= delta * speed
			if _delay <= 0:
				if next_state == State.SCROLL_DOWN:
					_delay = 0
				elif next_state == State.SCROLL_UP:
					_delay = scrollbar.max_value - scrollbar.page
				state = next_state
		State.SCROLL_DOWN:
			scroll_down(scrollbar, delta * speed * SCROLL_SPEED_MULT)
		State.SCROLL_UP:
			scroll_up(scrollbar, delta * speed * SCROLL_SPEED_MULT)


func scroll_down(bar: VScrollBar, delta: float) -> void:
	_delay += delta
	bar.value = roundf(_delay)
	if bar.value >= bar.max_value - bar.page:
		state = State.WAIT
		_delay = read_time
		next_state = State.SCROLL_UP


func scroll_up(bar: VScrollBar, delta: float) -> void:
	_delay -= delta
	bar.value = roundf(_delay)
	if bar.value <= 0:
		state = State.WAIT
		_delay = read_time
		next_state = State.SCROLL_DOWN


func reset() -> void:
	_delay = read_time
	state = State.WAIT
	next_state = State.SCROLL_DOWN
	if not target.get_v_scroll_bar():
		return
	var scrollbar := target.get_v_scroll_bar() as VScrollBar
	scrollbar.value = 0
