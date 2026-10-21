#Requires AutoHotkey v2.0

#Include Angles.ahk
#Include Challenges.ahk

SnowyTownSetup() {
    angleDataList := [{ pattern: STAngle1, keySequence: [{ key: "d", duration: 3000 }, { key: "w", duration: 2300 }, { key: "d",
        duration: 4000 }, { key: "s", duration: 1500 }, { key: "d", duration: 1000 }
    ], xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: STAngle1Placements }, { pattern: STAngle2, keySequence: [{ key: "a",
        duration: 3000 }, { key: "s", duration: 2300 }, { key: "a", duration: 4000 }, { key: "w", duration: 1500 }, { key: "a",
            duration: 1000 }
    ], xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: STAngle2Placements }, { pattern: STAngle3, keySequence: [{ key: "d",
        duration: 3000 }, { key: "w", duration: 2300 }, { key: "d", duration: 4000 }, { key: "s", duration: 1500 }, { key: "d",
            duration: 1000 }
    ], xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: STAngle3Placements }]
    return setupPlanet("SnowyTown", angleDataList)
}

PlanetGreenieSetup() {
    angleDataList := [{ pattern: PGAngle1, keySequence: [{ key: "a", duration: 700 }], xMin: 0, yMin: 0, xMax: 800,
        yMax: 600, placements: PGAngle1Placements }, { pattern: PGAngle2, keySequence: [{ key: "s", duration: 700 }],
            xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: PGAngle2Placements }
    ]
    return setupPlanet("PlanetGreenie", angleDataList)
}

WalledCitySetup() {
    angleDataList := [{ pattern: WCAngle1, keySequence: [{ key: "w", duration: 1100 }, { key: "d", duration: 2000 }],
        xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: WCAngle1Placements }, { pattern: WCAngle2, keySequence: [{ key: "s",
            duration: 1100 }, { key: "a", duration: 2000 }
        ], xMin: 0, yMin: 0, xMax: 800, yMax: 600, placements: WCAngle2Placements }
    ]
    return setupPlanet("WalledCity", angleDataList)
}
