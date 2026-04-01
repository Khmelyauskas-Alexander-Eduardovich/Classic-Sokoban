// levels.js
// # - стена, @ - игрок, $ - ящик, . - цель, * - ящик на цели, + - игрок на цели, X - стена (X)

const levels = [
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
    var nX = x + dx;
    var nY = y + dy;
    if (nY < 0 || nY >= currentMap.length || nX < 0 || nX >= currentMap[nY].length) return { "success": false };
    var target = currentMap[nY][nX];
    if (target === "#" || target === "X") return { "success": false };
    var oldMapCopy = JSON.parse(JSON.stringify(currentMap));
    if (target === "$" || target === "*") {
        var bX = nX + dx;
        var bY = nY + dy;
        var bTarget = currentMap[bY][bX];
        if (bTarget === " " || bTarget === ".") {
            var rowTo = currentMap[bY].split("");
            rowTo[bX] = (bTarget === ".") ? "*" : "$";
            currentMap[bY] = rowTo.join("");
            var rowFrom = currentMap[nY].split("");
            rowFrom[nX] = (target === "*") ? "." : " ";
            currentMap[nY] = rowFrom.join("");
        } else return { "success": false };
    }
    var pOldRow = currentMap[y].split("");
    pOldRow[x] = (currentMap[y][x] === "+") ? "." : " ";
    currentMap[y] = pOldRow.join("");
    var pNewRow = currentMap[nY].split("");
    pNewRow[nX] = (currentMap[nY][nX] === ".") ? "+" : "@";
    currentMap[nY] = pNewRow.join("");
    return { "success": true, "newX": nX, "newY": nY, "oldMap": oldMapCopy, "oldX": x, "oldY": y };
}
