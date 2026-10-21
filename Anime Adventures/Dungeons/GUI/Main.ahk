#Requires AutoHotkey v2.0
#Include gui.ahk

global ItemImages := Map(
    "PhilosophersStone", [A_ScriptDir "\..\..\Lib\Images\ShopItems\PhilosophersStone.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\PhilosophersStone.png"],
    "ElfBow", [A_ScriptDir "\..\..\Lib\Images\ShopItems\ElfBow.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\ElfBow.png"],
    "NinjaBelt", [A_ScriptDir "\..\..\Lib\Images\ShopItems\NinjaBelt.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\NinjaBelt.png"],
    "AureusMaul", [A_ScriptDir "\..\..\Lib\Images\ShopItems\AureusMaul.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\AureusMaul.png"],
    "Axe", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Axe.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Axe.png"],
    "MaskOfRiches", [A_ScriptDir "\..\..\Lib\Images\ShopItems\MaskOfRiches.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\MaskOfRiches.png"],
    "SpeedyBoots", [A_ScriptDir "\..\..\Lib\Images\ShopItems\SpeedyBoots.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\SpeedyBoots.png"],
    "Fishhook", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Fishhook.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Fishhook.png"],
    "NimbleCloak", [A_ScriptDir "\..\..\Lib\Images\ShopItems\NimbleCloak.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\NimbleCloak.png"],
    "Sword", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Sword.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Sword.png"],
    "Bow", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Bow.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Bow.png"],
    "GoldenMushroom", [A_ScriptDir "\..\..\Lib\Images\ShopItems\GoldenMushroom.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\GoldenMushroom.png"],
    "Dagger", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Dagger.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Dagger.png"],
    "ReaperScythe", [A_ScriptDir "\..\..\Lib\Images\ShopItems\ReaperScythe.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\ReaperScythe.png"],
    "CelestialBlade", [A_ScriptDir "\..\..\Lib\Images\ShopItems\CelestialBlade.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\CelestialBlade.png"],
    "GlacialAxe", [A_ScriptDir "\..\..\Lib\Images\ShopItems\GlacialAxe.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\GlacialAxe.png"],
    "MageCoat", [A_ScriptDir "\..\..\Lib\Images\ShopItems\MageCoat.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\MageCoat.png"],
    "Scimitar", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Scimitar.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Scimitar.png"],
    "Headsplitter", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Headsplitter.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Headsplitter.png"],
    "GoldenBranch", [A_ScriptDir "\..\..\Lib\Images\ShopItems\GoldenBranch.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\GoldenBranch.png"],
    "IceDagger", [A_ScriptDir "\..\..\Lib\Images\ShopItems\IceDagger.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\IceDagger.png"],
    "Longbow", [A_ScriptDir "\..\..\Lib\Images\ShopItems\Longbow.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\Longbow.png"],
    "MagicTome", [A_ScriptDir "\..\..\Lib\Images\ShopItems\MagicTome.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\MagicTome.png"],
    "ArchmagesHat", [A_ScriptDir "\..\..\Lib\Images\ShopItems\ArchmagesHat.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\ArchmagesHat.png"],
    "GoldenFishhook", [A_ScriptDir "\..\..\Lib\Images\ShopItems\GoldenFishhook.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\GoldenFishhook.png"],
    "ShimmeringMoonFragment", [A_ScriptDir "\..\..\Lib\Images\ShopItems\ShimmeringMoonFragment.png", A_ScriptDir "\..\..\Lib\Images\ShopItems\Disabled\ShimmeringMoonFragment.png"],
)

MainTab() {
    global SCCheckbox, RandomPrioCheckbox, RPCCheckbox, StatWCheckbox
    global FloorPriority := Map(), ShopPriority := Map()
    global FloorBG := Map(), ShopBG := Map()
    global ChatInput, PServerInput
    global BindResizeButton, BindStartButton, BindStopButton, BindPauseButton
    global resizeInput, startInput, stopInput, pauseInput
    global FloorList
    global SelectedFloor
    FloorList := ["Rare Chest", "Shrine", "Gold", "Shop", "Chest", "Curse"]

    for i, v in FloorFM {
        SelectedFloor.Push(StrLower(StrReplace(FloorList[v], " ", "_")))
    }

    Maintab1()

    TabCtrl.UseTab("MainTab2")
    Maintab2()

    MainTab1() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 1")

        ;PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        ;PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
        ;CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        NextButton.OnEvent("Click", (*) => TabCtrl.Choose("MainTab2"))
        CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; --- Floor Priorities ---
        holder := MaingUI.AddButton("x820 y58 w205 h150 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y63 w197 Center", "Floor Priorities")

        RandomPrioCheckbox := MainGUI.AddCheckBox("x830 y87 h" SGH " w" SGW)
        RandomPrioCheckbox.Value := RandomPrioE
        RandomPrioCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y87 w79", " Random")

        MainGUI.AddText("x830 y118 w15", "1")
        FloorBG.Set(1, mainGUI.AddButton(" x845 y113 Disabled w70 h25 Center", FloorList[FloorFM.Get(1)]))
        CreateImageButton(FloorBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(1, mainGUI.AddDropDownList("x845 y113 w70 +0x4000000", FloorList))
        FloorPriority.Get(1).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(1), FloorList, FloorBG.Get(1)))
        FloorPriority.Get(1).Text := FloorList[FloorFM.Get(1)]

        MainGUI.AddText("x830 y148 w15", "2")
        FloorBG.Set(2, mainGUI.AddButton(" x845 y143 Disabled w70 h25 Center", FloorList[FloorFM.Get(2)]))
        CreateImageButton(FloorBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(2, mainGUI.AddDropDownList(" x845 y143 w70 +0x4000000", FloorList))
        FloorPriority.Get(2).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(2), FloorList, FloorBG.Get(2)))
        FloorPriority.Get(2).Text := FloorList[FloorFM.Get(2)]

        MainGUI.AddText("x830 y178 w15", "3")
        FloorBG.Set(3, mainGUI.AddButton(" x845 y173 Disabled w70 h25 Center", FloorList[FloorFM.Get(3)]))
        CreateImageButton(FloorBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(3, mainGUI.AddDropDownList(" x845 y173 w70 +0x4000000", FloorList))
        FloorPriority.Get(3).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(3), FloorList, FloorBG.Get(3)))
        FloorPriority.Get(3).Text := FloorList[FloorFM.Get(3)]

        MainGUI.AddText("x930 y118 w15", "4")
        FloorBG.Set(4, mainGUI.AddButton("x945 y113 Disabled w70 h25 Center", FloorList[FloorFM.Get(4)]))
        CreateImageButton(FloorBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(4, mainGUI.AddDropDownList("x945 y113 w70 +0x4000000", FloorList))
        FloorPriority.Get(4).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(4), FloorList, FloorBG.Get(4)))
        FloorPriority.Get(4).Text := FloorList[FloorFM.Get(4)]

        MainGUI.AddText("x930 y148 w15", "5")
        FloorBG.Set(5, mainGUI.AddButton("x945 y143 Disabled w70 h25 Center", FloorList[FloorFM.Get(5)]))
        CreateImageButton(FloorBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(5, mainGUI.AddDropDownList("x945 y143 w70 +0x4000000", FloorList))
        FloorPriority.Get(5).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(5), FloorList, FloorBG.Get(5)))
        FloorPriority.Get(5).Text := FloorList[FloorFM.Get(5)]

        MainGUI.AddText("x930 y178 w15", "6")
        FloorBG.Set(6, mainGUI.AddButton("x945 y173 Disabled w70 h25 Center", FloorList[FloorFM.Get(6)]))
        CreateImageButton(FloorBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        FloorPriority.Set(6, mainGUI.AddDropDownList("x945 y173 w70 +0x4000000", FloorList))
        FloorPriority.Get(6).OnEvent("Change", (*) => FloorListWorker(FloorPriority.Get(6), FloorList, FloorBG.Get(6)))
        FloorPriority.Get(6).Text := FloorList[FloorFM.Get(6)]

        ; --- Shop Priorities ---
        holder := MaingUI.AddButton("x820 y224 w205 h255 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y229 w197 Center", "Shop Priorities")

        divider := MaingUI.AddButton("x833 y251 w180 h4 Disabled", "")
        CreateImageButton(divider, 0, ButtonStyles["divider"]*)

        ShopBG.Set(1, mainGUI.AddButton("x837 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(1, mainGui.AddPicture("x840 y266 w25 h25", ItemImages["Longbow"][2]))
        ShopPriority.Get(1).OnEvent("Click", (*) => ShopItemWorker(1, "Longbow"))
        ShopPriority.Get(1).Value := ItemImages["Longbow"][ShopItemEnabled.Get(1)]
        mainGui.Tips.SetTip(ShopPriority.Get(1), "Longbow`r`n+30% Range")

        ShopBG.Set(2, mainGUI.AddButton("x872 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(2, mainGui.AddPicture("x875 y266 w25 h25", ItemImages["MagicTome"][2]))
        ShopPriority.Get(2).OnEvent("Click", (*) => ShopItemWorker(2, "MagicTome"))
        ShopPriority.Get(2).Value := ItemImages["MagicTome"][ShopItemEnabled.Get(2)]
        mainGui.Tips.SetTip(ShopPriority.Get(2), "Magic Tome`r`n+100% Magic DMG")

        ShopBG.Set(3, mainGUI.AddButton("x907 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(3, mainGui.AddPicture("x910 y266 w25 h25", ItemImages["CelestialBlade"][2]))
        ShopPriority.Get(3).OnEvent("Click", (*) => ShopItemWorker(3, "CelestialBlade"))
        ShopPriority.Get(3).Value := ItemImages["CelestialBlade"][ShopItemEnabled.Get(3)]
        mainGui.Tips.SetTip(ShopPriority.Get(3), "Celestial Blade`r`n+777% True DMG")

        ShopBG.Set(4, mainGUI.AddButton("x942 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(4, mainGui.AddPicture("x945 y266 w25 h25", ItemImages["GoldenMushroom"][2]))
        ShopPriority.Get(4).OnEvent("Click", (*) => ShopItemWorker(4, "GoldenMushroom"))
        ShopPriority.Get(4).Value := ItemImages["GoldenMushroom"][ShopItemEnabled.Get(4)]
        mainGui.Tips.SetTip(ShopPriority.Get(4), "Golden Mushroom`r`n-30% UPG and Placement Cost")

        ShopBG.Set(5, mainGUI.AddButton("x977 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(5, mainGui.AddPicture("x980 y268 w25 h22", ItemImages["NinjaBelt"][2]))
        ShopPriority.Get(5).OnEvent("Click", (*) => ShopItemWorker(5, "NinjaBelt"))
        ShopPriority.Get(5).Value := ItemImages["NinjaBelt"][ShopItemEnabled.Get(5)]
        mainGui.Tips.SetTip(ShopPriority.Get(5), "Ninja Belt`r`n-12% SPA")

        ShopBG.Set(6, mainGUI.AddButton("x837 y298 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(6, mainGui.AddPicture("x840 y301 w25 h25", ItemImages["AureusMaul"][2]))
        ShopPriority.Get(6).OnEvent("Click", (*) => ShopItemWorker(6, "AureusMaul"))
        ShopPriority.Get(6).Value := ItemImages["AureusMaul"][ShopItemEnabled.Get(6)]
        mainGui.Tips.SetTip(ShopPriority.Get(6), "Aureus Maul`r`n+200% Physical DMG")

        ShopBG.Set(7, mainGUI.AddButton("x872 y298 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(7), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(7, mainGui.AddPicture("x875 y302 w25 h23", ItemImages["Axe"][2]))
        ShopPriority.Get(7).OnEvent("Click", (*) => ShopItemWorker(7, "Axe"))
        ShopPriority.Get(7).Value := ItemImages["Axe"][ShopItemEnabled.Get(7)]
        mainGui.Tips.SetTip(ShopPriority.Get(7), "Axe`r`n+50% Physical Crit Chance")

        ShopBG.Set(8, mainGUI.AddButton("x907 y298 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(8), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(8, mainGui.AddPicture("x912 y301 w21 h26", ItemImages["MaskOfRiches"][2]))
        ShopPriority.Get(8).OnEvent("Click", (*) => ShopItemWorker(8, "MaskOfRiches"))
        ShopPriority.Get(8).Value := ItemImages["MaskOfRiches"][ShopItemEnabled.Get(8)]
        mainGui.Tips.SetTip(ShopPriority.Get(8), "Mask Of Riches`r`n-50% UPG / Placement Cost")

        ShopBG.Set(9, mainGUI.AddButton("x942 y298 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(9), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(9, mainGui.AddPicture("x945 y301 w25 h25", ItemImages["SpeedyBoots"][2]))
        ShopPriority.Get(9).OnEvent("Click", (*) => ShopItemWorker(9, "SpeedyBoots"))
        ShopPriority.Get(9).Value := ItemImages["SpeedyBoots"][ShopItemEnabled.Get(9)]
        mainGui.Tips.SetTip(ShopPriority.Get(9), "Speedy Boots`r`n-20% SPA")

        ShopBG.Set(10, mainGUI.AddButton("x977 y298 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(10), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(10, mainGui.AddPicture("x980 y301 w25 h26", ItemImages["Fishhook"][2]))
        ShopPriority.Get(10).OnEvent("Click", (*) => ShopItemWorker(10, "Fishhook"))
        ShopPriority.Get(10).Value := ItemImages["Fishhook"][ShopItemEnabled.Get(10)]
        mainGui.Tips.SetTip(ShopPriority.Get(10), "Fishhook`r`n+20% Chest Luck")

        ShopBG.Set(11, mainGUI.AddButton("x837 y333 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(11), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(11, mainGui.AddPicture("x840 y336 w25 h25", ItemImages["NimbleCloak"][2]))
        ShopPriority.Get(11).OnEvent("Click", (*) => ShopItemWorker(11, "NimbleCloak"))
        ShopPriority.Get(11).Value := ItemImages["NimbleCloak"][ShopItemEnabled.Get(11)]
        mainGui.Tips.SetTip(ShopPriority.Get(11), "Nimble Cloak`r`n-7% SPA")

        ShopBG.Set(12, mainGUI.AddButton("x872 y333 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(12), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(12, mainGui.AddPicture("x875 y336 w25 h25", ItemImages["Sword"][2]))
        ShopPriority.Get(12).OnEvent("Click", (*) => ShopItemWorker(12, "Sword"))
        ShopPriority.Get(12).Value := ItemImages["Sword"][ShopItemEnabled.Get(12)]
        mainGui.Tips.SetTip(ShopPriority.Get(12), "Sword`r`n+30% Attack DMG")

        ShopBG.Set(13, mainGUI.AddButton("x907 y333 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(13), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(13, mainGui.AddPicture("x910 y336 w25 h26", ItemImages["Bow"][2]))
        ShopPriority.Get(13).OnEvent("Click", (*) => ShopItemWorker(13, "Bow"))
        ShopPriority.Get(13).Value := ItemImages["Bow"][ShopItemEnabled.Get(13)]
        mainGui.Tips.SetTip(ShopPriority.Get(13), "Bow`r`n+20% Range")

        ShopBG.Set(14, mainGUI.AddButton("x942 y333 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(14), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(14, mainGui.AddPicture("x945 y336 w25 h25", ItemImages["Dagger"][2]))
        ShopPriority.Get(14).OnEvent("Click", (*) => ShopItemWorker(14, "Dagger"))
        ShopPriority.Get(14).Value := ItemImages["Dagger"][ShopItemEnabled.Get(14)]
        mainGui.Tips.SetTip(ShopPriority.Get(14), "Dagger`r`n+15% Attack DMG")

        ShopBG.Set(15, mainGUI.AddButton("x977 y333 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(15), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(15, mainGui.AddPicture("x980 y336 w25 h25", ItemImages["ReaperScythe"][2]))
        ShopPriority.Get(15).OnEvent("Click", (*) => ShopItemWorker(15, "ReaperScythe"))
        ShopPriority.Get(15).Value := ItemImages["ReaperScythe"][ShopItemEnabled.Get(15)]
        mainGui.Tips.SetTip(ShopPriority.Get(15), "Reaper Scythe`r`n+75% DMG to Bosses")

        ShopBG.Set(16, mainGUI.AddButton("x837 y368 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(16), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(16, mainGui.AddPicture("x840 y373 w25 h21", ItemImages["GlacialAxe"][2]))
        ShopPriority.Get(16).OnEvent("Click", (*) => ShopItemWorker(16, "GlacialAxe"))
        ShopPriority.Get(16).Value := ItemImages["GlacialAxe"][ShopItemEnabled.Get(16)]
        mainGui.Tips.SetTip(ShopPriority.Get(16), "Glacial Axe`r`n-30% Enemy Speed")

        ShopBG.Set(17, mainGUI.AddButton("x872 y368 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(17), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(17, mainGui.AddPicture("x875 y371 w25 h26", ItemImages["MageCoat"][2]))
        ShopPriority.Get(17).OnEvent("Click", (*) => ShopItemWorker(17, "MageCoat"))
        ShopPriority.Get(17).Value := ItemImages["MageCoat"][ShopItemEnabled.Get(17)]
        mainGui.Tips.SetTip(ShopPriority.Get(17), "Mage Coat`r`n+50% Magic DMG")

        ShopBG.Set(18, mainGUI.AddButton("x907 y368 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(18), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(18, mainGui.AddPicture("x910 y371 w25 h26", ItemImages["Scimitar"][2]))
        ShopPriority.Get(18).OnEvent("Click", (*) => ShopItemWorker(18, "Scimitar"))
        ShopPriority.Get(18).Value := ItemImages["Scimitar"][ShopItemEnabled.Get(18)]
        mainGui.Tips.SetTip(ShopPriority.Get(18), "Scimitar`r`n+75% Attack DMG")

        ShopBG.Set(19, mainGUI.AddButton("x942 y368 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(19), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(19, mainGui.AddPicture("x945 y371 w25 h25", ItemImages["Headsplitter"][2]))
        ShopPriority.Get(19).OnEvent("Click", (*) => ShopItemWorker(19, "Headsplitter"))
        ShopPriority.Get(19).Value := ItemImages["Headsplitter"][ShopItemEnabled.Get(19)]
        mainGui.Tips.SetTip(ShopPriority.Get(19), "Headsplitter`r`n+75% Physical DMG")

        ShopBG.Set(20, mainGUI.AddButton("x977 y368 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(20), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(20, mainGui.AddPicture("x980 y370 w25 h27", ItemImages["GoldenBranch"][2]))
        ShopPriority.Get(20).OnEvent("Click", (*) => ShopItemWorker(20, "GoldenBranch"))
        ShopPriority.Get(20).Value := ItemImages["GoldenBranch"][ShopItemEnabled.Get(20)]
        mainGui.Tips.SetTip(ShopPriority.Get(20), "Golden Branch`r`n-15% UPG / Placement Cost")

        ShopBG.Set(21, mainGUI.AddButton("x837 y403 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(21), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(21, mainGui.AddPicture("x840 y406 w25 h25", ItemImages["IceDagger"][2]))
        ShopPriority.Get(21).OnEvent("Click", (*) => ShopItemWorker(21, "IceDagger"))
        ShopPriority.Get(21).Value := ItemImages["IceDagger"][ShopItemEnabled.Get(21)]
        mainGui.Tips.SetTip(ShopPriority.Get(21), "Ice Dagger`r`n-20% Enemy Speed")

        ShopBG.Set(22, mainGUI.AddButton("x872 y403 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(22), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(22, mainGui.AddPicture("x875 y406 w25 h25", ItemImages["ElfBow"][2]))
        ShopPriority.Get(22).OnEvent("Click", (*) => ShopItemWorker(22, "ElfBow"))
        ShopPriority.Get(22).Value := ItemImages["ElfBow"][ShopItemEnabled.Get(22)]
        mainGui.Tips.SetTip(ShopPriority.Get(22), "Elf Bow`r`n+50% Range")

        ShopBG.Set(23, mainGUI.AddButton("x907 y403 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(23), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(23, mainGui.AddPicture("x910 y407 w25 h24", ItemImages["PhilosophersStone"][2]))
        ShopPriority.Get(23).OnEvent("Click", (*) => ShopItemWorker(23, "PhilosophersStone"))
        ShopPriority.Get(23).Value := ItemImages["PhilosophersStone"][ShopItemEnabled.Get(23)]
        mainGui.Tips.SetTip(ShopPriority.Get(23), "Philosopher's Stone`r`nInstantly convert all chests to rare chests")

        ShopBG.Set(24, mainGUI.AddButton("x942 y403 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(24), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(24, mainGui.AddPicture("x945 y406 w25 h26", ItemImages["ArchmagesHat"][2]))
        ShopPriority.Get(24).OnEvent("Click", (*) => ShopItemWorker(24, "ArchmagesHat"))
        ShopPriority.Get(24).Value := ItemImages["ArchmagesHat"][ShopItemEnabled.Get(24)]
        mainGui.Tips.SetTip(ShopPriority.Get(24), "Archmage's Hat`r`n+250% Magic DMG")

        ShopBG.Set(25, mainGUI.AddButton("x977 y403 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(25), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(25, mainGui.AddPicture("x980 y405 w25 h27", ItemImages["GoldenFishhook"][2]))
        ShopPriority.Get(25).OnEvent("Click", (*) => ShopItemWorker(25, "GoldenFishhook"))
        ShopPriority.Get(25).Value := ItemImages["GoldenFishhook"][ShopItemEnabled.Get(25)]
        mainGui.Tips.SetTip(ShopPriority.Get(25), "Golden Fishhook`r`n+40% Chest Luck")

        ShopBG.Set(26, mainGUI.AddButton("x837 y438 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(26), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(26, mainGui.AddPicture("x840 y441 w25 h26", ItemImages["ShimmeringMoonFragment"][2]))
        ShopPriority.Get(26).OnEvent("Click", (*) => ShopItemWorker(26, "ShimmeringMoonFragment"))
        ShopPriority.Get(26).Value := ItemImages["ShimmeringMoonFragment"][ShopItemEnabled.Get(26)]
        mainGui.Tips.SetTip(ShopPriority.Get(26), "Shimmering Moon Fragment`r`n+1 Star Remnant to each Chest you open")

        /*ShopBG.Set(27, mainGUI.AddButton("x837 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(27), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(27, mainGui.AddPicture("x840 y266 w25 h25", ItemImages["Longbow"][2]))
        ShopPriority.Get(27).OnEvent("Click", (*) => ShopItemWorker(27, "Longbow"))
        ShopPriority.Get(27).Value := ItemImages["Longbow"][ShopItemEnabled.Get(27)]
        mainGui.Tips.SetTip(ShopPriority.Get(27), "Longbow`r`n+30% Range")
        
        ShopBG.Set(28, mainGUI.AddButton("x837 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(28), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(28, mainGui.AddPicture("x840 y266 w25 h25", ItemImages["Longbow"][2]))
        ShopPriority.Get(28).OnEvent("Click", (*) => ShopItemWorker(28, "Longbow"))
        ShopPriority.Get(28).Value := ItemImages["Longbow"][ShopItemEnabled.Get(28)]
        mainGui.Tips.SetTip(ShopPriority.Get(28), "Longbow`r`n+30% Range")
        
        ShopBG.Set(29, mainGUI.AddButton("x837 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(29), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(29, mainGui.AddPicture("x840 y266 w25 h25", ItemImages["Longbow"][2]))
        ShopPriority.Get(29).OnEvent("Click", (*) => ShopItemWorker(29, "Longbow"))
        ShopPriority.Get(29).Value := ItemImages["Longbow"][ShopItemEnabled.Get(29)]
        mainGui.Tips.SetTip(ShopPriority.Get(29), "Longbow`r`n+30% Range")
        
        ShopBG.Set(30, mainGUI.AddButton("x837 y263 Disabled w31 h31"))
        CreateImageButton(ShopBG.Get(30), 0, ButtonStyles["fake_for_group"]*)
        ShopPriority.Set(30, mainGui.AddPicture("x840 y266 w25 h25", ItemImages["Longbow"][2]))
        ShopPriority.Get(30).OnEvent("Click", (*) => ShopItemWorker(30, "Longbow"))
        ShopPriority.Get(30).Value := ItemImages["Longbow"][ShopItemEnabled.Get(30)]
        mainGui.Tips.SetTip(ShopPriority.Get(30), "Longbow`r`n+30% Range") */

        ;--- Keybind Settings ---
        ; - Keybind Box & Heading -
        holder := MaingUI.AddButton("x820 y487 w205 h143 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y492 w197 Center", "Hotkey Settings")

        ; - Resize -
        MainGUI.AddText("x830 y517 w45", "Resize:")
        holder := MainGUI.AddButton("x875 y512 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        resizeInput := MainGUI.AddEdit("Disabled x875 y512 w112 h25 Center", "")
        resizeInput.SetRounded(5)
        resizeInput.Value := BindToHotkey(resizeBind)
        ; - Resize Bind -
        BindResizeButton := MainGUI.AddButton("x992 y512 w25 h25", Chr(0xE104))
        BindResizeButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindResizeButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Start -
        MainGUI.AddText("x830 y546 w45", "Start:")
        holder := MainGUI.AddButton("x875 y541 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        startInput := MainGUI.AddEdit("Disabled x875 y541 w112 h25 Center", "")
        startInput.SetRounded(5)
        startInput.Value := BindToHotkey(startBind)
        ; - Start Bind -
        BindStartButton := MainGUI.AddButton("x992 y541 w25 h25", Chr(0xE104))
        BindStartButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindStartButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Stop -
        MainGUI.AddText("x830 y575 w45", "Stop:")
        holder := MainGUI.AddButton("x875 y570 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        stopInput := MainGUI.AddEdit("Disabled x875 y570 w112 h25 Center", "")
        stopInput.SetRounded(5)
        stopInput.Value := BindToHotkey(stopBind)
        ; - Stop Bind -
        BindStopButton := MainGUI.AddButton("x992 y570 w25 h25", Chr(0xE104))
        BindStopButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindStopButton, 0, ButtonStyles["fake_for_group"]*)

        ; - Pause -
        MainGUI.AddText("x830 y604 w45", "Pause:")
        holder := MainGUI.AddButton("x875 y599 w112 h25 Disabled")
        CreateImageButton(holder, 0, ButtonStyles["fake_for_group"]*)
        pauseInput := MainGUI.AddEdit("Disabled x875 y599 w112 h25 Center", "")
        pauseInput.SetRounded(5)
        pauseInput.Value := BindToHotkey(pauseBind)
        ; - Pause Bind -
        BindPauseButton := MainGUI.AddButton("x992 y599 w25 h25", Chr(0xE104))
        BindPauseButton.OnEvent("Click", BindHotkeyButton)
        CreateImageButton(BindPauseButton, 0, ButtonStyles["fake_for_group"]*)
    }

    Maintab2() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 2")

        PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Main"))
        CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        ;NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        ;NextButton.OnEvent("Click", (*) => TabCtrl.Choose("MainTab2"))
        ;CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; --- Congfigs ---
        holder := MaingUI.AddButton("x820 y62 w205 h110 0x100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y67 Center w197 h15", "Configs")

        MainGUI.AddText("x830 y90 w125", "Config Name")
        inputholder := MainGUI.AddButton("x830 y108 w125 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        ConfigInput := MainGUI.AddEdit("x830 y108 w125 h25", "")
        ConfigInput.SetRounded(5)

        UploadButton := mainGui.AddButton("x960 y108 w55 h25", "Upload")
        CreateImageButton(UploadButton, 0, ButtonStyles["default"]*)

        LoadButton := mainGui.AddButton("x873 y141 w100 h25", "Load Config")
        CreateImageButton(LoadButton, 0, ButtonStyles["default"]*)

        ; --- Reconnect ---
        holder := MaingUI.AddButton("x820 y188 w205 h89 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y196 Center w197", "Reconnect")

        TestRCButton := mainGui.AddButton("x978 y195 w40 h19", "Test")
        TestRCButton.OnEvent("Click", (*) => testReconnect())
        CreateImageButton(TestRCButton, 0, ButtonStyles["default"]*)

        MainGUI.AddText("x830 y222 Left w193", "Private Server Link")
        inputholder := MainGUI.AddButton("x830 y242 w185 h25 Disabled")
        CreateImageButton(inputholder, 0, ButtonStyles["fake_for_group"]*)
        PServerInput := MainGUI.AddEdit("x830 y242 w185 h25", "")
        PServerInput.Text := PServerURL
        PServerInput.OnEvent('Change', (*) => GUISave())
        PServerInput.SetRounded(5)

        ; --- Misc ---
        holder := MaingUI.AddButton("x820 y293 w205 h100 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)

        MainGUI.AddText("x824 y301 Center w197", "Misc")

        global RPCCheckbox := MainGUI.AddCheckBox("x830 y323 h" SGH " w" SGW)
        RPCCheckbox.Value := RichPresenceE
        RPCCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y323", " Discord Rich Presence")

        global StatWCheckbox := MainGUI.AddCheckBox("x830 y345 h" SGH " w" SGW)
        StatWCheckbox.Value := StatWebsiteE
        MainGUI.AddText("x845 y345", " Stats Website")

        OpenSWButton := MaingUI.AddButton("x968 y345 w50 h16 Center", "Open")
        CreateImageButton(OpenSWButton, 0, ButtonStyles["default"]*)

        global DebugCheckbox := MainGUI.AddCheckBox("x830 y367 h" SGH " w" SGW)
        DebugCheckbox.Value := DEBUG
        DebugCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y367", " Debug Mode")

        ; --- DEBUG ---
        /*holder := MaingUI.AddButton("x820 y398 w205 h50 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        
        MainGUI.AddText("x824 y406 Center w197", "Debug")
        
        global DebugCheckbox := MainGUI.AddCheckBox("x830 y426 h" SGH " w" SGW)
        DebugCheckbox.Value := DEBUG
        DebugCheckbox.OnEvent('Click', (*) => GUISave())
        MainGUI.AddText("x845 y426", " Enabled") */

    }
}

WaitForBind(Options := "T5") {
    global ih := InputHook(Options)
    if !InStr(Options, "V")
        ih.VisibleNonText := false
    ih.KeyOpt("{All}", "E")
    ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    ih.Start()
    ih.Wait()
    return StrReplace(StrReplace(ih.EndMods . ih.EndKey, "<", ""), ">", "")
}

CancelInputHook() {
    global ih
    if (ih) {
        ih.Stop()
        return true
    } else {
        return false
    }
}

BindHotkey(BtnObj) {
    try {
        global CurrentBindsRecords
        ; TODO: cancel input hook, and set the button back to normal
        BtnObj.Text := Chr(0xE15B)
        CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
        CurrentBindsRecords := BtnObj.Hwnd
        tbind := WaitForBind()
        if tbind != "" {
            if BtnObj == BindResizeButton {
                global resizeBind
                Hotkey(resizeBind, "off")
                resizeBind := tbind
                resizeInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindStartButton {
                global startBind
                Hotkey(startBind, "off")
                startBind := tbind
                startInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindStopButton {
                global stopBind
                Hotkey(stopBind, "off")
                stopBind := tbind
                stopInput.Text := BindToHotkey(tbind)
            }
            else if BtnObj == BindPauseButton {
                global pauseBind
                Hotkey(pauseBind, "off")
                pauseBind := tbind
                pauseInput.Text := BindToHotkey(tbind)
            }
            SaveCfg()
        }
        BtnObj.Text := Chr(0xE104)
        CreateImageButton(BtnObj, 0, ButtonStyles["fake_for_group"]*)
        CurrentBindsRecords := ""
    }
}
BindHotkeyButton(BtnObj, *) {
    BindHotkey(BtnObj)
}
BindToHotkey(keys) {
    return StrReplace(StrReplace(StrReplace(StrReplace(keys, "+", "Shift + "), "^", "Ctrl + "), "!", "Alt + "), "#",
    "Win + ")
}

SaveCfg(*) {
    GUISave()
    Hotkey(resizeBind, start_write_non_ui)
    Hotkey(startBind, start_write_non_ui)
    Hotkey(stopBind, start_write_non_ui)
    Hotkey(pauseBind, start_write_non_ui)
}

start_write_non_ui(*) {
    global status
    status := 1
    ;start_write(false)
}