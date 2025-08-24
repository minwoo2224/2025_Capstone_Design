const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const { battle } = require('./battle.js');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
});

const players = {};      // { [socketId]: { name, socket, cards, selectedIndex, roomId, wins } }
const waitingQueue = []; // socketId list

<<<<<<< HEAD
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    // 매칭 큐 등록
    socket.on('joinQueue', (playerData) => {
        try {
            if (!playerData || !Array.isArray(playerData.cards)) {
                socket.emit('card_length_error', 'invalid payload');
                return;
            }
            if (playerData.cards.length !== 3) {
                socket.emit('card_length_error', 'you have to select three cards!');
                return;
            }

            players[socket.id] = {
                name: playerData.name,
                socket,
                cards: playerData.cards.map((c) => ({
                    name: c.name,
                    hp: c.hp,
                    attack: c.attack,
                    defend: c.defend,
                    speed: c.speed,
                    type: c.type,
                    image: c.image,
                })),
                selectedIndex: undefined,
                roomId: null,
                wins: 0,
            };

            waitingQueue.push(socket.id);
            console.log('waitingQueue:', waitingQueue.map((id) => id.slice(0, 6)));

            if (waitingQueue.length >= 2) {
                let id1 = waitingQueue.shift();
                let id2 = waitingQueue.shift();
                if (!id1 || !id2) return;

                const roomId = `${id1}-${id2}`;
                [id1, id2].forEach((id) => {
                    if (!players[id]) return;
                    players[id].roomId = roomId;
                    players[id].socket.join(roomId);
                });

                const p1 = players[id1];
                const p2 = players[id2];
                if (!p1 || !p2) return;

                io.to(roomId).emit('matched', 'matching success! select card!');
                p1.socket.emit('cardsInfo', p2.cards);
                p2.socket.emit('cardsInfo', p1.cards);

                console.log('Room created:', roomId);
            }
        } catch (err) {
            console.error('joinQueue error:', err);
            socket.emit('card_length_error', 'internal error');
        }
    });

    // 라운드용 카드 선택
    socket.on('selectCard', (index) => {
        const me = players[socket.id];
        if (!me) return;
        if (typeof index !== 'number' || index < 0 || index >= me.cards.length) {
            console.warn('selectCard invalid index from', socket.id);
            return;
        }
=======
// socket connection
io.on("connection", (socket) => {
    console.log("User connected: ", socket.id);

    // random matching
    socket.on("joinQueue", (playerData) => {
        if (playerData.cards.length !== 3) {
            socket.emit("card_length_error", "you have to select three cards!");
            return;
        }

        // key: players[socket.id], {value}
        players[socket.id] = {
            name: playerData.name,
            socket: socket,
            cards: playerData.cards,   // three card information
            selectedIndex: undefined,  // select one card
            roomId: null,
            wins: 0                    // wins point = 2 -> game win
        };

        waitingQueue.push(socket.id);
        console.log("waitingQueue: ", waitingQueue);

        // room matching logic
        if (waitingQueue.length >= 2) {
            const id1 = waitingQueue.shift();
            const id2 = waitingQueue.shift();
            const roomId = `${id1}-${id2}`;
            [id1, id2].forEach(id => {
                players[id].roomId = roomId;
                players[id].socket.join(roomId);
            });

            io.to(roomId).emit("matched", "matching success! select card!");

            // send three cards info
            const roomPlayers = Object.values(players).filter(p => p.roomId === roomId);
            const [p1, p2] = roomPlayers;
            p1.socket.emit("cardsInfo", p2.cards);
            p2.socket.emit("cardsInfo", p1.cards);
            console.log(p2.cards);
            console.log(p1.cards);

            console.log(io.sockets.adapter.rooms);
        };
    });

    // battle logic
    socket.on("selectCard", (index) => {
        const player = players[socket.id];
        if (!player) return;
>>>>>>> b168eb18dab09c4aeda712317d14c360e8d857d5

        me.selectedIndex = index;
        const roomId = me.roomId;
        if (!roomId) return;

        const roomPlayers = Object.values(players).filter((p) => p.roomId === roomId);
        if (roomPlayers.length !== 2) return;

<<<<<<< HEAD
        // 양측 모두 선택되면 배틀 시작 (승자는 다음 라운드에 index 유지)
        if (roomPlayers.every((p) => p.selectedIndex !== undefined)) {
            const [p1, p2] = roomPlayers;
            const p1Idx = p1.selectedIndex;
            const p2Idx = p2.selectedIndex;
            const p1Card = p1.cards[p1Idx];
            const p2Card = p2.cards[p2Idx];

            p1.socket.emit('startBattle', p2Card);
            p2.socket.emit('startBattle', p1Card);

            const p1_card_info = {
                name: p1Card.name, hp: p1Card.hp, attack: p1Card.attack,
                defend: p1Card.defend, speed: p1Card.speed, image: p1Card.image,
                socket: p1.socket,
            };
            const p2_card_info = {
                name: p2Card.name, hp: p2Card.hp, attack: p2Card.attack,
                defend: p2Card.defend, speed: p2Card.speed, image: p2Card.image,
                socket: p2.socket,
            };
=======
            //아래 있던 거 위치 변경 #pjh 수정
            const [p1, p2] = roomPlayers;
            const p1_card = p1.cards[p1.selectedIndex];
            const p2_card = p2.cards[p2.selectedIndex];

            // 두 플레이어가 모두 선택한 경우 클라이언트한테 배틀 시작 신호 보내기 #pjh 수정
            p1.socket.emit("startBattle", p2_card);
            p2.socket.emit("startBattle", p1_card);

            const p1_card_info = {
                name: p1_card.name,
                hp: p1_card.hp,
                attack: p1_card.attack,
                defend: p1_card.defend,
                speed: p1_card.speed,
                image: p1_card.image,
                socket: p1.socket
            }; // 수정 image 추가 #pjh 수정

            const p2_card_info = {
                name: p2_card.name,
                hp: p2_card.hp,
                attack: p2_card.attack,
                defend: p2_card.defend,
                speed: p2_card.speed,
                image: p2_card.image,
                socket: p2.socket
            }; // 수정 image 추가 #pjh 수정
>>>>>>> b168eb18dab09c4aeda712317d14c360e8d857d5

            battle(p1_card_info, p2_card_info, (winnerSocketId) => {
                try {
                    const p1Id = p1.socket.id;
                    const p2Id = p2.socket.id;
                    const winner = players[winnerSocketId];
                    if (!winner) return;

<<<<<<< HEAD
                    const loserSocketId = (winnerSocketId === p1Id) ? p2Id : p1Id;
                    const loser = players[loserSocketId];
                    if (!loser) return;

                    winner.wins += 1;

                    // 승리 카드 HP 유지(업데이트), 패배 카드 제거
                    const winnerIdx = (winnerSocketId === p1Id) ? p1Idx : p2Idx;
                    const loserIdx = (loserSocketId === p1Id) ? p1Idx : p2Idx;
                    const finalWinnerHp =
                        (winnerSocketId === p1Id) ? p1_card_info.hp : p2_card_info.hp;

                    if (winner.cards[winnerIdx]) {
                        winner.cards[winnerIdx].hp = finalWinnerHp;
                    }
                    if (loser.cards[loserIdx]) {
                        loser.cards.splice(loserIdx, 1);
                    }

                    // 경기 종료 조건: 3승 또는 상대 카드 0장
                    if (winner.wins >= 3 || loser.cards.length === 0) {
                        io.to(winner.roomId).emit('matchResult', `${winner.name} wins!`);
                        console.log(`${winner.roomId} game end`);
                        return;
                    }

                    // 다음 라운드:
                    // 승자는 같은 카드로 계속 (selectedIndex 유지),
                    // 패자는 다시 고르게끔 selectedIndex 초기화
                    if (winnerSocketId === p1Id) {
                        p1.selectedIndex = winnerIdx;      // 유지
                        p2.selectedIndex = undefined;      // 패자만 다시 고름
                    } else {
                        p2.selectedIndex = winnerIdx;      // 유지
                        p1.selectedIndex = undefined;      // 패자만 다시 고름
                    }

                    // 이번에 고를 사람(picker): 패자
                    const picker = loserSocketId;

                    // cardsInfo 규약: [내 socket.id]: 상대 남은 카드
                    io.to(winner.roomId).emit('nextRound', {
                        wins: { [p1.name]: p1.wins, [p2.name]: p2.wins },
                        picker, // 이번 라운드에서 카드를 "선택해야 하는" 플레이어의 socket.id
                        cardsInfo: {
                            [p1Id]: p2.cards,
                            [p2Id]: p1.cards,
                        },
=======
                // 이긴 뒤 연결 끊기 넣기
                if (players[winnerSocketId].wins === 2) {
                    io.to(roomId).emit("matchResult", players[winnerSocketId].name + " wins!");
                    console.log(`${roomId} game end`);
                } else {
                    p1.selectedIndex = undefined;
                    p2.selectedIndex = undefined;

                    io.to(roomId).emit("nextRound", {
                        wins: {
                            [p1.name]: p1.wins,
                            [p2.name]: p2.wins
                        },
                        // UI쪽 문제로 인해 추가 죄송합니다 민기님 ㅠㅠ #pjh 수정
                        cardsInfo: {
                            [p1.socket.id]: p2.cards,
                            [p2.socket.id]: p1.cards
                        }
>>>>>>> b168eb18dab09c4aeda712317d14c360e8d857d5
                    });
                } catch (err) {
                    console.error('post-battle error:', err);
                }
            });
        }
    });

<<<<<<< HEAD
    // 연결 종료
    socket.on('disconnect', () => {
        console.log('Disconnected:', socket.id);
        const me = players[socket.id];

        const idx = waitingQueue.indexOf(socket.id);
        if (idx !== -1) waitingQueue.splice(idx, 1);

        const roomId = me?.roomId;
        if (me) delete players[socket.id];

        if (roomId) {
            const roomPlayers = Object.values(players).filter((p) => p.roomId === roomId);
            const remaining = roomPlayers.find((p) => p.socket.id !== socket.id);
            if (remaining) {
                io.to(roomId).emit('matchResult', `${remaining.name} wins! (opponent disconnected)`);
=======
    // disconnect logic
    // 수정 할 듯 -> delete players[socket.id] 부분 중복이라 위치 변경 및 중복 삭제 #pjh 수정
    socket.on("disconnect", () => {
        console.log("Disconnected: ", socket.id);
        const roomId = players[socket.id]?.roomId;
        const index = waitingQueue.indexOf(socket.id);
        console.log("waitingQueue: ", waitingQueue);

        if (index !== -1) waitingQueue.splice(index, 1);
        if (players[socket.id]) {
            const roomId = players[socket.id].roomId;
            io.to(roomId).emit("oppnent_distconnect");
            delete players[socket.id]; // 위치 한 줄 아래로 이동 #pjh 수정
        }

        if (roomId) {
            const roomPlayers = Object.values(players).filter(p => p.roomId === roomId);
            const remainingPlayer = roomPlayers.find(p => p.socket.id !== socket.id);

            if (remainingPlayer) {
                io.to(roomId).emit("matchResult", remainingPlayer.name + " wins! (opponent disconnected)");
>>>>>>> b168eb18dab09c4aeda712317d14c360e8d857d5
            }
            console.log(`${roomId} game end`);
        }
<<<<<<< HEAD
    });
});

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

server.listen(8080, () => {
    console.log('server running at http://localhost:8080');
});
=======

        console.log(`${roomId} game end`);
    });
});

app.get("/", (req, res) => {
    res.sendFile(__dirname + "/index.html");
});

server.listen(8080, () => {
    console.log(`server running at http://localhost:8080`);
});
>>>>>>> b168eb18dab09c4aeda712317d14c360e8d857d5
