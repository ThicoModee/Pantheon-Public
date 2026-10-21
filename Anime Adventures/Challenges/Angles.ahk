#Requires AutoHotkey v2.0

PGAngle1Placements := [{ x: 782, y: 60 }, { x: 741, y: 57 }, { x: 691, y: 60 }, { x: 648, y: 57 }, { x: 427, y: 185 }, { x: 468,
    y: 188 }, { x: 511, y: 192 }, { x: 559, y: 192 }, { x: 564, y: 231 }, { x: 519, y: 227 }, { x: 478, y: 222 }, { x: 429,
        y: 217 }, { x: 427, y: 254 }, { x: 468, y: 255 }, { x: 514, y: 258 }, { x: 561, y: 263 }, { x: 364, y: 218 }, { x: 368,
            y: 251 }, { x: 369, y: 300 }, { x: 543, y: 320 }, { x: 583, y: 321 }, { x: 630, y: 322 }
]
PGAngle2Placements := [{ x: 11, y: 176 }, { x: 66, y: 176 }, { x: 268, y: 274 }, { x: 268, y: 241 }, { x: 270, y: 201 }, { x: 272,
    y: 164 }, { x: 310, y: 282 }, { x: 311, y: 234 }, { x: 313, y: 203 }, { x: 317, y: 165 }, { x: 350, y: 278 }, { x: 353,
        y: 232 }, { x: 351, y: 192 }, { x: 354, y: 155 }, { x: 300, y: 339 }, { x: 349, y: 340 }, { x: 410, y: 346 }, { x: 295,
            y: 388 }, { x: 291, y: 442 }
]
PGAngle1 :=
    "|<>*57$65.0000000000600000000004000000000080000000000E0000000000U0000000000000000000060000000000y000000Tk07W000003zz0wI00000T0TzVY00003sk1wD40000T7zU1z40003szzzDz8000T7zzzzzDU03szzzzzyDzUT7zzzzzy0zzszzzzzzy00z7zzzzzzzw00zzzzzzzzzw7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
PGAngle2 :=
    "|<>*50$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzszzzzzzzzzzs0Dzzzzzzzzs000Tzzzzzzk00000zzzzzk0000001zzzw000000003zXs00000000007k0000000000DU0000000000T00000000000y00000000003w00000000007k0000000000DU0000000000T00000000000y00000000001w00000000003s00000000007k0000000000TU0001"

WCAngle1Placements := [{ x: 53, y: 481 }, { x: 63, y: 451 }, { x: 67, y: 411 }, { x: 404, y: 264 }, { x: 405, y: 234 }, { x: 402,
    y: 193 }, { x: 405, y: 321 }, { x: 397, y: 355 }, { x: 356, y: 343 }, { x: 359, y: 307 }, { x: 327, y: 306 }, { x: 290,
        y: 306 }, { x: 251, y: 305 }, { x: 220, y: 304 }, { x: 190, y: 301 }, { x: 151, y: 301 }, { x: 123, y: 306 }, { x: 343,
            y: 258 }, { x: 307, y: 254 }, { x: 273, y: 254 }, { x: 233, y: 254 }, { x: 189, y: 251 }, { x: 129, y: 249 },
]
WCAngle2Placements := [{ x: 746, y: 69 }, { x: 747, y: 100 }, { x: 748, y: 142 }, { x: 750, y: 187 }, { x: 388, y: 337 }, { x: 394,
    y: 376 }, { x: 392, y: 417 }, { x: 402, y: 280 }, { x: 401, y: 244 }, { x: 442, y: 250 }, { x: 440, y: 279 }, { x: 476,
        y: 286 }, { x: 516, y: 290 }, { x: 552, y: 293 }, { x: 586, y: 294 }, { x: 625, y: 297 }, { x: 678, y: 292 }, { x: 456,
            y: 346 }, { x: 512, y: 343 }, { x: 561, y: 343 }, { x: 621, y: 350 }, { x: 669, y: 352 },
]
WCAngle1 :=
    "|<>*109$71.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk1zzzzzzzzzz03zzzzzzzzzy07zzzzzzzzzw0Dzzzzzzzzzs0Tzzzzzzzzzk0zzzzzzzzzz01zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzztzzzzzzzzzzzk1zzzzzzzzzzU3zzzzzzzzzy07zzzzzzzzzw0Dzzzzzzzzzs0Tzzzzzzzzzw0zzzzzzzzzzzzzzzzzzzzzzzzz"
WCAngle2 :=
    "|<>*115$71.s7zzzzzzzzzzk7zzzzzzzzzzU7zzzzzzzzzz07zzzzzzzzzy07zzzzzzzzzw0DzzzzzzzzzsMzzzzzzzzzz0Nzzzzzzzzzy0Pzzzzzzzzzw0Tzzzzzzzzzs0Tzzzzzzzzzk0zzzzzzzzzzU3zzzzzzzzzzzbzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"

STAngle1Placements := [{ x: 180, y: 95 }, { x: 171, y: 151 }, { x: 340, y: 200 }, { x: 389, y: 204 }, { x: 433, y: 211 }, { x: 486,
    y: 214 }, { x: 481, y: 256 }, { x: 486, y: 305 }, { x: 486, y: 351 }, { x: 276, y: 265 }, { x: 323, y: 266 }, { x: 399,
        y: 273 }, { x: 418, y: 328 }, { x: 419, y: 389 }, { x: 472, y: 435 }
]
STAngle2Placements := [{ x: 704, y: 563 }, { x: 702, y: 501 }, { x: 638, y: 500 }, { x: 637, y: 562 }, { x: 509, y: 424 }, { x: 471,
    y: 424 }, { x: 423, y: 427 }, { x: 383, y: 427 }, { x: 373, y: 376 }, { x: 340, y: 358 }, { x: 339, y: 316 }, { x: 339,
        y: 284 }, { x: 309, y: 249 }, { x: 370, y: 217 }, { x: 399, y: 258 }, { x: 411, y: 322 }, { x: 447, y: 345 }, { x: 502,
            y: 351 }, { x: 543, y: 367 }, { x: 545, y: 328 }, { x: 498, y: 316 }, { x: 444, y: 310 }
]
STAngle3Placements := [{ x: 180, y: 95 }, { x: 171, y: 151 }, { x: 224, y: 154 }, { x: 228, y: 94 }, { x: 340, y: 200 }, { x: 389,
    y: 204 }, { x: 433, y: 211 }, { x: 486, y: 214 }, { x: 481, y: 256 }, { x: 486, y: 305 }, { x: 486, y: 351 }, { x: 276,
        y: 265 }, { x: 323, y: 266 }, { x: 399, y: 273 }, { x: 418, y: 328 }, { x: 419, y: 389 }, { x: 472, y: 435 }
]
STAngle1 :=
    "|<>*16$71.00000A00000k00000E00001U0000100000300000200000400000800000800000k00000E0000D000000U000zy000001000Tzy000006000zzy00000A001zzy00000M003zzy00000k007zzw00001U00Dzzw00003000Tzzw00006000zzzw0000A001zzzw0000M003zz7w0000U007zy080001000Dzw000002000Tzw000004000Tzs00000M000Tzs00000k000Dzk00001U000DzU000031"
STAngle2 :=
    "|<>*17$71.3zkDzzzzzzzy7zUzzzzzzzzwDz1Tzzzzzzzszy3zzzzzzzzlzw3zzzzzzzzXzs7zzzzzzxz7zk/zzzzzxvyDzUNw6Fs0XWMTz008020000000000000000000000000000000C00000000000S00000000M01z00000000g07zU0000003y0DzU000000Dy0zzU000000Tz3zy0000000zw7zo0000001zu7zk0000003zc3z00000007zU3u0000000Dz01s00000007y01U00000003w0000000001"
STAngle3 :=
    "|<>*16$71.00001zk0000000003TU0000000007v0000000000Dy0000000000Rw0000000000zs0000000001zk000000001zzk00000Ts03zzU00000zk07zz000001zs0Dzy000003zw0DzzU0000zzzzzzzw0001zzU7zzzy0003zzUDzzzzU007zz0Tzzw0000Dzy0zzzs00001zw0Dzzk000007s0TzzU000007k00Tz0000001U00Dy00000000007w00000000001s00000000000E0000000000000001"