// levels.js
// # - стена, @ - игрок, $ - ящик, . - цель, * - ящик на цели, + - игрок на цели, X - стена (X)
// Levels & Logics in 1 (One) ;;)
var levels = [
    {"name": qsTr("Level 1"), "map": [
                         "  ###    ",
                         "  #.#    ",
                         "  # #### ",
                         "###$ $.# ",
                         "#. $@### ",
                         "####$#   ",
                         "   #.#   ",
                         "   ###   ",
                         "         "]},
    {"name": qsTr("Level 2"), "map": [
                         "#####   ",
                         "#  @#        ",
                         "# $$# ###",
                         "# $ # #.#",
                         "### ###.#",
                         " ##    .#",
                         " #   #  #",
                         " #   ####",
                         " #####   "]},
    {"name": qsTr("Level 3"), "map": [
                         " ####    ",
                         "##  #    ",
                         "# @$#    ",
                         "##$ ##   ",
                         "## $ #  ",
                         "#.$  #",
                         "#..*.#   ",
                         "######   ",
                         "         "]},
    {"name": qsTr("Level 4"), "map": [
                         " ####    ",
                         " #@ ###  ",
                         " # $  #  ",
                         "### # ## ",
                         "#.# #  # ",
                         "#.$  # # ",
                         "#.   $ # ",
                         "######## ",
                         "         "]},
    {"name": qsTr("Level 5"), "map": [
                         "  ###### ",
                         "  #    # ",
                         "###$$$ # ",
                         "#@ $.. # ",
                         "# $...## ",
                         "####  #  ",
                         "   ####  ",
                         "        ",
                         "         "]},
    {"name": qsTr("Level 6"), "map": [
                         "  #####  ",
                         "###  @#  ",
                         "#  $. ##  ",
                         "#  .$. # ",
                         "### *$ # ",
                         "  #   ## ",
                         "  #####  ",
                         "        ",
                         "         "]},
    {"name": qsTr("Level 7"), "map": [
                         "  ####   ",
                         "  #..#   ",
                         " ## .##  ",
                         " #  $.#  ",
                         "## $  ## ",
                         "#  #$$ # ",
                         "#  @   # ",
                         "######## ",
                         "         "]},
    {"name": qsTr("Level 8"), "map": [
                         "######## ",
                         "#  #   # ",
                         "# $..$ # ",
                         "#@$.* ## ",
                         "# $..$ # ",
                         "#  #   # ",
                         "######## ",
                         "         ",
                         "         "]},
    {"name": qsTr("Level 9"), "map": [
                         "######   ",
                         "#    #   ",
                         "# $$$##  ",
                         "#  #..###",
                         "##  ..$ #",
                         " # @    #",
                         " ########",
                         "         ",
                         "         "]},
    {"name": qsTr("Level 10"), "map": [
                         "#######  ",
                         "#..$..#  ",
                         "#..#..#  ",
                         "# $$$ #  ",
                         "#  $  #  ",
                         "# $$$ #  ",
                         "#  #@ #  ",
                         "#######",
                         "         "]},
    {"name": qsTr("Level 11"), "map": [
                         " #####   ",
                         " # @ ### ",
                         "## #$  # ",
                         "# *. . # ",
                         "#  $$ ## ",
                         "### #.#  ",
                         "  #   #  ",
                         "  #####  ",
                         "         "]},
    {"name": qsTr("Level 12"), "map": [
                         "######  ",
                         "#    #   ",
                         "# $ @#   ",
                         "##*  #   ",
                         "# * ##   ",
                         "# * #    ",
                         "# * #    ",
                         "# . #    ",
                         "#####    "]},
    {"name": qsTr("Level 13"), "map": [
                         "  ####   ",
                         "  #  #   ",
                         "###$ ##  ",
                         "#  * @#  ",
                         "#  *  #  ",
                         "#  * ##  ",
                         "###* #   ",
                         "  #.##   ",
                         "  ###    "]},
    {"name": qsTr("Level 14"), "map": [
                         "#####   ",
                         "#   #####",
                         "# # #   #",
                         "# $   $ #",
                         "#..#$#$##",
                         "#.@$   # ",
                         "#..  ### ",
                         "######   ",
                         "         "]},
    {"name": qsTr("Level 15"), "map": [
                         " ######  ",
                         " #    ## ",
                         "##.##$ # ",
                         "# ..$  # ",
                         "#  #$  # ",
                         "#  @ ### ",
                         "######   ",
                         "         ",
                         "         "]}
];

function tryMove(currentMap, x, y, dx, dy) {
    // Делаем копию сразу, чтобы не портить оригинал до проверки
    var newMap = JSON.parse(JSON.stringify(currentMap));
    var nX = x + dx;
    var nY = y + dy;

    if (nY < 0 || nY >= newMap.length || nX < 0 || nX >= newMap[nY].length) return { "success": false };

    var target = newMap[nY][nX];
    if (target === "#" || target === "X") return { "success": false };

    // Логика ящика
    if (target === "$" || target === "*") {
        var bX = nX + dx;
        var bY = nY + dy;
        if (bY < 0 || bY >= newMap.length || bX < 0 || bX >= newMap[bY].length) return { "success": false };

        var bTarget = newMap[bY][bX];
        if (bTarget === " " || bTarget === ".") {
            var rowTo = newMap[bY].split("");
            rowTo[bX] = (bTarget === ".") ? "*" : "$";
            newMap[bY] = rowTo.join("");

            var rowFrom = newMap[nY].split("");
            rowFrom[nX] = (target === "*") ? "." : " ";
            newMap[nY] = rowFrom.join("");
        } else return { "success": false };
    }

    // Логика игрока (обновляем target, так как он мог измениться ящиком)
    var finalTarget = newMap[nY][nX];
    var pOldRow = newMap[y].split("");
    pOldRow[x] = (newMap[y][x] === "+" || newMap[y][x] === ".") ? "." : " ";
    newMap[y] = pOldRow.join("");

    var pNewRow = newMap[nY].split("");
    pNewRow[nX] = (finalTarget === "." || finalTarget === "*") ? "+" : "@";
    // Заметь: если там был ящик, мы его уже подвинули, поэтому тут просто ставим игрока
    newMap[nY] = pNewRow.join("");

    return { "success": true, "newX": nX, "newY": nY, "newMap": newMap };
}
