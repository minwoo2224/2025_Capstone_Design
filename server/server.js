const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const { battle } = require('./battle.js');

const app = express();
const server = http.createServer(app);
const io = socketIO(server);

const players = {};
const waitingQueue = [];

//socket connection
io.on("connection", (socket) => {
    console.log("User connected: ", socket.id);

    //random matching
    socket.on("joinQueue", (playerData) => {
        if (playerData.cards.length !== 3) {
            socket.emit("card_length_error", "you have to select three cards!");
            return;
        }
        
        // key:players[socket.id], {value}
        players[socket.id] = {
            name: playerData.name,
            socket: socket,
            cards: playerData.cards,   //three card information
            selectedIndex: undefined,  //select one card
            roomId: null,
            wins: 0                    //wins point = 2 -> game win
        };

        waitingQueue.push(socket.id);
        console.log("waitingQueue: ", waitingQueue);
        //room matching logic
        if (waitingQueue.length >= 2) {
            const id1 = waitingQueue.shift();
            const id2 = waitingQueue.shift();
            const roomId = `${id1}-${id2}`;
            [id1, id2].forEach(id => {
                players[id].roomId = roomId;
                players[id].socket.join(roomId);
            });
            io.to(roomId).emit("matched", "matching success! select card!");

            //send three cards info
            const roomPlayers = Object.values(players).filter(p => p.roomId === roomId);
            const [p1, p2] = roomPlayers;
            p1.socket.emit("cardsInfo", p2.cards);
            p2.socket.emit("cardsInfo", p1.cards);
            console.log(p2.cards);
            console.log(p1.cards);

            console.log(io.sockets.adapter.rooms);
        };
    });

    //battle logic
    socket.on("selectCard", (index) => {
        const player = players[socket.id];
        if (!player) return;

        player.selectedIndex = index;
        const roomId = player.roomId;

        const roomPlayers = Object.values(players).filter(p => p.roomId === roomId);
        if (roomPlayers.length === 2 &&
            roomPlayers.every(p => p.selectedIndex !== undefined)) {

            const [p1, p2] = roomPlayers;
            const p1_card = p1.cards[p1.selectedIndex];
            const p2_card = p2.cards[p2.selectedIndex];
            const p1_card_info = { name: p1_card.name, hp: p1_card.hp, attack: p1_card.attack, defend: p1_card.defend, speed: p1_card.speed, socket: p1.socket };
            const p2_card_info = { name: p2_card.name, hp: p2_card.hp, attack: p2_card.attack, defend: p2_card.defend, speed: p2_card.speed, socket: p2.socket };

            battle(p1_card_info, p2_card_info, (winnerSocketId) => {
                players[winnerSocketId].wins += 1;

                //이긴 뒤 연결 끊기 넣기
                if (players[winnerSocketId].wins === 2) {

                    io.to(roomId).emit("matchResult", players[winnerSocketId].name + "wins!");
                    console.log(`${roomId} game end`);
                } else {
                    p1.selectedIndex = undefined;
                    p2.selectedIndex = undefined;

                    io.to(roomId).emit("nextRound", {
                        wins: {
                            [p1.name]: p1.wins,
                            [p2.name]: p2.wins
                        }
                    });
                }
            });
        }
    });

    //disconnect logic
    //수정
    socket.on("disconnect", () => {
        console.log("Disconnected: ", socket.id);
        const roomId = players[socket.id]?.roomId;
        const index = waitingQueue.indexOf(socket.id);
        console.log("waitingQueue: ", waitingQueue);
        if (index !== -1) waitingQueue.splice(index, 1);
        if (players[socket.id]) {
            const roomId = players[socket.id].roomId;
            delete players[socket.id];
            io.to(roomId).emit("oppnent_distconnect");
        }
        if (roomId) {
            const roomPlayers = Object.values(players).filter(p => p.roomId === roomId);

            const remainingPlayer = roomPlayers.find(p => p.socket.id !== socket.id);

            if (remainingPlayer) {
                io.to(roomId).emit("matchResult", remainingPlayer.name + "wins! (opponent disconnected)");
            }
        }
        delete players[socket.id];
        console.log(`${roomId} game end`);
    });
});


app.get("/", (req, res) => {
    res.sendFile(__dirname + "/index.html");
});

server.listen(8080, () => {
    console.log(`server running at http://localhost:8080`);
});