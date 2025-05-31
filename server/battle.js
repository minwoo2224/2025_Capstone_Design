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
        var critical = Math.random();
        critical.toFixed(1);
        var miss = Math.random();
        miss.toFixed(1);
        console.log(`${critical}, ${miss}`);

        // 공격 계산 => critical + miss logic
        damage = Math.max(0, attacker.attack - defender.defend);
        if ((1 - critical) <= 0.1) {
            damage *= 1.3;
            console.log(damage);
            attacker.socket.emit("critical", "critical!");
            defender.socket.emit("critical", "critical!");
        }
        if ((1 - miss) <= 0.1) {
            damage = 0;
            console.log(damage);
            attacker.socket.emit("miss", "miss!");
            defender.socket.emit("miss", "miss!");
        }

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