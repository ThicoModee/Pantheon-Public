#Requires AutoHotkey v2.0

#Include %A_ScriptDir%\Challenges.ahk

global Movements := Map(
    "Snowy Town", MoveInSnowyTown
)

MoveInSnowyTown() {
    started := true
    SendInput("{d down}")

    while (started) {
        SendInput("{Space}")
        if A_TickCount > 7500
            started := false
    }

    SendInput("{d up}")
}
