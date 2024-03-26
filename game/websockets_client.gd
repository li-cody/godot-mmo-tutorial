extends Node

const Packet = preload("res://packet.gd")

signal connected
signal data
signal disconnected
signal error

var _client = WebSocketPeer.new()


func _process(delta):
	_client.poll()
	var state = _client.get_ready_state()
	# print(state)
	if state == WebSocketPeer.STATE_CONNECTING:
		print("connecting!")
		pass
	elif state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet_string = _client.get_packet()
			print("Got data from server: ", packet_string)
			emit_signal("data", packet_string)
			print("data signal emitted")

func connect_to_server(hostname: String, port: int) -> void:
	var websocket_url = "ws://%s:%d" % [hostname, port]
	print("connecting to server: " + websocket_url)
	var err = _client.connect_to_url(websocket_url)
	print(err)
	if err:
		print("Unable to connect")
		set_process(false)
		emit_signal("error")
	else:
		set_process(true)
		print("Able to connect_to_server")

func send_packet(packet: Packet) -> void:
	print("send_packet")
	_send_string(packet.tostring())

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)
	emit_signal("disconnected", was_clean)

func _connected(proto = ""):
	print("Conected with protocol: ", proto)
	emit_signal("connected")

func _send_string(string: String) -> void:
	_client.put_packet(string.to_utf8_buffer())
	print("Sent string ", string)

	
	
