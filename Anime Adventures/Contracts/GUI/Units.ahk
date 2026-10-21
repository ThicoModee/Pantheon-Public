#Requires AutoHotkey v2.0
#Include gui.ahk

UnitsTab() {
    global Unit1Checkbox, Unit2Checkbox, Unit3Checkbox, Unit4Checkbox, Unit5Checkbox, Unit6Checkbox, UPCheckbox, PSInput
    global PMDDL1, PMDDL2, PMDDL3, PMDDL4, PMDDL5, PMDDL6, PLDDL
    global UPGDDL1, UPGDDL2, UPGDDL3, UPGDDL4, UPGDDL5, UPGDDL6
    global TypeDDL1, TypeDDL2, TypeDDL3, TypeDDL4, TypeDDL5, TypeDDL6

    placementsList := ["1", "2", "3", "4", "5"]
    UPGPList := ["1", "2", "3", "4", "5", "6"]
    TypeList := ["DPS", "Ground", "Hill", "Buff", "Farm"]
    PlacementLogicList := ["Automatic", "Spiral", "Manual"]

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
    PSInput.SetRounded(7)

    ;--- Placement Logic ---
    MainGUI.AddText("x830 y602 w115", "Placement Mode")

    PLLBG := mainGUI.AddButton("x945 y597 Disabled w70 h25 Center", PlacementLogicList[PlacementLogicFM])
    CreateImageButton(PLLBG, 0, ButtonStyles["fake_for_group"]*)
    PLDDL := mainGUI.AddDropDownList("x945 y597 w70 +0x4000000", PlacementLogicList)
    PLDDL.OnEvent("Change", (*) => DropDownListWorker(PLDDL, PlacementLogicList, PLLBG))
    PLDDL.Text := PlacementLogicList[PlacementLogicFM]

    ; --- Unit 1 ---
    holder := MaingUI.AddButton("x820 y10 w205 h73 0x100 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y17 w197 Center", "Unit 1")

    Unit1Checkbox := MainGUI.AddCheckBox("x828 y16 h" SGH " w" SGW)
    Unit1Checkbox.Value := Unit1Enabled
    Unit1Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y38", "Placements")
    PlacementBG1 := mainGUI.AddButton("x898 y36 Disabled w20 h20 Center ", placementsList[placementFM1])
    CreateImageButton(PlacementBG1, 0, ButtonStyles["fake_for_group"]*)
    PMDDL1 := mainGUI.AddDropDownList("x898 y36 w20 +0x4000000", placementsList)
    PMDDL1.OnEvent("Change", (*) => DropDownListWorker(PMDDL1, placementsList, PlacementBG1))
    PMDDL1.Text := placementsList[placementFM1]

    MainGUI.AddText("x830 y60", "Upgrade Priority")
    UpgBG1 := mainGUI.AddButton("x923 y58 Disabled w20 h20 Center", UPGPList[UpgFM1])
    CreateImageButton(UpgBG1, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL1 := mainGUI.AddDropDownList("x923 y58 w20 +0x4000000", UPGPList)
    UPGDDL1.OnEvent("Change", (*) => DropDownListWorker(UPGDDL1, UPGPList, UpgBG1))
    UPGDDL1.Text := UPGPList[UpgFM1]

    TypeBG1 := mainGUI.AddButton("x970 y15 Disabled w50 h20 Center", TypeList[typeFM1])
    CreateImageButton(TypeBG1, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL1 := mainGUI.AddDropDownList("x970 y15 w50 +0x4000000", TypeList)
    TypeDDL1.OnEvent("Change", (*) => DropDownListWorker(TypeDDL1, TypeList, TypeBG1))
    TypeDDL1.Text := TypeList[typeFM1]

    ; --- Unit 2 ---
    holder := MaingUI.AddButton("x820 y91 w205 h73 0x100 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y98 w197 Center", "Unit 2")

    Unit2Checkbox := MainGUI.AddCheckBox(" x828 y97 h" SGH " w" SGW)
    Unit2Checkbox.Value := Unit2Enabled
    Unit2Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y119", "Placements")
    PlacementBG2 := mainGUI.AddButton("x898 y117 Disabled w20 h20 Center", placementsList[placementFM2])
    CreateImageButton(PlacementBG2, 0, ButtonStyles["fake_for_group"]*)
    PMDDL2 := mainGUI.AddDropDownList("x898 y117 w20 +0x4000000", placementsList)
    PMDDL2.OnEvent("Change", (*) => DropDownListWorker(PMDDL2, placementsList, PlacementBG2))
    PMDDL2.OnEvent('Change', (*) => GUISave())
    PMDDL2.Text := placementsList[placementFM2]

    MainGUI.AddText("x830 y141", "Upgrade Priority")
    UpgBG2 := mainGUI.AddButton("x923 y139 Disabled w20 h20 Center", UPGPList[UpgFM2])
    CreateImageButton(UpgBG2, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL2 := mainGUI.AddDropDownList("x923 y139 w20 +0x4000000", UPGPList)
    UPGDDL2.OnEvent("Change", (*) => DropDownListWorker(UPGDDL2, UPGPList, UpgBG2))
    UPGDDL2.Text := UPGPList[UpgFM2]

    TypeBG2 := mainGUI.AddButton("x970 y96 Disabled w50 h20 Center", TypeList[typeFM2])
    CreateImageButton(TypeBG2, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL2 := mainGUI.AddDropDownList("x970 y96 w50 +0x4000000", TypeList)
    TypeDDL2.OnEvent("Change", (*) => DropDownListWorker(TypeDDL2, TypeList, TypeBG2))
    TypeDDL2.Text := TypeList[typeFM2]

    ; --- Unit 3 ---
    holder := MaingUI.AddButton("x820 y172 w205 h73 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y179 w197 Center", "Unit 3")

    Unit3Checkbox := MainGUI.AddCheckBox("x828 y178 h" SGH " w" SGW)
    Unit3Checkbox.Value := Unit3Enabled
    Unit3Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y200", "Placements")
    PlacementBG3 := mainGUI.AddButton("x898 y198 Disabled w20 h20 Center", placementsList[placementFM3])
    CreateImageButton(PlacementBG3, 0, ButtonStyles["fake_for_group"]*)
    PMDDL3 := mainGUI.AddDropDownList("x898 y198 w20 +0x4000000", placementsList)
    PMDDL3.OnEvent("Change", (*) => DropDownListWorker(PMDDL3, placementsList, PlacementBG3))
    PMDDL3.Text := placementsList[placementFM3]

    MainGUI.AddText("x830 y222", "Upgrade Priority")
    UpgBG3 := mainGUI.AddButton("x923 y220 Disabled w20 h20 Center", UPGPList[UpgFM3])
    CreateImageButton(UpgBG3, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL3 := mainGUI.AddDropDownList("x923 y220 w20 +0x4000000", UPGPList)
    UPGDDL3.OnEvent("Change", (*) => DropDownListWorker(UPGDDL3, UPGPList, UpgBG3))
    UPGDDL3.Text := UPGPList[UpgFM3]

    TypeBG3 := mainGUI.AddButton("x970 y177 Disabled w50 h20 Center", TypeList[typeFM3])
    CreateImageButton(TypeBG3, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL3 := mainGUI.AddDropDownList("x970 y177 w50 +0x4000000", TypeList)
    TypeDDL3.OnEvent("Change", (*) => DropDownListWorker(TypeDDL3, TypeList, TypeBG3))
    TypeDDL3.Text := TypeList[typeFM3]

    ; --- Unit 4 ---
    holder := MaingUI.AddButton("x820 y253 w205 h73 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y260 w197 Center", "Unit 4")

    Unit4Checkbox := MainGUI.AddCheckBox("x828 y259 h" SGH " w" SGW)
    Unit4Checkbox.Value := Unit4Enabled
    Unit4Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y281", "Placements")
    PlacementBG4 := mainGUI.AddButton("x898 y279 Disabled w20 h20 Center", placementsList[placementFM4])
    CreateImageButton(PlacementBG4, 0, ButtonStyles["fake_for_group"]*)
    PMDDL4 := mainGUI.AddDropDownList("x898 y279 w20 +0x4000000", placementsList)
    PMDDL4.OnEvent("Change", (*) => DropDownListWorker(PMDDL4, placementsList, PlacementBG4))
    PMDDL4.Text := placementsList[placementFM4]

    MainGUI.AddText("x830 y303", "Upgrade Priority")
    UpgBG4 := mainGUI.AddButton("x923 y301 Disabled w20 h20 Center", UPGPList[UpgFM4])
    CreateImageButton(UpgBG4, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL4 := mainGUI.AddDropDownList("x923 y301 w20 +0x4000000", UPGPList)
    UPGDDL4.OnEvent("Change", (*) => DropDownListWorker(UPGDDL4, UPGPList, UpgBG4))
    UPGDDL4.Text := UPGPList[UpgFM4]

    TypeBG4 := mainGUI.AddButton("x970 y258 Disabled w50 h20 Center", TypeList[typeFM4])
    CreateImageButton(TypeBG4, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL4 := mainGUI.AddDropDownList("x970 y258 w50 +0x4000000", TypeList)
    TypeDDL4.OnEvent("Change", (*) => DropDownListWorker(TypeDDL4, TypeList, TypeBG4))
    TypeDDL4.Text := TypeList[typeFM4]

    ; --- Unit 5 ---
    holder := MaingUI.AddButton("x820 y334 w205 h73 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y341 w197 Center", "Unit 5")

    Unit5Checkbox := MainGUI.AddCheckBox("x828 y340 h" SGH " w" SGW)
    Unit5Checkbox.Value := Unit5Enabled
    Unit5Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y362", "Placements")
    PlacementBG5 := mainGUI.AddButton("x898 y360 Disabled w20 h20 Center", placementsList[placementFM5])
    CreateImageButton(PlacementBG5, 0, ButtonStyles["fake_for_group"]*)
    PMDDL5 := mainGUI.AddDropDownList("x898 y360 w20 +0x4000000", placementsList)
    PMDDL5.OnEvent("Change", (*) => DropDownListWorker(PMDDL5, placementsList, PlacementBG5))
    PMDDL5.Text := placementsList[placementFM5]

    MainGUI.AddText("x830 y384", "Upgrade Priority")
    UpgBG5 := mainGUI.AddButton("x923 y382 Disabled w20 h20 Center", UPGPList[UpgFM5])
    CreateImageButton(UpgBG5, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL5 := mainGUI.AddDropDownList("x923 y382 w20 +0x4000000", UPGPList)
    UPGDDL5.OnEvent("Change", (*) => DropDownListWorker(UPGDDL5, UPGPList, UpgBG5))
    UPGDDL5.Text := UPGPList[UpgFM5]

    TypeBG5 := mainGUI.AddButton("x970 y339 Disabled w50 h20 Center", TypeList[typeFM5])
    CreateImageButton(TypeBG5, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL5 := mainGUI.AddDropDownList("x970 y339 w50 +0x4000000", TypeList)
    TypeDDL5.OnEvent("Change", (*) => DropDownListWorker(TypeDDL5, TypeList, TypeBG5))
    TypeDDL5.Text := TypeList[typeFM5]

    ; --- Unit 6 ---
    holder := MaingUI.AddButton("x820 y415 w205 h73 Disabled", "")
    CreateImageButton(holder, 0, ButtonStyles["holder"]*)
    MainGUI.AddText("x824 y422 w197 Center", "Unit 6")

    Unit6Checkbox := MainGUI.AddCheckBox("x828 y421 h" SGH " w" SGW)
    Unit6Checkbox.Value := Unit6Enabled
    Unit6Checkbox.OnEvent('Click', (*) => GUISave())

    MainGUI.AddText("x830 y443", "Placements")
    PlacementBG6 := mainGUI.AddButton("x898 y441 Disabled w20 h20 Center", placementsList[placementFM6])
    CreateImageButton(PlacementBG6, 0, ButtonStyles["fake_for_group"]*)
    PMDDL6 := mainGUI.AddDropDownList("x898 y441 w20 +0x4000000", placementsList)
    PMDDL6.OnEvent("Change", (*) => DropDownListWorker(PMDDL6, placementsList, PlacementBG6))
    PMDDL6.Text := placementsList[placementFM6]

    MainGUI.AddText("x830 y465", "Upgrade Priority")
    UpgBG6 := mainGUI.AddButton("x923 y463 Disabled w20 h20 Center", UPGPList[UpgFM6])
    CreateImageButton(UpgBG6, 0, ButtonStyles["fake_for_group"]*)
    UPGDDL6 := mainGUI.AddDropDownList("x923 y463 w20 +0x4000000", UPGPList)
    UPGDDL6.OnEvent("Change", (*) => DropDownListWorker(UPGDDL6, UPGPList, UpgBG6))
    UPGDDL6.Text := UPGPList[UpgFM6]

    TypeBG6 := mainGUI.AddButton("x970 y420 Disabled w50 h20 Center", TypeList[typeFM6])
    CreateImageButton(TypeBG6, 0, ButtonStyles["fake_for_group"]*)
    TypeDDL6 := mainGUI.AddDropDownList("x970 y420 w50 +0x4000000", TypeList)
    TypeDDL6.OnEvent("Change", (*) => DropDownListWorker(TypeDDL6, TypeList, TypeBG6))
    TypeDDL6.Text := TypeList[typeFM6]
}