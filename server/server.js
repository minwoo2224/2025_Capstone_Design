const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const { battle } = require('./battle.js');

const app = express();
const server = http.createServer(app);
const io = socketIO(server);

const waitingQueue = [];

io.on("connection", (socket) => {
    console.log("user connected");

    socket.on("joinQueue", (data) => {
        console.log(`player joined: ${data.name}`);

        const player = {
            name: data.name,
            hp: data.hp || 100,
            attack: data.attack || 20,
            defend: data.defend || 5,
            speed: data.speed || 10,
            socket: socket
        };

        waitingQueue.push(player);

        if (waitingQueue.length >= 2) {
            const player1 = waitingQueue.shift();
            const player2 = waitingQueue.shift();
            battle(player1, player2);
        }
    });
});

app.get("/", (req, res) => {
    res.sendFile(__dirname + "/index.html");
});

server.listen(8080, () => {
    console.log("server running at http://localhost:8080");
});