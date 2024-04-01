import queue

from autobahn.twisted.websocket import WebSocketServerProtocol

import packet
from django_app.django_app import models


class GameServerProtocol(WebSocketServerProtocol):
    # Protocol defines how a client should handle data packets
    def __init__(self):
        super().__init__()
        self._packet_queue: queue.Queue[tuple['GameServerProtocol', packet.Packet]] = queue.Queue()
        # Want to start off in the LOGIN state
        self._state: callable = self.LOGIN
        self._user: models.User = None

    def PLAY(self, sender: 'GameServerProtocol', p: packet.Packet):
        # In the Play state, process packets using the following logic:

        if p.action == packet.Action.Chat:
            if sender == self:
                print("broadcasting packet")
                self.broadcast(p, exclude_self=True)
            else:
                print("sending packet to everyone")
                self.send_client(p)

    def LOGIN(self, sender: 'GameServerProtocol', p: packet.Packet):
        if p.action == packet.Action.Login:
            print("login packet seen")
            username, password = p.payloads
            if models.User.objects.filter(username=username, password=password).exists():
                self._user = models.User.objects.get(username=username)
                self.send_client(packet.OkPacket())
                self._state = self.PLAY
            else:
                self.send_client(packet.DenyPacket("Username or password incorrect"))
        elif p.action == packet.Action.Register:
            print("register packet seen")
            username, password = p.payloads
            if models.User.objects.filter(username=username).exists():
                self.send_client(packet.DenyPacket("This username is already taken."))
            else:
                user = models.User(username=username, password=password)
                user.save()
                self.send_client(packet.OkPacket())


    def tick(self):
        # Every tick, poll packet queue and apply the current state
        if not self._packet_queue.empty():
            print("fetching packet!")
            s, p = self._packet_queue.get()

            self._state(s, p)

    def broadcast(self, p: packet.Packet, exclude_self: bool = False):

        # Check and see what other clients are connected to
        for other in self.factory.players:
            # Don't process packet that "self" sent
            if other == self and exclude_self:
                continue
            # Route packet
            other.onPacket(self, p)
    
    def onPacket(self, sender: 'GameServerProtocol', p: packet.Packet):
        # Route packet to queue
        self._packet_queue.put((sender, p))
        print(f"Queued packet: {p}")
    
    # Override 
    def onConnect(self, request):
        # Called when a WS connection is made
        print(f"Client connection: {request.peer}")
    
    # Override
    def onOpen(self):
        # Called when a WS connection is started
        print(f"Websocket connection open.")
        self._state = self.LOGIN
    
    # Override
    def onClose (self, wasClean, code, reason):
        self.factory.players.remove(self)
        print(f"Websocket connection closed {'unexpectedly' if not wasClean else ' cleanly'} with code {code}: {reason}")
    
    # Override
    def onMessage(self, payload, isBinary):
        # Called when a WS message is received
        decoded_payload = payload.decode('utf-8')

        try:
            p: packet.Packet = packet.from_json(decoded_payload)
        except Exception as e:
            print(f"Could not load message as packet: {e}. Message was: {payload.decode('utf8')}")
        
        self.onPacket(self, p)
    
    def send_client(self, p: packet.Packet):
        b = bytes(p)
        self.sendMessage(b)