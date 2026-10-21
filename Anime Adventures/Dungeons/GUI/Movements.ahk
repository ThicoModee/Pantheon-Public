#Requires AutoHotkey v2.0

#Include Binaries.ahk

MoveForGreenie() {
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep (1800)
    SendInput ("{a up}")
    SendInput ("{w up}")
}

MoveForSnowyTown() {
    BetterClick(700, 125, "Right")
    Sleep (7000)
}

MoveForNavyBay() {
    SendInput ("{a down}")
    SendInput ("{w down}")
    Sleep (1700)
    SendInput ("{a up}")
    SendInput ("{w up}")
}

MoveForFiendCity() {
    BetterClick(185, 410, "Right")
    Sleep (3000)
    SendInput ("{a down}")
    Sleep (3000)
    SendInput ("{a up}")
    Sleep (500)
}

MoveForSpiritTown() {
    SendInput("{a down}")
    Sleep(1000)
    SendInput("{a up}")
    Sleep(500)
    SendInput("{w down}")
    Sleep(500)
    SendInput("{w up}")
}

MoveForSpiritWorld() {
    SendInput ("{d down}")
    SendInput ("{w down}")
    Sleep(7000)
    SendInput ("{d up}")
    SendInput ("{w up}")
    sleep(500)
    BetterClick(400, 15, "Right")
    sleep(4000)
}

MoveForAntKingdom() {
    BetterClick(130, 550, "Right")
    Sleep (3000)
    BetterClick(130, 550, "Right")
    Sleep (4000)
    BetterClick(30, 450, "Right")
    Sleep (3000)
    BetterClick(120, 100, "Right")
    sleep (3000)
}

MoveForMagicTown() {
    BetterClick(700, 315, "Right")
    Sleep (2500)
    BetterClick(585, 535, "Right")
    Sleep (3000)
    /*SendInput ("{d down}")
    Sleep (3800)
    SendInput ("{d up}")*/
}

explosiveTest :=
    "|<>*79$70.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk7zzXzzyTzzzDzzzDzztzzzwS80ws877A0zk80lnC0SQk1zDUE7At0tk07w200kE023V0zk1kz0UUM7C3zzznzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"

TestExplosive() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, explosiveTest)) {
        return true
    }

    return false
}

MagicHillDetect := "|<>##0.70$0/0/FFD400,-5/-7/FFD400,-12/3/FFD400,-1/10/FFD400,12/6/FFD400,16/-4/FFD400,11/-8/FFD400"

MoveForMagicHill() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 170, 0, 0, MagicHillDetect)) {
        BetterClick(22, 187, "Right")
        Sleep(3000)
        BetterClick(22, 167, "Right")
        Sleep(3000)
        SendInput("{a down}")
        SendInput("{s down}")
        SendInput("{Space down}")
        Sleep(3000)
        SendInput("{a up}")
        SendInput("{s up}")
        SendInput("{Space up}")
        Sleep(1000)
        SendInput("{a down}")
        SendInput("{w down}")
        Sleep(3500)
        SendInput("{a up}")
        SendInput("{w up}")
    } else {
        BetterClick(500, 20, "Right")
        Sleep (3000)
        BetterClick(500, 20, "Right")
        Sleep (3500)
        BetterClick(285, 15, "Right")
        Sleep (2500)
        SendInput("{a down}")
        SendInput("{w down}")
        SendInput("{Space down}")
        Sleep(3000)
        SendInput("{a up}")
        SendInput("{w up}")
        SendInput("{Space up}")
        /*BetterClick(285, 25, "Right")
        Sleep (3000)
        BetterClick(410, 25, "Right")
        Sleep (3000)
        BetterClick(765, 150, "Right")
        Sleep (3000)
        BetterClick(545, 30, "Right")
        Sleep (3000)*/
    }
}

HauntedAcademyAngle :=
    "|<>##0.97$0/0/091512,8/-3/081211,12/5/091412,5/8/0A1713,1/14/0A1513,10/11/0A1612,0/-3/081212,-5/-5/091512"

MoveForHauntedAcademy() {
    if (ok := FindText(&X, &Y, 600, 200, 800, 400, 0, 0, HauntedAcademyAngle)) {
        SendInput ("{s down}")
        sleep (4500)
        SendInput ("{s up}")
    } else {
        SendInput ("{d down}")
        sleep (4500)
        SendInput ("{d up}")
    }
}

MoveForSpaceCenter() {
    BetterClick(160, 280, "Right")
    Sleep (7000)
    SendInput("{w down}")
    Sleep(1000)
    SendInput("{w up}")
}

MoveForMountainTemple() {
    SendInput("{w down}")
    SendInput("{d down}")
    Sleep(2000)
    SendInput("{w up}")
    SendInput("{d up}")
}

CursedFestivalAngle :=
    "|<>##0.85$0/0/E84800,17/-4/E84800,23/9/E84800,35/-4/E84800,-23/-7/E84800,-18/3/E84800,1/12/E84800,25/3/E84800,23/-5/E84800,4/-4/E84800,-5/-3/E84800,16/6/E84800"

MoveForCursedFestival() {
    if (ok := FindText(&X, &Y, 0, 400, 800, 600, 0, 0, CursedFestivalAngle)) {
        SendInput ("{d down}")
        sleep (2000)
        SendInput ("{d up}")
        Sleep(100)

        SendInput("{w down}")
        Sleep(3000)
        SendInput("{w up}")
        Sleep(100)
        SendInput("{w down}")
        SendInput("{a down}")
        Sleep(2000)
        SendInput("{w up}")
        SendInput("{a up}")
    } else {
        SendInput ("{a down}")
        sleep (2000)
        SendInput ("{a up}")
        Sleep(100)

        SendInput("{s down}")
        Sleep(3000)
        SendInput("{s up}")
        Sleep(100)
        SendInput("{s down}")
        SendInput("{d down}")
        Sleep(2000)
        SendInput("{s up}")
        SendInput("{d up}")
    }
}

MoveForNightmareTrain() {
    SendInput ("{a down}")
    sleep (1800)
    SendInput ("{a up}")
}

MoveForAirCraft() {
    SendInput ("{s down}")
    sleep (800)
    SendInput ("{s up}")
}

MoveForHellish() {
    BetterClick(600, 300, "Right")
    Sleep (7000)
}

MoveForShibuya() {
    if (ok := FindText(&X, &Y, 220, 190, 320, 250, 0.15, 0.15, ShibuyaAngle)) {
        SendInput ("{a down}")
        sleep (600)
        SendInput ("{a up}")
        sleep (500)
        SendInput ("{a down}")
        SendInput ("{w down}")
        Sleep (1500)
        SendInput ("{a up}")
        SendInput ("{w up}")
    } else {
        SendInput ("{d down}")
        Sleep(4000)
        SendInput ("{d up}")
    }
}
