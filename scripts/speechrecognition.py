import socket
import speech_recognition as sr

# 🎤 Setup speech recognition
recognizer = sr.Recognizer()
mic = sr.Microphone()

# 🖥️ Setup socket server
HOST = "127.0.0.1"  # Localhost
PORT = 65432
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((HOST, PORT))
server_socket.listen(1)

print("✅ Voice control server running. Waiting for Godot to connect...")
conn, addr = server_socket.accept()
print(f"🤝 Connected to Godot: {addr}")

while True:
    with mic as source:
        print("🎤 Say something...")
        recognizer.adjust_for_ambient_noise(source)
        audio = recognizer.listen(source)

    try:
        text = recognizer.recognize_sphinx(audio).lower()
        print("You said:", text)

        # Send recognized text to Godot
        conn.sendall(text.encode("utf-8"))

    except sr.UnknownValueError:
        print("❌ Could not understand audio")
    except sr.RequestError as e:
        print(f"⚠️ Error: {e}")
    