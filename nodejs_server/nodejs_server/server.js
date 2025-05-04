const express = require('express');
const http = require('http');
const socketIO = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIO(server);

const waitingQueue = [];

io.on("connection", (socket) => {
    console.log("user connection");

    socket.on("joinQueue", (data) => {
        console.log('Player Joined: ' + data.name);
    });
});

app.get("/", (req, res) => {
    res.sendFile(__dirname + "/client.html");
});

server.listen(8080, () => {
    console.log("server on http://localhost:8080");
});