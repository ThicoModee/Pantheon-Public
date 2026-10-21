#Requires AutoHotkey v2.0
#Include gui.ahk

UnitsTab() {
    global UPCheckbox,PSInput, PLDDL, PathMappingDDL
    global CurseInput := Map()
    global SPACurse := Map()
    global SPABG := Map(), TypeBG := Map(), UpgPrioBG := Map(), PlacementBG := Map(), UpgBG := Map()
    global TypeDDL := Map(), UpgDDL := Map(), PlacementDDL := Map(), UpgPrioDDL := Map()
    global unitCheckbox := Map()

    placementsList := ["1", "2", "3", "4", "5"]
    UPGPrioList := ["1", "2", "3", "4", "5", "6"]
    UPGList := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "MAX"]
    TypeList := ["DPS", "Ground", "Hill", "Buff", "Farm"]
    PlacementLogicList := ["Automatic", "Spiral", "Manual"]
    PathMappingList := ["Unit 1", "Unit 2", "Unit 3", "Unit 4", "Unit 5", "Unit 6"]

    ; --- Upgrade Priority ---
    holder := MaingUI.AddButton("x820 y496 w205 h134 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)

    MainGUI.AddText("x824 y504 w197 Center", "Settings")

    UPCheckbox := MainGUI.AddCheckBox("x830 y525 h" SGH " w" SGW)
    UPCheckbox.Value := UpgradePriorityE
    UPCheckbox.OnEvent('Click', (*) => GUISave())
    MainGUI.AddText("x845 y525 w170 h16", " Unit Upgrade Priority")

    ; --- Unit Placement Speed Adjuster ---
    MainGUI.AddText("x830 y549 w193", "Placement Speed (ms)")

    BG := MainGUI.AddButton("x830 y567 w185 h25 Disabled")
    CreateImageButton(BG, 0, ButtonStyles["fake_for_group"]*)
    PSInput := MainGUI.AddEdit("x830 y567 w185 h25", "")
    PSInput.Text := PlacementSpeed
    PSInput.OnEvent('Change', (*) => GUISave())
    PSInput.SetRounded(5)

    ;--- Placement Logic ---
    MainGUI.AddText("x830 y602 w115", "Placement Mode")

    PLLBG := mainGUI.AddButton("x945 y597 Disabled w70 h25 Center", PlacementLogicList[PlacementLogicFM])
    CreateImageButton(PLLBG, 0, ButtonStyles["fake_for_group"]*)
    PLDDL := mainGUI.AddDropDownList("x945 y597 w70 +0x4000000", PlacementLogicList)
    PLDDL.OnEvent("Change", (*) => DropDownListWorker(PLDDL, PlacementLogicList, PLLBG))
    PLDDL.Text := PlacementLogicList[PlacementLogicFM]

    UnitsTab1()

    TabCtrl.UseTab("UnitsTab2")
    UnitsTab2()

    UnitsTab1() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 1")

        ;PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        ;PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Units"))
        ;CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        NextButton.OnEvent("Click", (*) => TabCtrl.Choose("UnitsTab2"))
        CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; --- Unit 1 ---
        holder := MainGui.AddButton("x820 y62 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y69 w197 h18 Center", "Unit 1")

        unitCheckbox.Set(1, MainGUI.AddCheckBox("x826 y68 h" SGH " w" SGW))
        unitCheckbox.Get(1).Value := UnitEnabled.Get(1)
        unitCheckbox.Get(1).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(1, mainGUI.AddButton("x969 y68 Disabled w50 h20 Center", TypeList[typeFM.Get(1)]))
        CreateImageButton(TypeBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(1, mainGUI.AddDropDownList("x969 y68 w50 +0x4000000", TypeList))
        TypeDDL.Get(1).OnEvent("Change", (*) => ChangeType(1, TypeDDL.Get(1), TypeList, TypeBG.Get(1)))
        TypeDDL.Get(1).Text := TypeList[typeFM.Get(1)]

        MainGUI.AddText("x828 y95", "Placements")
        PlacementBG.Set(1, mainGUI.AddButton("x896 y93 Disabled w35 h20 Center", placementsList[placementFM.Get(1)]))
        CreateImageButton(PlacementBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(1, mainGUI.AddDropDownList("x896 y93 w35 +0x4000000", placementsList))
        PlacementDDL.Get(1).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(1), placementsList, PlacementBG.Get(1)))
        PlacementDDL.Get(1).Text := placementsList[placementFM.Get(1)]

        MainGUI.AddText("x828 y123", "Upgrade Priority")
        UpgPrioBG.Set(1, mainGUI.AddButton("x923 y121 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(1)]))
        CreateImageButton(UpgPrioBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(1, mainGUI.AddDropDownList("x923 y121 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(1).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(1), UPGPrioList, UpgPrioBG.Get(1)))
        UpgPrioDDL.Get(1).Text := UPGPrioList[UpgPrioFM.Get(1)]

        MainGUI.AddText("x828 y151", "Upgrades")
        UpgBG.Set(1, mainGUI.AddButton("x886 y149 Disabled w35 h20 Center", UPGList[UpgFM.Get(1)]))
        CreateImageButton(UpgBG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(1, mainGUI.AddDropDownList("x886 y149 w35 +0x4000000", UPGList))
        UpgDDL.Get(1).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(1), UPGList, UpgBG.Get(1)))
        UpgDDL.Get(1).Text := UPGList[UpgFM.Get(1)]

        SPACurse.Set(1, MainGUI.AddText("x959 y141 w60 Right Hidden", "SPA Curse"))

        SPABG.Set(1, MainGUI.AddButton("x969 y156 w50 h20 Disabled Center Hidden"))
        CreateImageButton(SPABG.Get(1), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(1, MainGUI.AddEdit("x969 y156 w50 h20 Center Hidden", ""))
        CurseInput.Get(1).Text := CurseContents.Get(1)
        CurseInput.Get(1).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(1).SetRounded(5)

        ; --- Unit 2 ---
        holder := MainGui.AddButton("x820 y198 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y205 w197 h18 Center", "Unit 2")

        unitCheckbox.Set(2, MainGUI.AddCheckBox("x826 y204 h" SGH " w" SGW))
        unitCheckbox.Get(2).Value := UnitEnabled.Get(2)
        unitCheckbox.Get(2).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(2, mainGUI.AddButton("x969 y204 Disabled w50 h20 Center", TypeList[typeFM.Get(2)]))
        CreateImageButton(TypeBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(2, mainGUI.AddDropDownList("x969 y204 w50 +0x4000000", TypeList))
        TypeDDL.Get(2).OnEvent("Change", (*) => ChangeType(2, TypeDDL.Get(2), TypeList, TypeBG.Get(2)))
        TypeDDL.Get(2).Text := TypeList[typeFM.Get(2)]

        MainGUI.AddText("x828 y231", "Placements")
        PlacementBG.Set(2, mainGUI.AddButton("x896 y229 Disabled w35 h20 Center", placementsList[placementFM.Get(2)]))
        CreateImageButton(PlacementBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(2, mainGUI.AddDropDownList("x896 y229 w35 +0x4000000", placementsList))
        PlacementDDL.Get(2).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(2), placementsList, PlacementBG.Get(2)))
        PlacementDDL.Get(2).Text := placementsList[placementFM.Get(2)]

        MainGUI.AddText("x828 y259", "Upgrade Priority")
        UpgPrioBG.Set(2, mainGUI.AddButton("x923 y257 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(2)]))
        CreateImageButton(UpgPrioBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(2, mainGUI.AddDropDownList("x923 y257 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(2).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(2), UPGPrioList, UpgPrioBG.Get(2)))
        UpgPrioDDL.Get(2).Text := UPGPrioList[UpgPrioFM.Get(2)]

        MainGUI.AddText("x828 y287", "Upgrades")
        UpgBG.Set(2, mainGUI.AddButton("x886 y285 Disabled w35 h20 Center", UPGList[UpgFM.Get(2)]))
        CreateImageButton(UpgBG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(2, mainGUI.AddDropDownList("x886 y285 w35 +0x4000000", UPGList))
        UpgDDL.Get(2).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(2), UPGList, UpgBG.Get(2)))
        UpgDDL.Get(2).Text := UPGList[UpgFM.Get(2)]

        SPACurse.Set(2, MainGUI.AddText("x959 y277 w60 Center Hidden", "SPA Curse"))

        SPABG.Set(2, MainGUI.AddButton("x969 y292 w50 h20 Disabled Hidden Center"))
        CreateImageButton(SPABG.Get(2), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(2, MainGUI.AddEdit("x969 y292 w50 h20 Hidden Center", ""))
        CurseInput.Get(2).Text := CurseContents.Get(2)
        CurseInput.Get(2).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(2).SetRounded(5)

        ; --- Unit 3 ---
        holder := MainGui.AddButton("x820 y334 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y341 w197 h18 Center", "Unit 3")

        unitCheckbox.Set(3, MainGUI.AddCheckBox("x826 y340 h" SGH " w" SGW))
        unitCheckbox.Get(3).Value := UnitEnabled.Get(3)
        unitCheckbox.Get(3).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(3, mainGUI.AddButton("x969 y340 Disabled w50 h20 Center", TypeList[typeFM.Get(3)]))
        CreateImageButton(TypeBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(3, mainGUI.AddDropDownList("x969 y340 w50 +0x4000000", TypeList))
        TypeDDL.Get(3).OnEvent("Change", (*) => ChangeType(3, TypeDDL.Get(3), TypeList, TypeBG.Get(3)))
        TypeDDL.Get(3).Text := TypeList[typeFM.Get(3)]

        MainGUI.AddText("x828 y367", "Placements")
        PlacementBG.Set(3, mainGUI.AddButton("x896 y365 Disabled w35 h20 Center", placementsList[placementFM.Get(3)]))
        CreateImageButton(PlacementBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(3, mainGUI.AddDropDownList("x896 y365 w35 +0x4000000", placementsList))
        PlacementDDL.Get(3).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(3), placementsList, PlacementBG.Get(3)))
        PlacementDDL.Get(3).Text := placementsList[placementFM.Get(3)]

        MainGUI.AddText("x828 y395", "Upgrade Priority")
        UpgPrioBG.Set(3, mainGUI.AddButton("x923 y393 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(3)]))
        CreateImageButton(UpgPrioBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(3, mainGUI.AddDropDownList("x923 y393 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(3).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(3), UPGPrioList, UpgPrioBG.Get(3)))
        UpgPrioDDL.Get(3).Text := UPGPrioList[UpgPrioFM.Get(3)]

        MainGUI.AddText("x828 y423", "Upgrades")
        UpgBG.Set(3, mainGUI.AddButton("x886 y421 Disabled w35 h20 Center", UPGList[UpgFM.Get(3)]))
        CreateImageButton(UpgBG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(3, mainGUI.AddDropDownList("x886 y421 w35 +0x4000000", UPGList))
        UpgDDL.Get(3).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(3), UPGList, UpgBG.Get(3)))
        UpgDDL.Get(3).Text := UPGList[UpgFM.Get(3)]

        SPACurse.Set(3, MainGUI.AddText("x959 y413 w60 Right Hidden", "SPA Curse"))

        SPABG.Set(3, MainGUI.AddButton("x969 y428 w50 h20 Disabled Hidden Center"))
        CreateImageButton(SPABG.Get(3), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(3, MainGUI.AddEdit("x969 y428 w50 h20 Hidden Center", ""))
        CurseInput.Get(3).Text := CurseContents.Get(3)
        CurseInput.Get(3).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(3).SetRounded(5)

        holder := MainGui.AddButton("x820 y462 w205 h26 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y467 w85 Center", "Path Mapping")

        PathMappingBG := MainGUI.AddButton("x909 y466 Disabled w60 h18 Center", PathMappingList[PathMappingFM])
        CreateImageButton(PathMappingBG, 0, ButtonStyles["fake_for_group"]*)
        PathMappingDDL := MainGUI.AddDropDownList("x909 y466 w60 +0x4000000", PathMappingList)
        PathMappingDDL.OnEvent("Change", (*) => DropDownListWorker(PathMappingDDL, PathMappingList, PathMappingBG))
        PathMappingDDL.Text := PathMappingList[PathMappingFM]

        HelpButton := mainGui.AddButton("x1000 y466 w18 h18", "?")
        HelpButton.OnEvent("Click", (*) => MsgBox("Please select a unit that is either a Farm/Buff/Hybrid for placements to work properly."))
        CreateImageButton(HelpButton, 0, ButtonStyles["default"]*)
    }

    UnitsTab2() {
        MainGUI.AddText("x852 y18 Center w141 h16", "Page 2")

        PreviousButton := mainGui.AddButton("x820 y10 w32 h32", "<")
        PreviousButton.OnEvent("Click", (*) => TabCtrl.Choose("Units"))
        CreateImageButton(PreviousButton, 0, ButtonStyles["default"]*)

        ;NextButton := mainGui.AddButton("x993 y10 w32 h32", ">")
        ;NextButton.OnEvent("Click", (*) => TabCtrl.Choose("UnitsTab3"))
        ;CreateImageButton(NextButton, 0, ButtonStyles["default"]*)

        ; --- Unit 4 ---
        holder := MainGui.AddButton("x820 y62 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y69 w197 h18 Center", "Unit 4")

        unitCheckbox.Set(4, MainGUI.AddCheckBox("x826 y68 h" SGH " w" SGW))
        unitCheckbox.Get(4).Value := UnitEnabled.Get(4)
        unitCheckbox.Get(4).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(4, mainGUI.AddButton("x969 y68 Disabled w50 h20 Center", TypeList[typeFM.Get(4)]))
        CreateImageButton(TypeBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(4, mainGUI.AddDropDownList("x969 y68 w50 +0x4000000", TypeList))
        TypeDDL.Get(4).OnEvent("Change", (*) => ChangeType(4, TypeDDL.Get(4), TypeList, TypeBG.Get(4)))
        TypeDDL.Get(4).Text := TypeList[typeFM.Get(4)]

        MainGUI.AddText("x828 y95", "Placements")
        PlacementBG.Set(4, mainGUI.AddButton("x896 y93 Disabled w35 h20 Center", placementsList[placementFM.Get(4)]))
        CreateImageButton(PlacementBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(4, mainGUI.AddDropDownList("x896 y93 w35 +0x4000000", placementsList))
        PlacementDDL.Get(4).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(4), placementsList, PlacementBG.Get(4)))
        PlacementDDL.Get(4).Text := placementsList[placementFM.Get(4)]

        MainGUI.AddText("x828 y123", "Upgrade Priority")
        UpgPrioBG.Set(4, mainGUI.AddButton("x923 y121 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(4)]))
        CreateImageButton(UpgPrioBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(4, mainGUI.AddDropDownList("x923 y121 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(4).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(4), UPGPrioList, UpgPrioBG.Get(4)))
        UpgPrioDDL.Get(4).Text := UPGPrioList[UpgPrioFM.Get(4)]

        MainGUI.AddText("x828 y151", "Upgrades")
        UpgBG.Set(4, mainGUI.AddButton("x886 y149 Disabled w35 h20 Center", UPGList[UpgFM.Get(4)]))
        CreateImageButton(UpgBG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(4, mainGUI.AddDropDownList("x886 y149 w35 +0x4000000", UPGList))
        UpgDDL.Get(4).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(4), UPGList, UpgBG.Get(4)))
        UpgDDL.Get(4).Text := UPGList[UpgFM.Get(4)]

        SPACurse.Set(4, MainGUI.AddText("x959 y141 w60 Right Hidden", "SPA Curse"))

        SPABG.Set(4, MainGUI.AddButton("x969 y156 w50 h20 Disabled Center Hidden"))
        CreateImageButton(SPABG.Get(4), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(4, MainGUI.AddEdit("x969 y156 w50 h20 Center Hidden", ""))
        CurseInput.Get(4).Text := CurseContents.Get(4)
        CurseInput.Get(4).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(4).SetRounded(5)

        ; --- Unit 5 ---
        holder := MainGui.AddButton("x820 y198 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y205 w197 h18 Center", "Unit 5")

        unitCheckbox.Set(5, MainGUI.AddCheckBox("x826 y204 h" SGH " w" SGW))
        unitCheckbox.Get(5).Value := UnitEnabled.Get(5)
        unitCheckbox.Get(5).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(5, mainGUI.AddButton("x969 y204 Disabled w50 h20 Center", TypeList[typeFM.Get(5)]))
        CreateImageButton(TypeBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(5, mainGUI.AddDropDownList("x969 y204 w50 +0x4000000", TypeList))
        TypeDDL.Get(5).OnEvent("Change", (*) => ChangeType(5, TypeDDL.Get(5), TypeList, TypeBG.Get(5)))
        TypeDDL.Get(5).Text := TypeList[typeFM.Get(5)]

        MainGUI.AddText("x828 y231", "Placements")
        PlacementBG.Set(5, mainGUI.AddButton("x896 y229 Disabled w35 h20 Center", placementsList[placementFM.Get(5)]))
        CreateImageButton(PlacementBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(5, mainGUI.AddDropDownList("x896 y229 w35 +0x4000000", placementsList))
        PlacementDDL.Get(5).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(5), placementsList, PlacementBG.Get(5)))
        PlacementDDL.Get(5).Text := placementsList[placementFM.Get(5)]

        MainGUI.AddText("x828 y259", "Upgrade Priority")
        UpgPrioBG.Set(5, mainGUI.AddButton("x923 y257 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(5)]))
        CreateImageButton(UpgPrioBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(5, mainGUI.AddDropDownList("x923 y257 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(5).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(5), UPGPrioList, UpgPrioBG.Get(5)))
        UpgPrioDDL.Get(5).Text := UPGPrioList[UpgPrioFM.Get(5)]

        MainGUI.AddText("x828 y287", "Upgrades")
        UpgBG.Set(5, mainGUI.AddButton("x886 y285 Disabled w35 h20 Center", UPGList[UpgFM.Get(5)]))
        CreateImageButton(UpgBG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(5, mainGUI.AddDropDownList("x886 y285 w35 +0x4000000", UPGList))
        UpgDDL.Get(5).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(5), UPGList, UpgBG.Get(5)))
        UpgDDL.Get(5).Text := UPGList[UpgFM.Get(5)]

        SPACurse.Set(5, MainGUI.AddText("x959 y277 w60 Center Hidden", "SPA Curse"))

        SPABG.Set(5, MainGUI.AddButton("x969 y292 w50 h20 Disabled Hidden Center"))
        CreateImageButton(SPABG.Get(5), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(5, MainGUI.AddEdit("x969 y292 w50 h20 Hidden Center", ""))
        CurseInput.Get(5).Text := CurseContents.Get(5)
        CurseInput.Get(5).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(5).SetRounded(5)

        ; --- Unit 6 ---
        holder := MainGui.AddButton("x820 y334 w205 h120 Disabled", "")
        CreateImageButton(holder, 0, ButtonStyles["holder"]*)
        MainGUI.AddText("x824 y341 w197 h18 Center", "Unit 6")

        unitCheckbox.Set(6, MainGUI.AddCheckBox("x826 y340 h" SGH " w" SGW))
        unitCheckbox.Get(6).Value := UnitEnabled.Get(6)
        unitCheckbox.Get(6).OnEvent('Click', (*) => GUISave())

        TypeBG.Set(6, mainGUI.AddButton("x969 y340 Disabled w50 h20 Center", TypeList[typeFM.Get(6)]))
        CreateImageButton(TypeBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        TypeDDL.Set(6, mainGUI.AddDropDownList("x969 y340 w50 +0x4000000", TypeList))
        TypeDDL.Get(6).OnEvent("Change", (*) => ChangeType(6, TypeDDL.Get(6), TypeList, TypeBG.Get(6)))
        TypeDDL.Get(6).Text := TypeList[typeFM.Get(6)]

        MainGUI.AddText("x828 y367", "Placements")
        PlacementBG.Set(6, mainGUI.AddButton("x896 y365 Disabled w35 h20 Center", placementsList[placementFM.Get(6)]))
        CreateImageButton(PlacementBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        PlacementDDL.Set(6, mainGUI.AddDropDownList("x896 y365 w35 +0x4000000", placementsList))
        PlacementDDL.Get(6).OnEvent("Change", (*) => DropDownListWorker(PlacementDDL.Get(6), placementsList, PlacementBG.Get(6)))
        PlacementDDL.Get(6).Text := placementsList[placementFM.Get(6)]

        MainGUI.AddText("x828 y395", "Upgrade Priority")
        UpgPrioBG.Set(6, mainGUI.AddButton("x923 y393 Disabled w35 h20 Center", UPGPrioList[UpgPrioFM.Get(6)]))
        CreateImageButton(UpgPrioBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        UpgPrioDDL.Set(6, mainGUI.AddDropDownList("x923 y393 w35 +0x4000000", UPGPrioList))
        UpgPrioDDL.Get(6).OnEvent("Change", (*) => DropDownListWorker(UpgPrioDDL.Get(6), UPGPrioList, UpgPrioBG.Get(6)))
        UpgPrioDDL.Get(6).Text := UPGPrioList[UpgPrioFM.Get(6)]

        MainGUI.AddText("x828 y423", "Upgrades")
        UpgBG.Set(6, mainGUI.AddButton("x886 y421 Disabled w35 h20 Center", UPGList[UpgFM.Get(6)]))
        CreateImageButton(UpgBG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        UpgDDL.Set(6, mainGUI.AddDropDownList("x886 y421 w35 +0x4000000", UPGList))
        UpgDDL.Get(6).OnEvent("Change", (*) => DropDownListWorker(UpgDDL.Get(6), UPGList, UpgBG.Get(6)))
        UpgDDL.Get(6).Text := UPGList[UpgFM.Get(6)]

        SPACurse.Set(6, MainGUI.AddText("x959 y413 w60 Right Hidden", "SPA Curse"))

        SPABG.Set(6, MainGUI.AddButton("x969 y428 w50 h20 Disabled Hidden Center"))
        CreateImageButton(SPABG.Get(6), 0, ButtonStyles["fake_for_group"]*)
        CurseInput.Set(6, MainGUI.AddEdit("x969 y428 w50 h20 Hidden Center", ""))
        CurseInput.Get(6).Text := CurseContents.Get(6)
        CurseInput.Get(6).OnEvent('Change', (*) => GUISave())
        CurseInput.Get(6).SetRounded(5)
    }
}
