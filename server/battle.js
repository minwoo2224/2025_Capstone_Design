// 상태를 보기위해 콘솔 로그 부분 추가 #pjh 수정
async function battle(player1, player2, callback) {
    console.log("⚔️ Battle Start");

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

    // 초기 상태 전달
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
        // 연결 끊긴 경우 종료
        if (!attacker.socket.connected || !defender.socket.connected) {
            console.log("🔌 Player disconnected. Battle aborted.");
            break;
        }

        const critical = Math.random();
        const miss = Math.random();
        console.log(`Rolls - Critical: ${critical.toFixed(2)}, Miss: ${miss.toFixed(2)}`);

        // 기본 데미지 계산
        let damage = Math.max(0, attacker.attack - defender.defend);

        if ((1 - critical) <= 0.1) {
            // 데미지 계산을 확실히 하기 위한 반올림 #pjh 수정
            damage = Math.round(damage * 1.3);
            console.log("🔴 Critical Hit!", damage);
            attacker.socket.emit("critical", "critical!");
            defender.socket.emit("critical", "critical!");
        } else if ((1 - miss) <= 0.1) {
            damage = 0;
            console.log("⚪ Missed!");
            attacker.socket.emit("miss", "miss!");
            defender.socket.emit("miss", "miss!");
        } else {
            // 일반 공격 #pjh 수정
            const normalAttackPayload = {
                attacker: attacker.name,
                defender: defender.name,
                damage: damage
            };
            attacker.socket.emit("normalAttack", normalAttackPayload);
            defender.socket.emit("normalAttack", normalAttackPayload);
        }

        // HP 적용
        defender.hp -= damage;

        // 상태 업데이트 전송
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

        // 라운드 종료 조건
        if (defender.hp <= 0) {
            const resultMsg = `${attacker.name} round win!`;
            attacker.socket.emit("updateResult", resultMsg);
            defender.socket.emit("updateResult", resultMsg);

            const winnerSocketId = attacker.socket.id;
            if (callback && typeof callback === 'function') {
                callback(winnerSocketId);
            }

            console.log("✅ Round Ended");
            break;
        }

        // 턴 교체
        [attacker, defender] = [defender, attacker];
        await delay(1000);
    }
}

module.exports = { battle };
