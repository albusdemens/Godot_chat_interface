extends Node2D

@onready var chatLog = get_node("VBoxContainer/RichTextLabel")
@onready var inputLabel = get_node("VBoxContainer/HBoxContainer/Label")
@onready var inputField = get_node("VBoxContainer/HBoxContainer/LineEdit")

var user_name = 'User'
var http_request = HTTPRequest.new()

func _ready():
	inputField.connect("text_submitted", Callable(self, "text_submitted"))
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			inputField.grab_focus()
		if event.pressed and event.keycode == KEY_ESCAPE:
			inputField.release_focus()

func text_submitted(text):
	if text.strip_edges() != "":
		var formatted_text = "%s: %s\n" % [user_name, text]
		chatLog.append_text(formatted_text)
		inputField.text = ''
		send_to_ollama(text)

func send_to_ollama(message):
	var url = "http://localhost:11434/api/generate"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		#"model": "llama3",
		"model": "qwen2:1.5b",
		"prompt": message,
		"stream": false
	})

	print("Sending request to Ollama: ", body)

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("An error occurred in the HTTP request.")

func _on_request_completed(_result, response_code, _headers, body):
	print("Response Code: ", response_code)
	print("Raw Response: ", body.get_string_from_utf8())
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var response = json.get_data()
			print("Parsed Response: ", response)
			if response and "response" in response:
				add_message("Ollama: " + response["response"])
			else:
				print("Response doesn't contain 'response' key")
		else:
			print("JSON Parse Error: ", json.get_error_message())
	else:
		print("Error: ", response_code)

func add_message(text):
	chatLog.append_text(text + "\n")
