extends Node

const NetworkClient = preload("res://websockets_client.gd")
const Packet = preload("res://packet.gd")


@onready var _network_client = NetworkClient.new()
@onready var _chatbox = get_node("Chatbox")

var state: Callable

func _ready():
	_network_client.connect("connected", _handle_client_connected)
	_network_client.connect("disconnected", _handle_client_disconnected)
	_network_client.connect("error", _handle_network_error)
	_network_client.connect("data", _handle_network_data)
	add_child(_network_client)
	_network_client.connect_to_server("127.0.0.1", 8081)
	_chatbox.connect("message_sent", send_chat)
	
	state = PLAY

func PLAY(p):
	match p.action:
		"Chat":
			var message: String = p.payloads[0]
			_chatbox.add_message(message)

func _handle_client_connected():
	print("Client connected to server!")

func _handle_client_disconnected(was_clean: bool):
	OS.alert("Disconnected %s" % ["cleanly" if was_clean else "unexpectedly"])
	get_tree().quit()

func _handle_network_data(data: PackedByteArray):
	print("Received server data: ", data)
	var	stringified: String = data.get_string_from_utf8()
	var action_payloads: Array = Packet.json_to_action_payloads(stringified)
	var p: Packet = Packet.new(action_payloads[0], action_payloads[1])
	
	state.call(p)

func _handle_network_error():
	OS.alert("There was an error")
	
func send_chat(text: String):
	print("send_chat")
	var p: Packet = Packet.new("Chat", [text])	
	_network_client.send_packet(p)
	_chatbox.add_message(text)

