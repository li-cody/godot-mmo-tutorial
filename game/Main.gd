extends Node

const Login = preload("res://Login.gd")
const NetworkClient = preload("res://websockets_client.gd")
const Packet = preload("res://packet.gd")
const Chatbox = preload("res://Chatbox.tscn")


@onready var _network_client = NetworkClient.new()
@onready var _login_screen = get_node("Login")
@onready var _chatbox = null

var state: Callable
var _username: String

func _ready():
	_network_client.connect("connected", _handle_client_connected)
	_network_client.connect("disconnected", _handle_client_disconnected)
	_network_client.connect("error", _handle_network_error)
	_network_client.connect("data", _handle_network_data)
	add_child(_network_client)
	_network_client.connect_to_server("127.0.0.1", 8081)
	_login_screen.connect("login", _handle_login_button)
	_login_screen.connect("register", _handle_register_button)
	
	state = PLAY

func PLAY(p):
	match p.action:
		"Chat":
			var username: String = p.payloads[0]
			var message: String = p.payloads[1]
			_chatbox.add_message(username, message)

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
	var p: Packet = Packet.new("Chat", [_username, text])	
	_network_client.send_packet(p)
	_chatbox.add_message(_username, text)

func _handle_login_button(username: String, password: String):
	state = LOGIN
	var p: Packet = Packet.new("Login", [username, password])
	_username = username
	_network_client.send_packet(p)

func _handle_register_button(username: String, password: String):
	state = REGISTER
	var p: Packet = Packet.new("Register", [username, password])
	_network_client.send_packet(p)

func _enter_game():
	state = PLAY

	remove_child(_login_screen)

	_chatbox = Chatbox.instantiate()
	_chatbox.connect("message_sent", send_chat)
	add_child(_chatbox)

func LOGIN(p):
	match p.action:
		"Ok":
			print("login is good")
			_enter_game()
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)

func REGISTER(p):
	match p.action:
		"Ok":
			OS.alert("Registration successful")
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)
