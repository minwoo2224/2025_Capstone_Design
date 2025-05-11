async function battle(player1, player2, callback) {
    console.log("battle start")
    const delay = (ms) => new Promise((res) => setTimeout(res, ms));

    let attacker, defender;

    // 속도 비교로 선공 결정
    if (player1.speed >= player2.speed) {
        attacker = player1;
        defender = player2;
    } else {
        attacker = player2;
        defender = player1;
    }
    attacker.socket.emit("initialStatus", {
        enemy: defender.name,
        enemyatk: defender.attack,
        enemyhp: defender.hp,
        enemydf: defender.defend,
        enemyspd: defender.speed
    });

    defender.socket.emit("initialStatus", {
        enemy: attacker.name,
        enemyatk: attacker.attack,
        enemyhp: attacker.hp,
        enemydf: attacker.defend,
        enemyspd: attacker.speed
    });
    
    while (true) {
        if (!attacker.socket.connected || !defender.socket.connected) {
            break;
        }
        // 공격 계산
        const damage = Math.max(0, attacker.attack - defender.defend);
        defender.hp -= damage;

        // 상태 전송 (각 플레이어에게 서로의 상태 전달)
        attacker.socket.emit("updateStatus", {
            self: attacker.name,
            enemy: defender.name,
            selfHp: attacker.hp,
            enemyHp: defender.hp
        });

        defender.socket.emit("updateStatus", {
            self: defender.name,
            enemy: attacker.name,
            selfHp: defender.hp,
            enemyHp: attacker.hp
        });

        // 종료 조건
        if (defender.hp <= 0) {
            const resultMsg = `${attacker.name} round win!`;
            attacker.socket.emit("updateResult", resultMsg);
            defender.socket.emit("updateResult", resultMsg);

            const winnerSocketId = attacker.socket.id;
            if (callback && typeof callback === 'function') {
                callback(winnerSocketId);
            }

            console.log("round end")
            break;
        }

        // 턴 교체
        [attacker, defender] = [defender, attacker];
        await delay(1000);
    }
} 

module.exports = { battle };