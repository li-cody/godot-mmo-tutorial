extends Control

@onready var chat_log: RichTextLabel = get_node("CanvasLayer/VBoxContainer/RichTextLabel")
@onready var input_label: Label = get_node("CanvasLayer/VBoxContainer/HBoxContainer/Label")
@onready var input_field: LineEdit = get_node("CanvasLayer/VBoxContainer/HBoxContainer/LineEdit")

signal message_sent(message)


func _ready():
	input_field.connect("text_submitted", text_entered)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				input_field.grab_focus()
			KEY_ESCAPE:
				input_field.release_focus()

func add_message(username: String, text: String):
	print("add_message")
	chat_log.append_text(username + " says: " + text + "\n")

func text_entered(text: String):
	if len(text) > 0:
		input_field.text = ""
		
		emit_signal("message_sent", text)
