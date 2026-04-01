import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.LocalStorage 2.0
import "levels.js" as Logic

ApplicationWindow {
    id: window
    visible: true
    width: 480
    height: 800
    title: qsTr("Sokoban Bravada")
    color: "#7cfc00"

    // --- ПРОГРЕСС ---
    property int currentLevelIdx: 0
    property int maxUnlockedLevel: 0
    readonly property int totalLevels: 15

    // --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ АССЕТОВ ---
    function getAsset(name) {
        var qrcPath = "qrc:/" + name;
        // Проверяем, доступны ли ресурсы (для бинарника), если нет — берем локально (для qmlscene)
        return (Qt.resolvedUrl(qrcPath).toString() !== "") ? qrcPath : name;
    }

    // --- SQL STORAGE (FIXED) ---
        QtObject {
            id: dbManager
            property var db: null

            function initDb() {
                try {
                    // Открываем базу. Если версии нет, ставим "1.0"
                    db = LocalStorage.openDatabaseSync("SokobanBravadaDB", "", "Save Progress", 100000);

                    db.transaction(function(tx) {
                        // Создаем таблицу, если её нет
                        tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)');
                        console.log("SQL: Table checked/created");
                    });
                } catch (e) {
                    console.log("SQL Init Error: " + e);
                }
            }

            function saveProgress() {
                if (!db) return;
                db.transaction(function(tx) {
                    // Явно приводим к String перед записью
                    tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["lastIdx", String(window.currentLevelIdx)]);
                    tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', ["maxIdx", String(window.maxUnlockedLevel)]);
                    console.log("SQL: Saved level " + window.currentLevelIdx);
                });
            }

            function loadProgress() {
                if (!db) return;
                db.readTransaction(function(tx) {
                    try {
                        var rs1 = tx.executeSql('SELECT value FROM settings WHERE key="lastIdx"');
                        if (rs1.rows.length > 0) {
                            window.currentLevelIdx = parseInt(rs1.rows.item(0).value);
                        }

                        var rs2 = tx.executeSql('SELECT value FROM settings WHERE key="maxIdx"');
                        if (rs2.rows.length > 0) {
                            window.maxUnlockedLevel = parseInt(rs2.rows.item(0).value);
                        }
                        console.log("SQL: Loaded. Current: " + window.currentLevelIdx + " Max: " + window.maxUnlockedLevel);
                    } catch (e) {
                        console.log("SQL Load Error: " + e);
                    }
                });
            }
        }

    // --- ENGINE ---
    QtObject {
        id: engine
        property var history: []; property var map: []; property int px: 0; property int py: 0
        property bool swipeMode: false

        function loadLevel(idx) {
            if (idx >= Logic.levels.length) idx = 0;
            window.currentLevelIdx = idx;
            if (idx > window.maxUnlockedLevel) window.maxUnlockedLevel = idx;
            dbManager.saveProgress();

            var data = Logic.levels[idx];
            map = JSON.parse(JSON.stringify(data.map));
            history = [];
            for (var i = 0; i < map.length; i++) {
                var pPos = map[i].indexOf("@");
                if (pPos === -1) pPos = map[i].indexOf("+");
                if (pPos !== -1) { px = pPos; py = i; }
            }
            refresh();
        }

        function refresh() {
            gameModel.clear();
            for (var y = 0; y < 9; y++) {
                var row = (map[y] !== undefined) ? map[y] : "         ";
                for (var x = 0; x < 9; x++) {
                    gameModel.append({"type": (row[x] !== undefined) ? row[x] : " "});
                }
            }
            winLabel.visible = isWin();
            if (winLabel.visible) autoNextTimer.start();
        }

        function isWin() {
            if (map.length === 0) return false;
            for (var i = 0; i < map.length; i++) {
                if (map[i].indexOf("$") !== -1) return false;
            }
            return true;
        }

        function step(dx, dy) {
            if (winLabel.visible) return;
            var res = Logic.tryMove(map, px, py, dx, dy);
            if (res.success === true) {
                history.push({"m": res.oldMap, "x": res.oldX, "y": res.oldY});
                px = res.newX; py = res.newY;
                refresh();
            }
        }

        function back() {
            if (history.length > 0 && !winLabel.visible) {
                var prev = history.pop();
                map = prev.m; px = prev.x; py = prev.y;
                refresh();
            }
        }
    }

    Timer { id: autoNextTimer; interval: 1500; onTriggered: engine.loadLevel(window.currentLevelIdx + 1) }
    ListModel { id: gameModel }

    Column {
        anchors.fill: parent; anchors.margins: 10; spacing: 15

        Text {
            text: Logic.levels[window.currentLevelIdx].name
            font.pixelSize: 24; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 15
            Button { text: qsTr("↶ Назад"); onClicked: engine.back() }
            Button { text: qsTr("СБРОС"); onClicked: engine.loadLevel(window.currentLevelIdx) }
            Button {
                id: btnChoose
                text: qsTr("CHOOSE LEVEL")
                visible: window.maxUnlockedLevel >= 14
                onClicked: console.log("Menu open")
            }
        }

        // --- ОБЛАСТЬ С ПЛАВНЫМ ЗУМОМ И СВАЙПОМ ---
        Flickable {
            id: flick
            width: parent.width; height: 400
            contentWidth: gameContainer.width * gameContainer.scale
            contentHeight: gameContainer.height * gameContainer.scale
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: true

            // Настройка плавности свайпа (инерции)
            flickDeceleration: 1500 // Чем меньше, тем дольше "катится" карта
            maximumFlickVelocity: 2500 // Максимальная скорость "броска"

            // Улучшенная эмуляция зума для трекпада (безумный MouseWheel)
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: {
                    // Используем Behavior для сглаживания зума
                    var zoomFactor = wheel.angleDelta.y > 0 ? 1.2 : 0.8
                    gameContainer.smoothScaleTo(zoomFactor);
                }
                onClicked: mouse.accepted = false
            }

            PinchArea {
                id: pinchArea
                anchors.fill: parent
                pinch.target: gameContainer
                pinch.minimumScale: 0.5
                pinch.maximumScale: 3.0
                pinch.dragAxis: Pinch.NoDrag

                Item {
                    id: gameContainer
                    width: 40 * 9; height: 40 * 9
                    anchors.centerIn: parent
                    transformOrigin: Item.Center

                    // Функция для плавного изменения масштаба через MouseArea
                    function smoothScaleTo(factor) {
                        var ns = scale * factor
                        if (ns >= 0.5 && ns <= 3.0) scale = ns
                    }

                    // --- BEHAVIOR ДЛЯ ПЛАВНОГО ЗУМА ---
                    // Отключаем анимацию, когда активна PinchArea (щипок на экране телефона),
                    // чтобы не было дрожания. Анимация работает только для MouseWheel.
                    Behavior on scale {
                        id: scaleAnimation
                        enabled: !pinchArea.pinch.active // Магия выключения анимации
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    GridView {
                        anchors.fill: parent; cellWidth: 40; cellHeight: 40
                        model: gameModel; interactive: false
                        delegate: Item {
                            width: 40; height: 40
                            Image { anchors.fill: parent; source: "floor.svg"; opacity: 0.1 }
                            Image {
                                anchors.fill: parent
                                source: {
                                    if (model.type === "#" || model.type === "X") return "wall.svg";
                                    if (model.type === "@" || model.type === "+") return "player.svg";
                                    if (model.type === "$") return "box.svg";
                                    if (model.type === ".") return "goal.svg";
                                    if (model.type === "*") return "box_on_goal.svg";
                                    return "";
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- БЛОК УПРАВЛЕНИЯ С АНИМАЦИЕЙ РЕЖИМОВ ---
        Item {
            id: controlRoot
            width: 300; height: 250; anchors.horizontalCenter: parent.horizontalCenter

            // 1. ТАЧПАД (SWIPE MODE)
            Rectangle {
                id: touchpad
                anchors.fill: parent; color: "white"; radius: 20; border.color: "black"; border.width: 2

                // АНИМАЦИЯ ПОЯВЛЕНИЯ
                opacity: engine.swipeMode ? 0.15 : 0
                scale: engine.swipeMode ? 1.0 : 0.8
                visible: opacity > 0 // Для оптимизации рендеринга

                // Плавное изменение opacity и scale
                Behavior on opacity { OpacityAnimator { duration: 250 } }
                Behavior on scale { ScaleAnimator { duration: 250; easing.type: Easing.OutBack } }

                MouseArea {
                    anchors.fill: parent; enabled: engine.swipeMode
                    property real startX: 0; property real startY: 0
                    onPressed: { startX = mouse.x; startY = mouse.y }
                    onPositionChanged: {
                        var dx = mouse.x - startX; var dy = mouse.y - startY
                        if (Math.abs(dx) > 40) { engine.step(dx > 0 ? 1 : -1, 0); startX = mouse.x; startY = mouse.y }
                        else if (Math.abs(dy) > 40) { engine.step(0, dy > 0 ? 1 : -1); startX = mouse.x; startY = mouse.y }
                    }
                    onPressAndHold: engine.swipeMode = false
                }
                Text { anchors.centerIn: parent; text: qsTr("TOUCHPAD MODE\nPress and Hold to switch into Button Mode "); opacity: 0.5 }
            }

            // 2. КНОПКИ (D-PAD MODE)
            Grid {
                id: buttonGrid
                columns: 3; anchors.centerIn: parent; spacing: 10

                // АНИМАЦИЯ ИСЧЕЗНОВЕНИЯ
                opacity: engine.swipeMode ? 0 : 1
                scale: engine.swipeMode ? 0.8 : 1.0
                visible: opacity > 0

                // Те же Behavior для D-Pad кнопок
                Behavior on opacity { OpacityAnimator { duration: 250 } }
                Behavior on scale { ScaleAnimator { duration: 250; easing.type: Easing.OutBack } }

                Item { width: 75; height: 75 }
                Button { text: "↑"; width: 75; height: 75; onClicked: engine.step(0, -1); onPressAndHold: engine.swipeMode = true }
                Item { width: 75; height: 75 }
                Button { text: "←"; width: 75; height: 75; onClicked: engine.step(-1, 0); onPressAndHold: engine.swipeMode = true }
                Button { text: "↓"; width: 75; height: 75; onClicked: engine.step(0, 1); onPressAndHold: engine.swipeMode = true }
                Button { text: "→"; width: 75; height: 75; onClicked: engine.step(1, 0); onPressAndHold: engine.swipeMode = true }
            }
        }
    }

    Text {
        id: winLabel; text: qsTr("Win!"); visible: false; anchors.centerIn: parent
        font.pixelSize: 60; color: "orange"; font.bold: true
    }

    Component.onCompleted: {
        dbManager.initDb();
        dbManager.loadProgress();
        engine.loadLevel(window.currentLevelIdx);
    }
}
