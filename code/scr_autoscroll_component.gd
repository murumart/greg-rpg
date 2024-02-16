class_name AutoscrollComponent extends Node

const SPEED_MULT := 0.05

var scroller: Tween

@export var target: RichTextLabel
@export var speed := 1.0
@export var read_time := 2.0


func _ready() -> void:
	assert(target, "no target set!")
	check()


func check() -> void:
	if not target.is_visible_in_tree():
		return
	if target.get_v_scroll_bar():
		var scrollbar := target.get_v_scroll_bar() as VScrollBar
		if scrollbar.max_value != scrollbar.page:
			if scrollbar.value == 0:
				scroll_down(scrollbar)
				return
			else:
				scroll_up(scrollbar)
				return


func scroll_down(bar: VScrollBar) -> void:
	if is_instance_valid(scroller) and scroller.is_valid():
		scroller.kill()
	scroller = create_tween()
	var distance := bar.max_value - bar.page
	scroller.tween_interval(read_time)
	scroller.tween_property(bar, "value", distance, speed * SPEED_MULT * distance).from(0)
	scroller.tween_callback(check)


func scroll_up(bar: VScrollBar) -> void:
	if is_instance_valid(scroller) and scroller.is_valid():
		scroller.kill()
	scroller = create_tween()
	var distance := bar.max_value - bar.page
	scroller.tween_interval(read_time)
	scroller.tween_property(bar, "value", 0, speed * SPEED_MULT * distance)
	scroller.tween_callback(check)


func reset() -> void:
	if not target.get_v_scroll_bar():
		return
	var scrollbar := target.get_v_scroll_bar() as VScrollBar
	if is_instance_valid(scroller) and scroller.is_valid():
		scroller.kill()
	scrollbar.value = 0
