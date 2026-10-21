; Dependencies
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include GUI\gui.ahk
#Include WebhookOptions.ahk

#Include ..\..
#Include Lib\FindText.ahk
#Include Lib\imageForCS.ahk
#Include Lib\OCR-main\Lib\OCR.ahk
#Include Lib\IsProcessElevated.ahk
#Include Lib\Gdip_ImageSearch.ahk
#Include Lib\Gdip_All.ahk
#Include Lib\Roblox.ahk

#DllLoad "Gdiplus.dll"

Hotkey(pauseBind, (*) => PauseMacro())

global MacroState := 0 ; 0=stopped, 1=paused, 2=running

PauseMacro() {
    if MacroState != 0
        if A_IsPaused {
            AddToLog("Macro Resumed")
            ActivateRoblox()
            UpdateMacroState(2)
        } else {
            AddToLog("Macro Paused")
            ; Suspend Movement
            SendInput("{A Up}")
            UpdateMacroState(1)
        }
    Pause -1
}

UpdateMacroState(state) { ; 0=stopped, 1=paused, 2=running
    global MacroState
    MacroState := state

    if MacroState == 0
        color := 0xFF5B55
    else if MacroState == 1
        color := 0xFF9C55
    else if MacroState == 2
        color := 0x55FF5B

    StatusIndicatorH.Value := 'HBITMAP: ' . DrawStatus(20, color)
}

; Variables
global MacroStartTime := A_TickCount
global StageStartTime := A_TickCount

global cardPickerEnabled := 1

global hasReconnect := 0

; Define the rectangle coordinates
global startX := 100, startY := 500, endX := 700, endY := 350
global startY2 := 200, endY2 := 350
global step := 50 ; Step size for grid traversal
global successfulCoordinates := [] ; Array to store successful placements
global unsuccessfulCoordinates := []
global unsuccessfulHillCoordinates := []
global potentialPlacements := []
global filtered := []
global successThreshold := 3 ; Number of successful placements needed

rect1 := { x: 0, y: 511, width: 60, height: 89 }
rect2 := { x: 0, y: 0, width: 260, height: 100 }
rect3 := { x: 215, y: 510, width: 405, height: 90 }
rect5 := { x: 625, y: 160, width: 180, height: 110 }
rect4 := { x: 570, y: 0, width: 194, height: 72 }
rect6 := { x: 165, y: 53, width: 490, height: 25 }
rect7 := { x: 750, y: 265, width: 50, height: 60 }

; Images
UnitExistence :=
    "|<>*91$66.btzzzzzzyDzXlzzzzzzyDzXlzzzzzzyDzXlzzzyzzyDbXlUS0UM3UC1XlUA0UE30A1XlW4EXl34AMXlX0sbXXC80XVX4MbXX6A1U3UA0bk30ARk7UC0bk3UA1sDUz8bw3kC1zzbyszzzzzzzzbw1zzzzzzzzby3zzzzzzzzzzjzzzzzzU"
MaxUpgrade :=
    "|<>*134$53.0000000007U3k00000TUDk00001XUsk000033XVU0000636300800A3M6TzwS0M3UDrjRa0k70S0AS61U40s0EMAD001U0k0Ty41331k1zwA6673k7zsQAAS7UTzkwsMQC0TzVzkk0M0Tz3zVk0kETy7z3k1VkzwTz7kX7nzzzzzzzzzzzzzzzzzzw"
MaxUpgrade2 :=
    "|<>*146$47.D07U0001z0Tk000371lU00067z3zzzzw7w7zzzzs7kDzzzzk7UTzSzzUC0w0MwD081k0UkS00301U1w82663U3sMAAC7UDkssMwD0zVvkksQ0z3zVU0k0y7z3U1UUwDy7U33VszyDX6Dbzzzzzzzzzzzzzzzy"
MaxUpgrade3 :=
    "|<>*91$49.Dk7s00004M3600006633000031X1U0001UP0nzr3kkD0PzynAM3UD06D3A0U70331a00301U1X20VVUs1lVUklsS1kkssMwD0kMSQAC70AA/u603036413U1UUn20Vs0ksNX0My4NqMTUDnzzlwU"
VoteStart := "|<>*95$38.ryzzzzlz7zlzwDVzwTzXszz7zsSC30Q7770E40klU410C8sklVXUACAM0w7X360T1s1kEbsz0Q40zDsTVUM"
LobbyText :=
    "|<>*134$56.0000000000k00U10000T00y1w000Cs0RkvU003606AAM000lU1X36000AMzMwlswS36zyDwTzjslw7WD4ST6AS0M1k33lX7060A0MMPlkkVX366DwQS8sFkk3z772C4QC1zlkkV327UTw40M0k1wDz1UC0Q0z3zsQ7WD4TkzzzzzzzzwTzzzzzzzy7zzzzzzzzXzzzzzzzzszs"
AreasText := "|<>*108$36.zs007zyzztzzwTzzzzwTzTzzsA4613tA421/k4M0F3k4M4FXXUQ603bmy713zzzzzzU"
MatchmakeUI :=
    "|<>*129$83.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzUzzzzzzzzzzzzz0zzzzzzzw7zzzw1zzzzzzzkDzzzs3zzzzzzzUTzzzs7zzzzzzz0zzzzkTzzzzzzy1zzzzzzzzzzzzw3zzzzzzzzzzzzs7zzzzzzzzzzzzkDy0Tw7UsDzzzzUTk0Ds7007zzzz0z00DUA007zzzy1w00D0M007zzzw3k00S0k00Dzzzs7U00Q1U00DzzzkC0S0s3060TzzzUQ1y0k60y0zzzz0s7w1UA1y1zzzy1kDs30M3w3zzzw3UTk60k7s7zy7k70TUA1UDkDzs70C0Q0s30TUTzk00S001k60z0zzU01w007UA1y1zz007w00D0M3w3zz00Dw00y0k7s7zz01zw03y1kDkDzzU7zy0Tw7UzkTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"
CaptchaExistence :=
    "|<>*100$131.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwDzzzzzzzs3zzzzzzzzzzzkDzzzzzzz01zzzzzzy7zzzUTzzzzzzs00zzzzzzs7zzz0zzzzzzzU01zzzzzzkDzzy1zzzzzzy003zzzzzzUTzzw3zzzzzzs007zzzzzz0zzzs7zzzzzzk7wTzzzzzy1zyTkDzzzzzz0Tzz0UsEDk0DU7UEDz0Uzy1zzw01U0DU0S0300Dw01zw3zzk0300C00s0600Dk03zsDzz00600C01U0A00T007zkTzw00A00A0200M00Q00DzUzzs30M3US1w1lk70s30Tz0zzkD0kDUw3s7zUT1kD0zy1zzUz1UT1s7kTz0y3Uz1zw1zz1w30y3kDUzy1w31w3zw1zC1s61s7UT0zw3s61s7zs0sA00A00D0y0Es7kA00Dzs00A00M00y0C00kDUQ00Tzs00M00k01y0A01UT0s00zzs00s01U07w0Q030y3s01zzs03s0300zw1w0C1w7s03zzw0TwCC1rzy3y1y7wDwCDzzzzzzzw3zzzzzzzzzzzzzzzzzzzzs7zzzzzzzzzzzzzzzzzzzzkDzzzzzzzzzzzzzzzzzzzzUTzzzzzzzzzzzzzzzzzzzz0zzzzzzzzzzzzzzzzzzzzy3zzzzzzzzzzzzzzzzzzzzy7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU"
Matchmaking :=
    "|<>*93$73.zzzzzzzzzzzzzzlzzzsszzzzk08zzzwATzzzs04Tzzy6Dzzzw03zzzz3zzzzy7zzzzzVzzzzz3zX4DwElW7w8U7lU3s0Mk1w0E1sk0w0AM0Q080wM0A06A06040SAC6736737W7z6D37VX3VXl3zX7VVklXkkkVzlXkk0MlsM0EzslsQ0AMwC08zwMwC06AS7U4TyATDlb6DbxXzzzzzzzzzzzlzzzzzzzzzzs0zzzzzzzzzzw0zzzzzzzzzzy0zzzzzzzzzzzty"
AutoAbility := "|<>*83$21.zzzzzzzwD4S0kXl28wS03Xk0QSH7nWMy0n7sCQzzzzU"
ClaimText :=
    "|<>*127$71.00000000000000A7s01y000007zTs07w00000Tzlk0AQ00003k7VU0MM0000D03300kk0000Q0667zXzsw01k0AAzzzzzy031ysTrjTSyS0C7zky0AA0EQ0QCTVs0MM00Q0ss73U0kk00M1lkC711VVUUk3VnwC73333VU73zsQS666737y3tksQAAAC7zy01Uk0MMMQDzy030k0kkksTzy061U1VVVkzzz0y3kX77XXzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
LoadingScreen :=
    "|<>*98$87.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwTzzzzzzzzzzzzX3zszzzzzszXzzsMTz7zzzzz7wDzz3XzszzzzzszVzzsTzz7zzzzz7wDkz3bwMz3szbszXs1sQS07U73sT7wS07XXU0w0QT7s03UkQQMA7b3Vkz00QD3XX3kzwCCDs03XwQQMz7s1llz7wQTXXX7sw0C4TszXXwQQMz73VsXz7wQD3XX3kswD0TszXk0wQQ0731w7z7wT0DXXU0s0DUzszXw3wQT17UFyDzzzzzzzzzzzzzlzzzzzzzzzzzzzgTw"
P :=
    "|<>*88$35.3zzzy0Tzzzy0zzzzy3zzzzw7zzzzsTzzzzszzzzzlzzzzzXzw1zz7zs1zyDzk1zwTzV3zszz73zlzyC7zXzwQTz7zs0zyDzk3zwTzVzzszz7zzlzyDzzXzwTzz7zzzzyDzzzzwTzzzzszzzzzkzzzzzVzzzzy1zzzzw3zzzzk3zzzz00zzzs0000000000004"
P2 :=
    "|<>*102$165.1zzzs000Dzzz0003zzzk000zzzw0zzzzk007zzzy001zzzzU00TzzzsDzzzz001zzzzs00Tzzzy007zzzzXzzzzw00TzzzzU07zzzzs01zzzzyTzzzzU03zzzzw00zzzzz00Dzzzzrzzzzy00zzzzzk0Dzzzzw03zzzzzzzzzzk07zw3zy01zzzzzU0Tzzzzzzzzzy00zy07zk0Dzzzzw03zlyDzzzzzzk07zU0Ty01zzzzzU0Ts30Tzzzzzy00zs01zk0Dzzzzw03y001zzz0zzk07y0k7y01zzzzzU0TU007zzvzzy00zU60Tk0Dzzzzw03w000zzzTzzk07w003y01zzzzTU0TU007zzvzzy00z000Dk0Dzzzzw03w000zzzzzzk07s0k1y01zzzzzU0TU007zzzzzy00z060Dk0Dzzzzw03y001zzzzzzk07s0k1y01zzzzzU0Tk00Dzzzzzy00z060Dk0Dzzzzw03z003zzzzzzk07s0k1y01zzzzzU0Tw00zzzzzzy00zU60Tk0Dzzzzw03zk0Dzzzzzzk07w0k3y01zzzzzU0Tz03zzzzzzy00zk60zk0Dzzzzw03zw0zzzzzzzk07z00Dy01zzzzzU0TzkDzzzzzzy00zw03zk0Dzzzzw03zzbzzzzzzzk07zk0zy01zzzzzU0Tzzzzzzzzzy00zzkzzk0Dzzzzw03zzzzzzzzzzk07zzzzy01zzzzzU0Tzzzzvzzzzw00TzzzzU07zzzzs01zzzzyTzzzzU03zzzzw00zzzzz00Dzzzzlzzzzs00Dzzzz003zzzzk00zzzzw7zzzy000zzzzk00Dzzzw003zzzz0Dzzz0001zzzs000Tzzy0007zzzUU"
Priority :=
    "|<>*92$70.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs0000000000T00000000000s00000000001U0000000000600000000000M007zs000001U01zwU07U0060060200m000M00E1DvuA001U017zysss0060043W110U00M00E68442001U010MXkss006004TWD1X000M00Fu8x2C001U0168XUQ8006006En/1kU00M00D1zbxy001U0000870U00600000000000M00000000001k0000000000DU0000000001zzzzzzzzzzzzU"
CannotPlaceUnit1 :=
    "|<>FF494C-0.90$479.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000C000000000000003k000Q01k000000003U0000DU0000000000000000S00000000000000000000000w000000000s0000DU001s07U00000000D003U3zk00000000003k0000w000000000000000000000S1s000000003k0000z00w3k0D000000000S3k70Dzs00000000007U0001s000000000000000000000w3k00000000DU0003y01s7U0C000000000Q7US0zzk0000000000D00003k000000000000000000001s7U00000000z00007U03kD0000000000000D0w3wD00000000000S00007U000000000000000000003kD000000003y0000D007US0000000000000S1s7k0000000000s0w0000D0000403U000001k000D007US00000000Dw00Q0S00D0w0007000000000w3kT007rXrsDTU7y7zU3rkS0TS1z0zk0SyDUDw7jVzU0zwxy0TSDTU0Ts03z3zk1ztvw7Vzk0w3XrsD7zbUw00Tz7zsTzUTyDz07zkw1zw7z3zk0zyzUzwDz7zU1ztzy1zwTzU0vk0Dz7zU3znzwD3zU1sD7zsSDzD1s01zyDzkzz1zyTy0Dzls7zsTyDzU1zzz3zwTyTz03znzw7zszz007U0zzDz07zbzsS7b03kSDzkwTyS3k03zwTzlzz7twTs0TznkDzkzwy7U3zzzDnsz9wD03z7zwTzlzz00D03wyDw07yDzswS007UwTzlsTsw7U0DXsy7XsSD1sS00y7bUyDXs1sD07lsyS3lw3kS03kDVsyDXsS00S07UwD007UT3lsT00D1sy7XkS0sD00S3lsD7UwS1sw01sDD1sD7U3sy0D3kww3nk7lw07US3lsD7Uw00w0D0wS00D0w7Xkzk0S3lsD7Uw1kT00w7XkSD1sw3ls03kSS3kSD07zs0S7Vts7bUDzk0D0w7XkSD1s01s0S1sw00S1sD7Uzk0w7XkSD1s00T01sD7UwS3lsD3k07kww7UwS0DU00wD3nkSD0T000S1sD7UwS3k03k0w7Vs00w3kSD0Tk0wD7UwS3k00z1nxyD1sw7Xsy7U0DztwDrszAT001sS7blwS0y000w3kSDrsw7U07U1wT3k01s7UwS07U1wyD1sw7U40zzXzwS3lsD3zwDs0TzVyDzkzwT703kwD7zsw0yC01z7UwDzlsD00D01zy7U03yD1swCD03zwS3lsDsQ0zzXzsw7XkS3zkDk0zy3wDzUzszy07VsS7zVs1zw01yD1sDzXkS00S01zsD003wS3lszw03zsw7XkDlw0zw3zls77UQ3z0TU1zs7sDz0zkzw0D3kw7y3k1zs03wS3kDz7UQ00w01zUS007sw3Xlzs03zls77UTXs0DU1X1UC60s1s0703k03U6A0S0Tk0C30k3k3U0zU00sQ3U6C60s00s00w0M001ks73Uz001XVUC7073U00000000000000007U000000000000000000000000000000000000000000000000000000000000000000000000000000D0000000000000000000000000000000000000000000000000000000000000000000000000000000S0000000000000000000000000000000000000000000000000000000000000000000000000000000w0000000000000000000000000000000000000000000000000000000000000000000000000000001s0000000000000000000000000000000000000000000000000000000000000000000000000000001U00000000000000000000000000000000000000000000000000000000000002"
CannotPlaceUnit2 :=
    "|<>FF494C-0.90$457.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003U000000000000000000000s00000000000000y000Q03U00000003U00003w0000000000000003k000000000000000000000w00000000z00000z000S03k00000003k03U07zU0000000001s0001s00000000000000000003kS00000000zs0000TU1sD01s00000001sS3k0Dzs0000000000w0000w00000000000000000001sD00000000zy0000TU0w7U0Q00000000QD1s07zw0000000000S0000S00000000000000000000w7U0000000Tz0000D00S3k000000000007Uw07kA0000000000D0000D00000000000000000000S3k0000000S7k0007U0D1s000000000003kS03k01nVnUCQ0DUTw0Qs7U7C0y0TU0tks0y0tkDk0zttk0tktk0D1s07kDy0Twws3Vy03UwQs3bzD03k03ztzwDzUTwDy0Ty3kDzVzkzs0zwz1zkzwTw0Twzy1zwzy07Uw0Dy7zUDyTz3lzk3kSTz3nzbU1s03zwzz7zsTz7z0DzVsDzlzszy0TzzVzwTyTz0DyTzVzyTzU3ky0DzXzk7zDzlszk1sDDzltznk0w01zyTzXzwDzXzU7zsw7zszwTD0DzzszyDyDbU7zDzkzzDzk00S07zlzk3zbzsww00w7bzswzts0S01wTDXtwTDXsS03swS7lwyAS3U7nswyDbkD1k0w7lwyDblw00z07lwD00S3sySC00S3nsyS7Uw0D00wDbUww7bUwD01sDD3kyS0D3k3kwSS3nk7Vs0S3kSS7nkS00z03kS7U0D1sDD7w0D1tsDD3kC07U0S3nkSS3nkS7U0w7bVsDD07zs1sSDD1ts3zw0D1sDD1tsD01z01sD3k07Uw7bXzU7Uww7bVs001s0D3tsDD1tsD3k0S3XkwDbU3zk0wD7bUww1zs07Uw7bVww7U1y00w7Vs03kS3nkTk3kSS3nkw000z3bnww7bUwyDVs0DrlsTDnsls00S7XnsyS0w003kS3ntyS3k1y00T7kw01sD1ts1s0wTD1tsS000DztzyS3nkSDzUz07zsz7zszwS60D3lszyD0D301yD1szzD1s1zz07zkS00z7UwwMQ0TzbUwwDls03zwzzD1tsD7zkTk3zsDXzwTyDzU7VswTz7U7zk0zbUwTzbUw0zzU3zsD00TnkSSTy07znkSS7ww00zwDzbUww7Uzk7s1zs7kzy3y3zk3ksS3z3k1zs0DnkS7znkS0Tzk0Ts7U07tsDDDy01xtsDD1yS007s0lVUAA1UDU0s0w00s360Q0Tk0kQ60y0k0Ds01kk60Mkk607zs07k1U00sM331y00AMM330C700000000000000000S000000000000000000000000000000000000000000000000000000000000000000000000000D0000000000000000000000000000000000000000000000000000000000000000000000000007U000000000000000000000000000000000000000000000000000000000000000000000000003k000000000000000000000000000000000000000000000000000000000000000000000000001s000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008"
CannotPlaceUnit3 :=
    "|<>FF494C-0.90$458.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000001k00000000000001w000s07000000007000003w0000000000000003k000000000000000000000w00000000zU0000z000S03k00000003k03U03zk0000000000w0000w00000000000000000001sD00000000Tw0000Dk0w7U0w00000000wD1s03zy0000000000D0000D00000000000000000000S3k0000000DzU0007s0D1s070000000073kS00zzU0000000003k0003k00000000000000000007Uw00000003tw0001s03kS000000000000w7U0T0k0000000000w0000w00000000000000000001sD00000000wD0000S00w7U00000000000D1s07U03b3b0Qs0T0zs0tkD0CQ1w0z01nVk1w1nUTU1znnU1nVnU063k0DUTw0zttk73w071stk7DyS03k03ztzwDzUTwDy0Ty3kDzVzkzs0zwz1zkzwTw0Twzy1zwzy007w0Dy7zUDyTz3lzk3kSTz3nzbU0w01zyTzXzwDzXzU7zkw7zszwTz0DzzkzyDzDzU7zDzkzzDzk03y07zlzs3zbzswTs0w7bzswzts0D00Tzbzszz3zszs1zyD1zyDz7nk3zzyDzXzXts1znzwDznzw00z01zwTw0ztzyDD00D1tzyDDyS03k0DXtwTDXtwT3k0T7XkyDblXkQ0yT7blwy1sC07UyDblwyDU0Ds0yDVs03kT7nlk03kST7nkw7U0w03kyS3nkSS3kw07UwwD3ts0wD0D3ltsDD0S7U1sD1tsTD1s00T0D1sS00w7UwwTk0w7bUwwD0s0D00w7bUww7bUwD01sDD3kSS0Dzk3kwSS3nk7zs0S3kSS3nkS0A3k3kS7U0D1sDD7z0D1tsDD3k001s0D3tsDD1tsD3k0S3XkwDbU3zk0wD7bUww1zs07Uw7bVww7U7Uw0w7Vs03kS3nkTk3kSS3nkw000TVntyS3nkST7kw07vswDbtwMw00D3ltwTD0S001sD1twzD1s1sD0DXsS00w7Uww0w0SDbUwwD0003zyTzbUww7XzsDk1zyDlzyDz7VU3kwSDzXk3kk0TXkSDznkS0Tzk1zw7U0DlsDD6707ztsDD3wS00TzbztsDD1szy3y0Tz1wTzXzlzw0wD7Xzsw0zy07ww7Xzww7U3zs0Tz1s03yS3nnzk0zyS3nkzbU03zkzyS3nkS3z0TU7zUT3zsDsDz0D3VsDwD07zU0zD1sTzD1s0Tw01zUS00TbUwwzs07rbUww7ts00Dk1X30MM30T01k1s01k6A0s0zU1UsA1w1U0Tk03VUA0lVUA01w00DU3001kk663w00Mkk660QC00000000000000000S0000000000000000000000000000000000000000000000000000000000000000000000000007U000000000000000000000000000000000000000000000000000000000000000000000000001s000000000000000000000000000000000000000000000000000000000000000000000000000S0000000000000000000000000000000000000000000000000000000000000000000000000007U0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000U"
CannotPlaceUnit4 :=
    "|<>*62$345.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzyDzyDwDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzs1zzzUzzVz0zzzzzzDzbzzbzzzzzzzzzzzwDzzzzzzzzzzzzzzzszzzzzy07zzs7zU7k7zzzzzkzsTzU7zzzzzzzszzzVzzzzzzzzzzzzzzyC7zzzzzU0zzy0TUUz0zzzzzy663zs0Tzzzzzzy7zzwDzzzzzzzzzzzzzzVkTzy0zw07zzk3s47s7zzjzzkksTy03zzzDzzzkzzzVzzzzzzzzszzzzzwD3rU40zU0TsA0z0kz1zzU3s0C73zkMwHUD4Tkw1y9wDWTXwDyFly7mD1zUM001k1s03y1U7s61sQ7s0A0Fk8TwDy080s1s3U7k3Vs1k60TU070A0k7s106040700TUA0y0E1V0T0106403zVbk103060A0y0AC0A0k1w00s1U40T080k0U0s03s0U7k20A83s080M00Tw8A080M0k0U7k1VU1040DU0204103s102040300T020y0E0V0D0102003zVXU10322667y04A089U1w88EkVs0TVs0E0U0Q03k0MTs60481s080MkMTwDw08MMMFkkzk0VU13w0DV32C4D03wD020403U0y033z0k0V0D010163VzUQV13V32667y04A889U3w8MEkVs0zVs0E0U0C07s0MTs604A0s0808EQDy0008Q8ME0kDk1UU1040TV3204D07y3020403z0z033zUk0V07U10021Vzk0E13V320C1y0A60A0k1w8MM1Vg0Tk80E0U0Ts7s0sTw20401w0808E8DzU708QMsM1sDk3ks1k60DV330ABk3y3030403zUzUD3zUE0V0Dk101211zy1wHXX77kzly0z7WD1s3yQQy7nj0zsM0S1U0Ty3y3wzy606M1z0A0MEADzzxzzrzjzzzzlzzzzzzzzzzzzrzzzzX0Dzy0Dzkzwzzzsk0X0zy1U7zVXzzzzzzzzzzzzyDzzzzzzzzzzzzzzzzzTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzlzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzyDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw"
CannotPlaceUnit5 :=
    "|<>FF494C-1.00$484.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000004000000000000000A0001004000000000800000C00000000000000000Q00000000000000000000000s000000007w00003s000C00s000000001k00k07z00000000000600001k000000000000000000000k3U00000000zs0000TU0A0s03U0000000070k3U0zy00000000000w000070000000000000000000007UC000000007zU0001y01s3U0C000000000Q7UC0Dzs00000000003k0000Q000000000000000000000S0s00000000Ty0000D007UC0000000000000S0s0y3U0000000000D00001k000000000000000000001s3U00000001s00000w00S0s0000000000001s3U7U000000000000w000070000000000000000000007UC000000007000003k01s3U0000000000007UC0Q007b3bUCS07sDz03bUQ0SQ1y0z00QwS0Dk7D1y01zsts0SQCS00Q000TUzw0TyCS0sDs070sQw1lzss3k01zwDz0zw1zkzw0Dz1k7zkTwDy01rvw3zUTwTw07zXzk7zkzw01z007z3zk1zszw3Vzk0Q3Vzs77zXUD007zkzy3zsDzXzk0zy70Tz3zlzw07zzsTz1znzs0TyDzUTz3zs0Dy00zyDz07zXzsC7201kC7zkQTyC0w00wT3twDbkwD3k03lsQ3lwD67Vs0STbVsS7UD3k0S0yT3lwDbk0zw03kwD007UDbksQ0070sTDVkS0s3k07UwC3ksD7UQD00C3lkS3ls0w7U1kwCD0sQ1sD01s3UwS3ksD01zs0S1kw00S0sD3Vs00Q3VkS71s3UD00S3ks73UQS1kw00sD71sD7U3kS073kww3Vk7Uw07UC1lsD3UQ003U1s73k01s3UQC7w01kC70sQ7UA0Q01sD3UQC1ls73k03UwQ7UwS0Dzk0QD3nkC70TzU0S0s77UwC1k00D07UQD007UC1ksDw070sQ3VkS001s07UwC1ks77UQD00C3lkS3ls0w001kwDD0sQ1s001s3UQS3ks7000w0S1kw00S0s73U7k0Q7VkC71s003sCD7ks73UQD3kw00wS70wT3kVk0073kwS7Vk3U007UC1kwT3UQ063U0wD3k01s3UQC07U1sS70sQ7U007zszz3UQC1kzy1y03zsT3zwDz7UU0QD3lzw70D100Dks73zwC1k0zy03zsD003wC1ksMQ07zsQ3VkDks0DzVzwC1ks71zs7s0Dz1y7zkTwDz01kwD3zkQ0Ty00z3UQ7zks703zk07zUw00Dks73Xzk0DzVkC70z3U0Tw3tks73UQ3y0DU0vk3sDb0zUTw073ks7w1k0zs01wC1kDb3UQ07y00Ds3k00T3UQC7y00TC70sQ1wC00C0000000003U0003U000000M0T00000070000y00000000000007U00C00000000007U0000000000E00000000000000000C00000000000000000000000000000000000000000000000000000000000000000000000000000000s00000000000000000000000000000000000000000000000000000000000000000000000000000003U0000000000000000000000000000000000000000000000000000000000000000000000000000000C00000000000000000000000000000000000000000000000000000000000000000000000000000000s00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008"
NotEnoughMoney :=
    "|<>*62$250.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz3zzzzzzzzzzzzzzzzzzzyzszzzlzzzzzzzzzzzzzzwDzzzzzzzzzzzzzzzzVzzkz1zzy3zzzzzzzzzzzzzzkzzzzzzzzzzzzzzzzw7zy3w7zzsDzzzzzzzzzzzzzz3zzzzzzzzzzzzzzzzkTzs7kTzzUzzzzzzzzzzzzzzwDzzzzzzzzzzzzzzzz1zzUD1zzy3zzzzzzzzzzzzzzkzzzzzzzzzzzzzzzzw7zy0Q7k7U1zy0w8Dy0y7kz2703zyAC7y0z67z0SDkkTzs1kS0C07zU1k0Tk1sT3k0Q07zk007k0s07s0ET31zzU31U0M0Tw0300y03VwC00k0Dz000S01U0T001sA7zy04600U1zk0A01k067ks0300zw000k0600s023UkTzsM0MC3Uzz1kE871kMT30kA21zk8431kM63Us8A71zzVU11wC3zs711sMDVVwA7Ukw7z1kMADUUw63UkES7zy7047ksDzU0ADVUy67kkS33sTw73Uky23kM0303zzzsS0ET3Uzy00ky63sMC31sADVzkQC33s8D1U0S0DzzzVw1UsC3zsDz3sQ71UEC00ky7z1ksA71Uw63zw0zzzy7k600s1zkAQDVk0600s033sTw73Uk063kM6Dk7sTzsTUM07k7z00ky7U0w03k0ADVzkQC3U0MD1k0TUT1zzVz1k0z0Ty033sT07s0DU0ky7z1ksD03Uw701y3w7zy7yDk7y1zw0QDVy0zkEzW33sTwD3ky0y7ky07sDszzzzzzvzzzzy7zzzzTzzzzsTzzzzzzzzTzzzz3z1zzzzzzzzzzzzzzzzzzzzzzz71zzzzzzzzzzzzzzzw7zzzzzzzzzzzzzzzzzzzzzzw07zzzzzzzzzzzzzzzkzzzzzzzzzzzzzzzzzzzzzzzk0zzzzzzzzzzzzzzzy3zzzzzzzzzzzzzzzzzzzzzzz07zzzzzzzzzzzzzzzsTzzzzzzzzzzzzzzzzzzzzzzz1zzzzzzzzzzzzzzzzlzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU"
NextText :=
    "|<>*130$71.00000000000000000000000000000000000003UQ000000000DXw0007k0000laQ000Tk0001VgM000lU00033snwwRXU00063lzzxz7k000A3XkSTA1U000M3708QE30000k6A0M0U60001W0Mss3lw01zz60k1sDXzzzzyC1U3kT7zzzzwQ37z0S7zzzzsw60Q0Q7zzzzlwC0Esw7zzzzXwS1ntwTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
EndScreen :=
    "|<>*133$121.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzyTtUDz0Tzzzzzzzzzzzzy7sE1zU3zzzzzzzzzzzzzVsM0Tk0zzzzzzzzzzzzzsMQQDssTzzzzzzzzzzzzy0CD7wSAFkTUAFkD0s7zz0D7XyD60k3U60k30M3zzkDXVz730E1U30E1XANzzs7k0zU1VsMEVVssky7zzs1s0zk1lwQ8slw0M30Tzs0Q0zs1syC4QMy0C0k7zwA6DzwTwT320AT7zsT3zwD37zyDyDU306DU3081zwDkXzz7z7s3k37s1UA1zzDwlzzXzXy3yFXy1sD1zzzzzzzzzzzzzszzzzzzzzzzzzzzzzzzy0Tzzzzzzzzzzzzzzzzzy0TzzzzzzzzzzzzzzzzzzkTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk"
DeathText := "|<>*100$22.zzzzUzUw3w3l7l6ASAMtstXbXaASAQFgFkAEDUlUzzzzU"

Path :=
    "|<>##0.90$0/0/D82B73,3/0/D53589,0/-3/D82570,-4/-2/D7276E,-3/2/E0296C,4/2/D53888,8/0/D62B7A,-3/0/DB2C75,-7/0/DB3786,-10/0/DA3A8B,1/-4/D62874,0/-8/DC3A81,1/4/DC2569,1/8/D82165"

Path2 := "|<>##0.90$0/0/DB368A,-5/5/E31655,-10/11/E31256,-13/0/E21350,-8/7/DE2A77,-1/12/E3195B"

Path3 := "|<>##0.90$0/0/D51866,4/4/D90B4D,7/9/D71158,12/14/D90C4E,13/0/D71358,9/5/DA0643,5/9/D80D4F,0/13/D6155F"

Path4 := "|<>##0.90$0/0/D91256,-6/7/CF368B,-12/13/D61B5F,-12/0/D61960,-6/6/CD409A,1/14/D8135A" ; GOOD 8/10

Path5 := "|<>##0.90$0/0/CF2572,-6/5/CE2B7F,-13/12/D40E4D,-14/0/CA3C99,-7/8/CF2373,-2/13/D2185D"

Path6 := "|<>##0.90$0/0/C91764,-3/5/C22A83,-11/12/CB084D,-11/1/C90E5B,-5/6/C22D86,0/13/CB0B4E,-5/14/C61A68" ; MEH 6/10

Path7 := "|<>##0.90$0/0/D60E55,-6/12/D21F73,-13/2/CC3592,-2/13/D8064A,-15/10/D70950,-1/5/D61059"

Hill :=
    "|<>##0.90$0/0/00FFFF,-9/-4/00EF00,-18/-6/00F001,-26/-4/00EF00,-29/-1/00F000,-4/4/00F100,5/8/00FFFF,13/-3/00F200,-12/-5/00F100,-32/-1/00ED00,-32/7/00F000,-31/-1/00EC00"

Hill2 := "|<>##0.90$0/0/00F70F,-7/5/00FFFF,-13/13/00F60C,-13/1/00F70B,-8/5/00FFFF,-1/13/00FB20"

CannotPlaceUnitsArr := [CannotPlaceUnit1, CannotPlaceUnit2, CannotPlaceUnit3, CannotPlaceUnit4, CannotPlaceUnit5]

RobloxSettings := {
    MovementMode: {
        Text: "|<>*99$134.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzwT7zzzzzzzzyTlwTzwzzzzz7VzzzzzzzzzbwS7zzDzzzzlsQAxksAS70kT7Vkw3VzzzwCa1iNa07AlCTkuM68nDzzz3dj9axaQrgtbwCawjBvzzzmmPmPU9bA1CNz/9j/n0TzzwYawovyNnTnaTmGPmwrzzzz9NjACzaQrwtbwZawjBzzzzn6Mb7WNbAHCQzANWM34zzzwlb3twCNnVnb7n6QD4sTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU",
        Default: "|<>*50$131.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzz1zzTzzrTtCTzzTzzzzxjzyMzyzzzgzqNzzyzzzzzvDzwxkkMRvETAbVbh7VsRA7TzttAvavqnytSNiNaNasniTznmxrwrhbxkxvQrZtwnjQzzbY1j1jPDvVs2Pj/n1jStzzD/zRnSqTr9ryrSLZnSxnzySryvaxgziPjxCwj/axvbzwlaRqAnRzQnAswnAqBtbDzsDVvUQKsytn3tsD3UPsizzzzzzzzzzwzzznzzzzzzxzzzzzzzzzzxzzzjzzzzzznzzzzzzzzzztzzwzzzzzzzjzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk",
        Keyboard: "|<>*50$131.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzztnzzvzzzzzjzzDnzzzzzzznDzzrzzzzzTzyDbzzzzzzzYwAxcwD3dUzzwSC7SswDzz/nBnAnAr6RzjsxNaxYnDzy7jPawjDaRvzTkurZvTjTzwD0HRtSMBvrkDZZj/qD0TztCzqvmwiPrjxz/PSLj6zzznRzdrZtQrjTvyGqwjThzzzaNb7aNaljAzzwlgnAqNbzzCMTD1sQ3T5zztbQD5VsTzzzzyTzzzzzzzzzzzzzzzzzzzzxzzzzzzzzzzzzzzzzzzzzzbzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs",
    },
    CameraMode: {
        Text: "|<>*100$103.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz3zzzzzzzyDXzzbzzz0zzzzzzzz7VzznzzzDwC37VkkzXksS1kzzjwX0HaMGDkuMa8nDzrztaQrgzbsRBtSPrzvzUnCM2S3wgawjA1zxzaNbBzCNyGHSLazzyTrAnazbQz9Nj/nTzzUN6Nn4nYTaAlA1WTzsQ3AtktkDn6QD4sTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
        Follow: "|<>*49$56.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz0zvTzzzzznzyrzzzzzwz3hknCzzzDaPNYnDzznvmqwgHzzw2whj+IzzzDj/PmhTzznvmqwX7zzwyNhaMlzzzDkvQDCTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU",
        CameraToggle: "|<>*52$103.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzkzzzzzzy0zzzzTzzznDzzzzzztzzzzjzzznz3cVkuMRsS3Ur3zzvzBn6nANitaNaPAzzxzyPr/qTnRvSrhjTzyzsBvY1T1iwjPqk7zzTvaxmzjQrSLhvPzzzbxnStTriPjPqxhzzztaljQaPqBnAnAqNzzy70riMRs6wD5lPVzzzzzzzzzzzzzyzjzzzzzzzzzzzzzzaNbzzzzzzzzzzzzzzsS7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy",
    }
}

RobuxImage :=
    "|<>*93$40.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzUTzzzzw0zzzzz3kzzzzkTUzzzw73UzzzVs7VzzyS07bzzlU06DzzA00Azzwk00nzzn1y3DzzA7sAzzwkTUnzzn1y3DzzA7sAzzwkTUnzzn003DzzC00QzzwQ03Xzzss0QTzzVs7VzzzVtsTzzz1y3zzzz1Uzzzzz0Dzzzzz3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"

bitmaps := Map(), bitmaps.CaseSense := 0
base64 :=
    "iVBORw0KGgoAAAANSUhEUgAAAGQAAAASBAMAAABft2a7AAAAElBMVEU5Oz38/Pz8/f39/f3+/v7///+Pg9IaAAAALElEQVR42mMYBcMGCAoKCikbQ4ELFIRCQQiU72wMBUqCgoIMoSSDUS100AIAwSaP+Z3P8L8AAAAASUVORK5CYII="
bitmaps["disconnected"] := Gdip_BitmapFromBase64(&base64)

global PathMap := []

coordIsInBounds(x, y) {
    return x > 0 && y > 0 && x <= 770 && y <= 580
}

F1:: {
    loop 50 {
        MapPath()
    }

    DrawPath(1)
}

MapPath(isHill := false) {
    global PathMap, currentFails
    if !isHill {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, IsSet(Path4) ? Path4 :
            "|<>##0.90$0/0/D91256,-6/7/CF368B,-12/13/D61B5F,-12/0/D61960,-6/6/CD409A,1/14/D8135A")) { ; Path4
            for i, coord in ok {
                FindTextClass().ScreenToWindow(&X, &Y, coord.x, coord.y)
                if (PathMap.Length >= 300) {
                    break
                }
                if (!isInPathMap(X, Y) && !isInCurrentFails(X, Y) && coordIsInBounds(X, Y)) {
                    PathMap.Push({ x: X, y: Y - 32 })
                }
            }
        }
    } else {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Hill)) {
            for i, coord in ok {
                FindTextClass().ScreenToWindow(&X, &Y, coord.x, coord.y)
                if (PathMap.Length >= 200) {
                    break
                }
                if (!isInPathMap(X, Y) && !isInCurrentFails(X, Y) && coordIsInBounds(X, Y)) {
                    PathMap.Push({ x: X, y: Y - 32 })
                }
            }
        }
    }
}

isInPathMap(x, y) {
    for i, coord in PathMap {
        if (coord.x = x && coord.y = y) {
            return true
        }
    }
    return false
}

global DEBUG := false

DrawPath(unitType) {
    global PathMap, currentFails, DEBUG
    if PathMap.Length == 0 {
        return []
    }

    if DEBUG {
        hDC := DllCall("GetDC", "Ptr", mainGui.Hwnd, "Ptr")
        DllCall("gdiplus.dll\GdipCreateFromHDC", "Ptr", hDC, "Ptr*", &pGraphics := 0)
        DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)

        if unitType == 3 { ; Hill
            DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF0000FF, "Float", 2, "Int", 2, "Ptr*", &pPen := 0) ; BLUE: 0xFF0000FF
        } else {
            DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF66FF66, "Float", 2, "Int", 2, "Ptr*", &pPen := 0) ; Green: 0xFF66FF66
        }

        PathPointsDEBUG := FindClosestOrder(PathMap)

        OffsetPointsDEBUG := []

        loop PathPointsDEBUG.Length - 1 {
            x1 := PathPointsDEBUG[A_Index].x, y1 := PathPointsDEBUG[A_Index].y
            x2 := PathPointsDEBUG[A_Index + 1].x, y2 := PathPointsDEBUG[A_Index + 1].y

            dx := x2 - x1
            dy := y2 - y1
            len := Sqrt(dx * dx + dy * dy)

            if len = 0
                continue

            px := dy / len * 32
            py := -dx / len * 32 ; DONT REMOVE THIS, THIS CALCULATES PERPENDICULAR VECTOR, CHANGE 30 HERE AND BELOW FOR OFFSET BETWEEN POINTS

            offset1DEBUG := { x: x1 + px, y: y1 + py }
            offset2DEBUG := { x: x1 - px, y: y1 - py }

            if IsValidOffset(offset1DEBUG, OffsetPointsDEBUG)
                OffsetPointsDEBUG.Push(offset1DEBUG)
            if IsValidOffset(offset2DEBUG, OffsetPointsDEBUG)
                OffsetPointsDEBUG.Push(offset2DEBUG)

            /*if (ok := FindText(&X, &Y, OffsetPointsDEBUG[A_Index].x, OffsetPointsDEBUG[A_Index].y, , , 0, 0, Path4)) {
                AddToLog("point intersects with path")
                OffsetPointsDEBUG.RemoveAt(A_Index)
            } */

            /*for i, point in OffsetPointsDEBUG {
                if !(ok := FindText(&X, &Y, point.x, point.y, , , 0, 0, Path4)) {
                    AddToLog("added successful point")
                    placementPoints.Push(point)
                }
            }*/

            /*index := OffsetPointsDEBUG.Length
            while (index >= 1) {
                point := OffsetPointsDEBUG[index]
                if !(ok := FindText(&X, &Y, point.x, point.y, , , 0, 0, Path4)) {
                    ; Remove the point if it doesn't pass the intersection check
                    OffsetPointsDEBUG.RemoveAt(index)
                }
                index--
            }*/

            DllCall("Gdiplus.dll\GdipDrawLine", "Ptr", pGraphics, "Ptr", pPen, "Float", x1, "Float", y1, "Float", x2,
                "Float", y2)
            for i, point in OffsetPointsDEBUG {
                DrawCircle(pGraphics, point.x, point.y, 5, pPen)
            }
        }
    }

    if (unitType == 4) {
        PathPoints := FindClosestOrder(PathMap)
    } else {
        PathPoints := SortByDistance(PathMap, unitType)
    }

    OffsetPoints := []

    loop PathPoints.Length - 1 {
        x1 := PathPoints[A_Index].x, y1 := PathPoints[A_Index].y
        x2 := PathPoints[A_Index + 1].x, y2 := PathPoints[A_Index + 1].y

        dx := x2 - x1
        dy := y2 - y1
        len := Sqrt(dx * dx + dy * dy)

        if len = 0
            continue

        px := dy / len * 32
        py := -dx / len * 32 ; DONT REMOVE THIS, THIS CALCULATES PERPENDICULAR VECTOR, CHANGE 30 HERE AND BELOW FOR OFFSET BETWEEN POINTS

        offset1 := { x: x1 + px, y: y1 + py }
        offset2 := { x: x1 - px, y: y1 - py }

        if IsValidOffset(offset1, OffsetPoints)
            OffsetPoints.Push(offset1)
        if IsValidOffset(offset2, OffsetPoints)
            OffsetPoints.Push(offset2)
    }

    return OffsetPoints
}

IsValidOffset(point, points) {
    for _, p in points {
        if Sqrt((p.x - point.x) ** 2 + (p.y - point.y) ** 2) < 32
            return false
    }
    return true
}

DrawCircle(pGraphics, x, y, radius, pPen) {
    DllCall("Gdiplus.dll\GdipDrawEllipse", "Ptr", pGraphics, "Ptr", pPen, "Float", x - radius, "Float", y - radius,
        "Float", radius * 2, "Float", radius * 2)
}

GetDistance(x, y, centerX, centerY) {
    return Sqrt((x - centerX) ** 2 + (y - centerY) ** 2)
}

CalculateDistance(coord, center) {
    return Sqrt((coord.x - center.x) ** 2 + (coord.y - center.y) ** 2)
}

SortByDistance(arr, unitType) { ; TYPES: DPS=1 Ground=2 Hill=3 Buff=4 Farm=5
    sortOrder := (unitType == 3) ? 1 : ((unitType == 1) ? 1 : -1)
    center := { x: 400, y: 288 }

    loop arr.Length - 1 {
        swapped := false
        loop arr.Length - A_Index {
            i := A_Index
            if (CalculateDistance(arr[i], center) - CalculateDistance(arr[i + 1], center)) * sortOrder > 0 {
                temp := arr[i]
                arr[i] := arr[i + 1]
                arr[i + 1] := temp
                swapped := true
            }
        }
        if !swapped
            break
    }

    return arr
}

FindClosestOrder(PathMapPoints) {
    if (PathMapPoints.Length == 0)
        return []

    ordered := [PathMapPoints[1]]
    remaining := []

    loop PathMapPoints.Length {
        if (A_Index > 1)
            remaining.Push(PathMapPoints[A_Index])
    }

    while (remaining.Length > 0) {
        last := ordered[-1]
        minDist := 999999, minIndex := -1

        for i, coord in remaining {
            dist := Sqrt((last.x - coord.x) ** 2 + (last.y - coord.y) ** 2)
            if (dist < minDist) {
                minDist := dist
                minIndex := i
            }
        }

        ordered.Push(remaining[minIndex])

        remaining.RemoveAt(minIndex)
    }

    return ordered
}

CannotPlaceUnits() {
    global CannotPlaceUnitsArr
    for index, placementAmount in CannotPlaceUnitsArr {
        if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, placementAmount)) {
            return true
        }
    }
    return false
}

HasNotEnoughMoney() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0.8, NotEnoughMoney)) {
        return true
    }
    return false
}

; Instances
RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"

; On startup
SendMode "Event"
AddToLog("Macro initialized.")

; Functions
BetterClick(x, y, LR := "Left") { ; credits to yuh for this, lowk a life saver
    MouseMove(x, y)
    MouseMove(1, 0, , "R")
    MouseClick(LR, -1, 0, , , , "R")
    Sleep(50)
}

PlaceUnit(x, y, slot := 1, index := 1) {
    global filtered
    SendInput(slot)
    Sleep 50
    CoordMode("Mouse", "Client")
    BetterClick(x, y)
    Sleep 50
    SendInput("q")

    sleep 100
    if IsPlacementSuccessful(index, slot) {
        Sleep 15
        return true
    }
    return false
}

FindAndClickColor(targetColor := 0x006783, searchArea := [0, 0, A_ScreenWidth, A_ScreenHeight]) {
    ; Extract the search area boundaries
    x1 := searchArea[1], y1 := searchArea[2], x2 := searchArea[3], y2 := searchArea[4]

    ; Perform the pixel search
    if (PixelSearch(&foundX, &foundY, x1, y1, x2, y2, targetColor, 0)) {
        ; Color found, click on the detected coordinates
        BetterClick(foundX, foundY, "Right")
        ;AddToLog("Color found and clicked at: X" foundX " Y" foundY)
        return true

    }
}

isFullScreen(WinTitle) {
    WinGetPos(&x, &y, &width, &height, WinTitle)
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight

    if (x = 0 && y = 0 && width = screenWidth && height = screenHeight) {
        return true
    } else {
        return false
    }
}

SetupMacro() {
    if WinExist(RobloxWindow) {
        if (isFullScreen(RobloxWindow)) {
            SendInput("{F11}")
            Sleep(200)
        }
        WinActivate(RobloxWindow)
        Sleep 50
        FetchPos()
        Sleep 50
        RobloxPos()
        Sleep 50
    }
}

InitializeMacro() {
    global sessionTime := A_TickCount
    UpdateMacroState(2)
    StartStatsUpdate()
    TabCtrl.Choose("Status")

    for i, v1 in unitUpgradePrioritydropDowns {
        for j, v2 in unitUpgradePrioritydropDowns {
            if (i < j && v1.Text == v2.Text) {
                foundDuplicate := true
                StopStatsUpdate()
                MsgBox("Duplicate found in your upgrade priorities. Error: ERR_DUPLICATE_PRIORITY", "Error", "+0x1000")
                return
            }
        }
    }

    if WinExist(RobloxWindow) {
        FetchPos()
        Sleep 50
        RobloxPos()
        WinActivate(RobloxWindow)
        Sleep 100
    }
    else {
        StopStatsUpdate()
        MsgBox("Your ROBLOX must be open in order to start the macro. Error: ERR_RBLX_NOT_OPEN", "Error", "+0x1000",)
        return
    }

    if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
        GoToRaids()
    }
    else {
        StopStatsUpdate()
        MsgBox("You must wait for the icons to load before starting the macro. Error: ERR_AA_NOT_FOUND", "Error",
            "+0x1000",)
        return
    }

}

SetDefaultKeyboard(localeID) {
    static SPI_SETDEFAULTINPUTLANG := 0x005A, SPIF_SENDWININICHANGE := 2
    Lan := DllCall("LoadKeyboardLayout", "Str", Format("{:08x}", LocaleID), "Int", 0)
    binaryLocaleID := Buffer(4, 0)
    NumPut("UInt", LocaleID, binaryLocaleID)
    DllCall("SystemParametersInfo", "UInt", SPI_SETDEFAULTINPUTLANG, "UInt", 0, "Ptr", binaryLocaleID, "UInt",
        SPIF_SENDWININICHANGE)
    for hwnd in WinGetList()
        PostMessage 0x50, 0, Lan, , hwnd
}

FrozenAbyss :=
    "|<>*88$128.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzszzzzzzzw0DzzzzzzzzznyDzzzzzzz03zzzzzzzzzsTXzzzzzzzk0zzzzzzzzzy7szzzzzzzwTzjXw3wTzzz0yDyyyDlzz7w1UC0A1U7zkDUC720k7zk30E3U20M1zs1s1llUA1zw0kA0Q1V20DyAS0A8Mz7zz0AT77kskXXz23XXW61kDzlz7llsS0Mszk0sss3kC1zwTlwQQDXyCDs064D0y3kTz7wT06081XXyDVU3kS8l7zlz7s3U30Msz3wM1y7UA1zwTlz1s0s6CDtza0zXw7UzzzzzzzzzzzzzzzzzkzzzzzzzzzzzzzzzzzzzzwTzzzzzzzzzzzzzzzzzzzz7zzzzzzzzzzzzzzzzzzzznzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"

GoToRaids() {
    global placementCounts := Map()
    global placementTries := Map()
    global filtered := []
    global starsTries := 0
    SendInput ("{Tab}")
    loop {
        ; go to xmas map
        if (ok := FindText(&X, &Y, 10, 70, 350, 205, 0, 0, LoadingScreen)) {
            AddToLog("Loading started")
            break
        }
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            AddToLog("Waiting for match to start")
            break
        }
        if (ok := FindText(&X, &Y, 338, 505, 536, 572, 0, 0, ClaimText)) ; daily reward
        {
            BetterClick(406, 497)
            Sleep 3000
        }

        ; go to xmas map

        BetterClick(89, 302)
        Sleep 2000
        SendInput ("{a up}")
        ; go to teleporter
        Sleep 100
        SendInput ("{a down}")
        Sleep 6000
        SendInput ("{a up}")
        KeyWait "a" ; Wait for "a" to be fully processed

        ;sacred planet act 4
        Sleep(1200)
        if MatchmakeMode.Value = 1 {
            BetterClick(469, 340) ; play
            Sleep 2000
            AntiCaptcha()
        } else {
            BetterClick(370, 340)
            Sleep(2000)
            if (FindText(&X, &Y, 0, 0, 800, 600, 0, 0, FrozenAbyss)) {
                AddToLog("Entered elevator.. waiting for game to start")
                break
            }
        }
    }
    CoordMode("Mouse", "Client")
    LoadedLoop()
    ;StartedLoop()
    ;OnSpawnSetup()
    ;TryPlacingUnits()

}

AfterGame() {
    global placementCounts := Map()
    global placementTries := Map()
    global filtered := []
    global starsTries := 0
    SendInput ("{Tab}")
    loop {
        ; go to xmas map
        if (ok := FindText(&X, &Y, 10, 70, 350, 205, 0, 0, LoadingScreen)) {
            AddToLog("Loading started")
            break
        }
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            AddToLog("Waiting for match to start")
            break
        }
        if (ok := FindText(&X, &Y, 338, 505, 536, 572, 0, 0, ClaimText)) ; daily reward
        {
            BetterClick(406, 497)
            Sleep 3000
        }
    }
    CoordMode("Mouse", "Client")
    LoadedLoop()
    ;StartedLoop()
    ;OnSpawnSetup()
    ;TryPlacingUnits()

}

StopMacro() {
    Reload()
}

Eye :=
    "|<>*99$28.zzzzzk003wTzzXnzzzCTzzyPzzzxjzzzqzzzzPzzzxjw0zqz3kzPsTVxj1C3qsAw7PUkkRj123qy7sTPw63xjw0zqzyTzPzzzxjzzzqzzzzNzzztnzzzD7zzsz000Dzzzzy"

IsPlacementSuccessful(index, slot) {
    Sleep PlacementSpeed
    if (ok := FindText(&X, &Y, 78, 182, 400, 451, 0, 0, UnitExistence)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Priority)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, Eye)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    return false
}

GetWindowCenter(WinTitle) {
    x := 0 y := 0 Width := 0 Height := 0
    WinGetPos(&X, &Y, &Width, &Height, WinTitle)

    centerX := X + (Width / 2)
    centerY := Y + (Height / 2)

    return { x: centerX, y: centerY, width: Width, height: Height }
}

isInsideRect(rect, x, y) {
    if (x >= rect.x && x <= rect.x + rect.width
        && y >= rect.y && y <= rect.y + rect.height) {
        return true
    }

    return false
}

equipUnit(slot := 1) {
    SendInput(slot)
    MouseMove(565, 563)
}

IsCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

IsHillCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulHillCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

IsCoordInSuccessful(coordX, coordY) {
    for coord in successfulCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

isInsideAnyRect(x, y) {
    for index in [1, 2, 3, 4, 5, 6, 7] {
        rect := %"rect" index%

        if (isInsideRect(rect, x, y)) {
            return true
        }
    }
    return false
}

RepeatString(str, count) {
    result := ""
    loop count
        result .= str
    return result
}

DumpObject(obj, indent := 0) {
    output := ""
    indentStr := RepeatString("  ", indent)

    if IsObject(obj) {
        for key, value in obj {
            if IsObject(value) {
                output .= indentStr . key ":`n" . DumpObject(value, indent + 1)
            } else {
                output .= indentStr . key ": " value "`n"
            }
        }
    } else {
        output := indentStr . obj "`n"
    }

    return output
}

FilterUnique(array) {
    uniqueArray := []
    seen := Map()

    for item in array {
        if !item.HasProp("x") || !item.HasProp("y") {
            MsgBox("Invalid item: " DumpObject(item))
            continue
        }

        key := Format("{},{}", item.x, item.y)
        if !seen.Has(key) {
            seen.Set(key, true)
            uniqueArray.Push(item)
        }
    }

    return uniqueArray
}

global placementCounts := Map()
global placementTries := Map()

global currentFails := []

isInCurrentFails(x, y) {
    for i, value in currentFails {
        if value.x = x && value.y = y {
            return true
        }
    }

    return false
}

global gameEnded := false

Placement() {
    global successfulCoordinates, maxedCoordinates, filtered, currentFails, gameEnded
    successfulCoordinates := [] ; Reset successfulCoordinates for each run
    maxedCoordinates := []
    ordered := []
    global PathMap := []
    filtered := []
    mappingLoops := 100

    ; Iterate through all slots (1 to 6)
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := UnitEnabled.Get(slotNum)
        placements := placementFM.Get(slotNum)
        unitType := TypeFM.Get(slotNum)
        ;upgrades := UpgFM.Get(slotNum)

        if !(enabled == 1) {
            continue
        }

        if unitType == 3 { ; Hill
            AddToLog("Slot " slotNum " is a hill slot.")
            SendInput(slotNum)
            MouseMove(785, 550)
            global PathMap := []
            loop mappingLoops {
                MapPath(true)
            }
            filtered := DrawPath(unitType)
            hill := true
        } else {
            if slotNum != 1 && UnitEnabled.Get(slotNum - 1) == 1 && TypeFM.Get(slotNum - 1) == 3 {
                AddToLog("Previous slot was a Hill unit, remapping path")
                SendInput("{1}")
                MouseMove(785, 550)
                global PathMap := []
                loop mappingLoops {
                    MapPath(false)
                }
                filtered := DrawPath(unitType)
            }
            hill := false
        }
        filtered := DrawPath(unitType)

        currentTries := 0

        ; Skip if the slot is not enabled

        AddToLog("Starting placements for Slot " slotNum " with " placements " placements.")

        placementCounts.Set(slotNum, 0)
        placementTries.Set(slotNum, 0)

        ; Continue placement for the current slot
        while (placementCounts.Get(slotNum) < placements && placementTries.Get(slotNum) < 25) {
            if unitType == 4 {
                if ordered.Length <= 0 {
                    SendInput(slotNum)
                    MouseMove(785, 550)
                    global PathMap := []
                    loop mappingLoops {
                        MapPath(unitType == 3)
                    }
                    filtered := DrawPath(unitType)
                }
            } else {
                if filtered.Length <= 0 {
                    SendInput(slotNum)
                    MouseMove(785, 550)
                    global PathMap := []
                    loop mappingLoops {
                        MapPath(unitType == 3)
                    }
                    filtered := DrawPath(unitType)
                }
            }

            if unitType == 4 {
                ordered := FindClosestOrder(filtered)

                for i, coord in ordered {
                    /*
                    if unitType != 3 {
                        index := -A_Index
                        coord:= filtered[index]
                    } */
                    foundX := coord.x
                    foundY := coord.y

                    if (IsCoordInSuccessful(foundX, foundY) || isInsideAnyRect(foundX, foundY) || foundX < 0 || foundY <
                    30) {
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        currentFails.Push({ x: foundX, y: foundY })
                        AddToLog("coord either in successful or intersects with blocked rectangles")
                        continue
                    }

                    AddToLog("placing at x" foundX " y" foundY ". currently on try " placementTries.Get(slotNum))

                    if (cardPickerEnabled == 1) {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) { ; CARD PICKER
                            cardSelector()
                            ;AddToLog("Succesfully picked card")
                        }
                    } else {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) {
                            while (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) {
                                Sleep 100
                            }
                        }
                    }

                    if gameEnded == true {
                        break 2
                    }

                    if PlaceUnit(foundX, foundY, slotNum, i) {
                        placementCounts.Set(slotNum, placementCounts.Get(slotNum) + 1)
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        successfulCoordinates.Push({ x: FoundX, y: FoundY, slot: "slot_" slotNum }) ; Track successful placements
                    } else {
                        try {
                            ordered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        placementTries.Set(slotNum, placementTries.Get(slotNum) + 1)
                        currentFails.Push({ x: foundX, y: foundY })
                    }

                    if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) { ; USE ABILITY IF OFF
                        BetterClick(373, 237)
                    }

                    if (cardPickerEnabled == 1) {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                            pick_card)) { ; CARD PICKER
                            cardSelector()
                            ;AddToLog("Succesfully picked card")
                        }
                    } else {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                            pick_card)) {
                            while (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0,
                                0, pick_card)) {
                                Sleep 100
                            }
                        }
                    }

                    WinActivate(RobloxWindow)
                    SendInput("q")
                    isMatchFinished() ; next
                    BetterClick(565, 563) ; move mouse

                    /*if ShouldStopUpgrading(1) {
                        AddToLog("Stopping due to finding lobby  condition.")
                        return LobbyLoop()
                    }*/
                    if placementCounts.Get(slotNum) >= placements {
                        if unitType == 4 {
                            InfiniteBuff(slotNum)
                            Sleep(100)
                            BetterClick(328, 186)
                        }
                        break
                    }

                    DisconnectCheck()
                }
                else {
                    if (currentTries >= 1) {
                        AddToLog("Failed to find path, going to next unit")
                        SendInput("{q}")
                        break
                    }
                    AddToLog("Path not found, current try: " currentTries)
                    currentTries += 1
                }
                DisconnectCheck()
            } else {
                for i, coord in filtered {
                    /*
                    if unitType != 3 {
                        index := -A_Index
                        coord:= filtered[index]
                    } */
                    foundX := coord.x
                    foundY := coord.y

                    if (IsCoordInSuccessful(foundX, foundY) || isInsideAnyRect(foundX, foundY) || foundX < 0 || foundY <
                    30) {
                        try {
                            filtered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        currentFails.Push({ x: foundX, y: foundY })
                        AddToLog("coord either in successful or intersects with blocked rectangles")
                        continue
                    }

                    AddToLog("placing at x" foundX " y" foundY ". currently on try " placementTries.Get(slotNum))

                    if (cardPickerEnabled == 1) {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) { ; CARD PICKER
                            cardSelector()
                            ;AddToLog("Succesfully picked card")
                        }
                    } else {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) {
                            while (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) {
                                Sleep 100
                            }
                        }
                    }

                    if gameEnded == true {
                        break 2
                    }

                    if PlaceUnit(foundX, foundY, slotNum, i) {
                        placementCounts.Set(slotNum, placementCounts.Get(slotNum) + 1)
                        try {
                            filtered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }
                        successfulCoordinates.Push({ x: FoundX, y: FoundY, slot: "slot_" slotNum }) ; Track successful placements
                    } else {
                        try {
                            filtered.RemoveAt(i)
                        } catch Any as err {
                            AddToLog "Caught an error: " err.Message
                        }

                        placementTries.Set(slotNum, placementTries.Get(slotNum) + 1)
                        currentFails.Push({ x: foundX, y: foundY })
                    }

                    if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) { ; USE ABILITY IF OFF
                        BetterClick(373, 237)
                    }

                    if (cardPickerEnabled == 1) {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                            pick_card)) { ; CARD PICKER
                            cardSelector()
                            ;AddToLog("Succesfully picked card")
                        }
                    } else {
                        if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                            pick_card)) {
                            while (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0,
                                0, pick_card)) {
                                Sleep 100
                            }
                        }
                    }

                    if ShouldStopUpgrading() {
                        AddToLog("Found return to lobby, going back.")
                        return isMatchFinished()
                    }

                    WinActivate(RobloxWindow)
                    SendInput("q")
                    isMatchFinished() ; next
                    BetterClick(565, 563) ; move mouse

                    /*if ShouldStopUpgrading(1) {
                        AddToLog("Stopping due to finding lobby  condition.")
                        return LobbyLoop()
                    }*/
                    if placementCounts.Get(slotNum) >= placements {
                        if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                            while (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                                Sleep(100)
                            }
                        }
                        if unitType == 4 {
                            InfiniteBuff(slotNum)
                            Sleep(100)
                            BetterClick(328, 186)
                        }
                        break
                    }

                    DisconnectCheck()
                }
                else {
                    if (currentTries >= 1) {
                        AddToLog("Failed to find path, going to next unit")
                        SendInput("{q}")
                        break
                    }
                    AddToLog("Path not found, current try: " currentTries)
                    currentTries += 1
                }
                DisconnectCheck()
            }

        }

        AddToLog("Completed " placementCounts.Get(slotNum) " placements for Slot " slotNum ".")
        ; Upgrades Priority unit types inbetween placements

        DisconnectCheck()
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
    while gameEnded == false {
        BetterClick(328, 186)
        isMatchFinished()
        ShouldStopUpgrading()
        Sleep(500)
    }
}

InfiniteBuff(slotNum) {
    global SPACurse, SPABG, CurseInput
    filteredUnits := []
    for index, unit in successfulCoordinates {
        if (unit.slot == "slot_" slotNum) {
            filteredUnits.Push(unit)
        }
    }

    try {
        if CurseInput.Has(slotNum) && Number(CurseInput.Get(slotNum).Text) {
            loop filteredUnits.Length {
                if (A_Index == 2 || A_Index == 4) {
                    Sleep ((0.6 * (CurseInput.Get(slotNum).Text) - 1.3) * 1000) + 2000
                } else if (A_Index == 3) {
                    Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
                }

                unit := filteredUnits[A_Index]

                BetterClick(328, 186)

                Sleep(50)

                BetterClick(unit.x, unit.y)

                Sleep(50)

                BetterClick(373, 237)
            }
        } else {
            loop filteredUnits.Length {
                if (A_Index == 2 || A_Index == 4) {
                    Sleep ((0.6 * (7.1) - 1.3) * 1000) + 2000
                } else if (A_Index == 3) {
                    Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
                }

                unit := filteredUnits[A_Index]

                BetterClick(328, 186)

                Sleep(50)

                BetterClick(unit.x, unit.y)

                Sleep(50)

                BetterClick(373, 237)
            }
        }
    } catch {
        loop filteredUnits.Length {
            if (A_Index == 2 || A_Index == 4) {
                Sleep ((0.6 * (7.1) - 1.3) * 1000) + 2000
            } else if (A_Index == 3) {
                Sleep ((30 - 0.6 * 7.1 - 1.1) * 1000)  ; Before 3rd unit
            }

            unit := filteredUnits[A_Index]

            BetterClick(328, 186)

            Sleep(50)

            BetterClick(unit.x, unit.y)

            Sleep(50)

            BetterClick(373, 237)
        }
    }
}

SpiralPlacement(gridPlacement := false) {
    global startX, startY, endX, endY, step, successfulCoordinates, maxedCoordinates
    successfulCoordinates := [] ; Reset successfulCoordinates for each run
    maxedCoordinates := []
    savedPlacements := Map()

    centerX := GetWindowCenter(RobloxWindow).x
    centerY := GetWindowCenter(RobloxWindow).y
    radius := step
    direction := [[1, 0], [0, 1], [-1, 0], [0, -1]]
    dirIndex := 0
    directionCount := 0

    ; Iterate through all slots (1 to 6)
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := UnitEnabled.Get(slotNum)
        placements := placementFM.Get(slotNum)
        unitType := TypeFM.Get(slotNum)
        upgrades := UpgFM.Get(slotNum)

        ; Skip if the slot is not enabled
        if !(enabled = 1) {
            continue
        }

        AddToLog("Starting placements for Slot " slotNum " with " placements " placements.")

        placementCount := 0
        currentX := centerX - deltaX
        currentY := centerY - deltaY
        steps := 30
        maxSteps := 5

        while (placementCount < placements) {
            for index, stepSize in [steps] {
                if (cardPickerEnabled = 1) {
                    if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                        pick_card)) { ; CARD PICKER
                        cardSelector()
                    }
                }

                if PlaceUnit(currentX, currentY, slotNum) {
                    placementCount++
                    successfulCoordinates.Push({ x: currentX, y: currentY, slot: "slot_" slotNum }) ; Track successful placements
                    try {
                        if savedPlacements.Get("slot_" slotNum) {
                            savedPlacements.Set("slot_" slotNum, savedPlacements.Get("slot_" slotNum) + 1)
                        }
                    } catch {
                        savedPlacements.Set("slot_" slotNum, 1)
                    }

                    if placementCount >= placements {
                        break
                    }

                    if (gridPlacement) {
                        PlaceInGrid(currentX, currentY, slotNum, &placementCount, &successfulCoordinates, &
                            savedPlacements, &placements)
                    }

                }

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
                {
                    BetterClick(373, 237)
                }
                if (cardPickerEnabled = 1) {
                    if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0,
                        pick_card)) { ; CARD PICKER
                        cardSelector()
                    }
                }
                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                if ShouldStopUpgrading(1) {
                    AddToLog("Stopping due to finding lobby  condition.")
                    return isMatchFinished()
                }
                DisconnectCheck()

                currentX += direction[dirIndex + 1][1] * steps
                currentY += direction[dirIndex + 1][2] * steps

                currentX += Random(-15, 15)
                currentY += Random(-15, 15)

                if isInsideRect(rect1, currentX, currentY) or isInsideRect(rect2, currentX, currentY) or isInsideRect(
                    rect3, currentX, currentY) {
                    steps := 30
                    currentX := centerX - deltaX
                    currentY := centerY - deltaY
                }

                if currentX > 780 or currentY > 580 or currentX <= 0 or currentY < 0 {
                    steps := 30
                    currentX := centerX - deltaX
                    currentY := centerY - deltaY
                }
            }

            directionCount++

            if directionCount == 2 {
                steps += 30
                directionCount := 0
            }

            dirIndex := Mod(dirIndex + 1, 4)
            if ShouldStopUpgrading(1) {
                AddToLog("Stopping due to lobby condition.")
                return isMatchFinished()
            }
        }

        AddToLog("Completed " placementCount " placements for Slot " slotNum ".")
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
    while gameEnded == false {
        BetterClick(328, 186)
        isMatchFinished()
        ShouldStopUpgrading()
        Sleep(500)
    }
}

PlaceInGrid(startX, startY, slotNum, &placementCount, &successfulCoordinates, &savedPlacements, &placements) {
    ; Places untis in a 2x2 grid, starting from the top left where the initial unit is placed (as dictated by startX and startY)
    ; U x
    ; x x
    ;"Y"     ;"X"
    ;[number1,number2]

    gridOffsets := [
        [30, 0],  ; Row 1, Column 0
        [0, 30],  ; Row 0, Column 1
        [30, 30]   ; Row 1, Column 1]
    ]
    for index, offset in gridOffsets {

        ; Adds the value that's stored in the array at the current index to either x or y's starting location
        gridX := startX + offset[2] ; Move horizontally by 'step' from the initial start location
        gridY := startY + offset[1] ; Move vertically by 'step' from the initial start location

        if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
        {
            BetterClick(373, 237)
        }
        ; Handle card picker and related logic during grid placement
        if (cardPickerEnabled = 1) {
            if (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) { ; CARD PICKER
                cardSelector()
                AddToLog("Successfully picked card")
            }
        }
        isMatchFinished() ; next
        BetterClick(565, 563) ; move mouse
        if ShouldStopUpgrading(1) {
            AddToLog("Stopping due to finding lobby condition.")
            return isMatchFinished()
        }
        DisconnectCheck()

        if PlaceUnit(gridX, gridY, slotNum) {
            placementCount++ ; Increment the placement count
            successfulCoordinates.Push({ x: gridX, y: gridY, slot: "slot_" slotNum }) ; Track the placement
            AddToLog("Placed unit at (" gridX ", " gridY ") in 3x3 grid.")

            ; Update or initialize saved placements for the current slot
            try {
                if savedPlacements.Get("slot_" slotNum) {
                    savedPlacements.Set("slot_" slotNum, savedPlacements.Get("slot_" slotNum) + 1)
                }
            } catch {
                savedPlacements.Set("slot_" slotNum, 1)
            }

            ; Check if placement limit is reached
            if placementCount >= placements {
                break
            }

        }

    } ; End for

}

Numpad7:: Placement

TryPlacingUnits() {
    switch PLDDL.Text {
        case "Spiral":
            SpiralPlacement(false)
        case "Manual":
            ;ManualPlacement()
        default:
            Placement()
    }
}

IsMaxed(coord) {
    global maxedCoordinates
    for _, maxedCoord in maxedCoordinates {
        if (maxedCoord.x = coord.x && maxedCoord.y = coord.y) {
            return true
        }
    }
    return false
}

global successfulCoordinates := []

UpgradeUnits() {
    if UpgradePriorityE == 1 {
        global successfulCoordinates, maxedCoordinates, unitUpgradePrioritydropDowns, gameEnded, UpgFM
        AddToLog("Beginning prioritized unit upgrades.")

        slotPriorityMap := Map()
        for index, dropDown in unitUpgradePrioritydropDowns {
            priorityText := dropDown.Text
            if priorityText && priorityText != "" {
                slotPriorityMap["slot_" index] := priorityText
            }
        }
        SortByPriority(&successfulCoordinates, slotPriorityMap)

        for coord in successfulCoordinates {
            upgradeSlot := UpgFM.Get(Number(StrReplace(coord.slot, "slot_")))
            while !IsMaxUpgrade(upgradeSlot) {
                if (gameEnded == true) {
                    break 2
                }

                if UpgradeUnit(coord.x, coord.y, coord.slot) {
                    break
                }

                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return isMatchFinished()
                }

                Sleep(200)

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                    BetterClick(373, 237)
                }
                if (cardPickerEnabled == 1 && (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, pick_card))) {
                    cardSelector()
                }
                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                DisconnectCheck()
            }

            if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
            {
                BetterClick(373, 237)
            }

            BetterClick(565, 563) ; move mouse
            AddToLog("Max upgrade reached for: X" coord.x " Y" coord.y ". Moving onto next unit")
            maxedCoordinates.Push(coord)
        }

        AddToLog("All units upgraded or maxed.")
        while !ShouldStopUpgrading() {
            isMatchFinished() ; next
            Sleep(200)
            if (cardPickerEnabled == 1 && (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, pick_card))) {
                cardSelector()
            }
        }

        return isMatchFinished()
    }
    else {
        global successfulCoordinates
        global maxedCoordinates
        global gameEnded

        AddToLog("Beginning unit upgrades.")

        while true { ; Infinite loop to ensure continuous checking
            for index, coord in successfulCoordinates {
                if (gameEnded == true) {
                    break 2
                }

                upgradeSlot := UpgFM.Get(StrReplace(coord.slot, "slot_"))
                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return isMatchFinished()
                }

                if IsMaxUpgrade(upgradeSlot) {
                    AddToLog("Max upgrade reached for: X" coord.x " Y" coord.y)
                    maxedCoordinates.Push(successfulCoordinates.Get(index))
                    successfulCoordinates.RemoveAt(index) ; Remove the coordinate
                    continue ; Skip to the next coordinate
                }

                if UpgradeUnit(coord.x, coord.y, coord.slot) {
                    break
                }

                if IsMaxUpgrade(upgradeSlot) {
                    AddToLog("Max upgrade reached for: X" coord.x " Y" coord.y)
                    maxedCoordinates.Push(successfulCoordinates.Get(index))
                    successfulCoordinates.RemoveAt(index) ; Remove the coordinate
                    continue ; Skip to the next coordinate
                }

                Sleep(200)
                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
                {
                    BetterClick(373, 237)
                }
                if (cardPickerEnabled == 1) {
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, pick_card)) { ; CARD PICKER
                        cardSelector()
                        ;AddToLog("Succesfully picked card")
                    }
                }
                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                DisconnectCheck()
            }

            ; If all units are maxed, still check for stopping condition
            if successfulCoordinates.Length == 0 and maxedCoordinates.Length > 0 {
                DisconnectCheck()
                if (cardPickerEnabled == 1) {
                    if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, pick_card)) { ; CARD PICKER
                        cardSelector()
                        ;AddToLog("Succesfully picked card")
                    }
                }
                isMatchFinished() ; next
                if ShouldStopUpgrading() {
                    AddToLog("Stopping due to finding return to lobby button.")
                    return isMatchFinished()
                }
                Sleep(2000) ; Prevent excessive looping

            }

            DisconnectCheck()
        }
    }
}

DisplayObj(Obj, Depth := 5, IndentLevel := "") {
    if Type(Obj) = "Object"
        Obj := Obj.OwnProps()
    for k, v in Obj {
        List .= IndentLevel "[" k "]"
        if (IsObject(v) && Depth > 1)
            List .= "`n" DisplayObj(v, Depth - 1, IndentLevel . "    ")
        else
            List .= " => " v
        List .= "`n"
    }
    return RTrim(List)
}

SortByPriority(&successful, slotPriorityMap) {
    for i, item in successful {
        j := i
        currentPriority := slotPriorityMap[item.slot]

        while (j > 1) {
            prevItem := successful[j - 1]
            prevPriority := slotPriorityMap[prevItem.slot]

            if (prevPriority > currentPriority) {
                successful[j] := prevItem
                successful[j - 1] := item
            } else {
                break
            }
            j := j - 1
        }
    }
}

SuccessfulToString(arr) {
    output := ""
    for index, item in arr {
        output .= "Slot: " item.slot ", X: " item.x ", Y: " item.y "`n"
    }
    return output
}

/*
[1]
    [slot] => slot_6
    [x] => 123
    [y] => 456

[2]
    [slot] => slot_4
    [x] => 123
    [y] => 456

[3]
    [slot] => slot_2
    [x] => 15
    [y] => 92

[4]
    [slot] => slot_5
    [x] => 15
    [y] => 92

[5]
    [slot] => slot_1
    [x] => 15
    [y] => 92

[6]
    [slot] => slot_1
    [x] => 123
    [y] => 456

[7]
    [slot] => slot_3
    [x] => 15
    [y] => 92









---

[1]
    [slot] => slot_1
    [x] => 15
    [y] => 92

[2]
    [slot] => slot_1
    [x] => 15
    [y] => 92

[3]
    [slot] => slot_2
    [x] => 123
    [y] => 456

[4]
    [slot] => slot_3
    [x] => 15
    [y] => 92

[5]
    [slot] => slot_5
    [x] => 15
    [y] => 92

[6]
    [slot] => slot_4
    [x] => 123
    [y] => 456

[7]
    [slot] => slot_6
    [x] => 123
    [y] => 456




*/

UpgradeUnit(x, y, slot) {
    BetterClick(x, y)
    sleep 100
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    SendInput("r")
    if (IsMaxUpgrade(UpgFM.Get(Number(StrReplace(slot, "slot_"))))) {
        return true
    }
    Sleep 100
    BetterClick(785, 550)
}

IsMaxUpgrade(upgrade) {
    Sleep 500
    ;if (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade2)) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade3))) {
    ;return true
    ;}
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, UpgradesMap.Get("UPG" . upgrade))) {
        return true
    }
}

UpgradesMap := Map(
    "UPG1",
    "|<Upgrade 0>*90$25.zzzzzzzzzzzzzzzzzzzzzVsQ7ks63ts1lwwMsySQQTCCCDb777nXXXtsllww0syT0wTDkyDbzz7kzz3sTz1yDzlzzzzzzzzz",
    "UPG2", "|<Upgrade 1>*89$22.zzzzzzzzzzzsTMDVkUyS3XtkCDb0sySXXtyCDbssyTXXtyCDbssyTXXtzyDVzky7y3wTwTzzzzzzzU",
    "UPG3",
    "|<Upgrade 2>*90$25.zzzzzzzzzzzzz3ksDVUA7nk3XtkllwsssySQQTDsSDbsD7nkTXts1lws0syS0QTDzyDVzy7kzy3wTzXzzzzzzzzw",
    "UPG4",
    "|<Upgrade 3>*90$25.zzzzzzzzzzzzz3ksDVkA7nk3XtsllwzUsyTkwTDsCDbz77nXXXts1lww0syT1wTDzyDVzy7kzy3wTzXzzzzzzzzw",
    "UPG5", "|<Upgrade 4>*88$24.zzzzzzzzzzzzsQm3sME3tslXtslXtslXtslXtk1Xtk1Xts1XtzlXtzlXtzlXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG6", "|<Upgrade 5>*90$23.zzzzzzzzzzzz3UUy601ww1Xtsz7nkSDbUQTC0MySMlwzlXts37nUCDbkwTDzsy7zVwDy3wTyDzzzzzzzw",
    "UPG7", "|<Upgrade 6>*89$24.zzzzzzzzzzzzsTW3sS23tw3XtsTXtszXts7Xtk3Xtk3XtllXtsXXts3Xtw7XtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG8", "|<Upgrade 7>*89$24.zzzzzzzzzzzzsM23sE03tk1XtzXXtz3Xtz7Xty7XtyDXtwTXtwTXtwTXtwTXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG9", "|<Upgrade 8>*92$24.zzzzzzzzzzzzsS63sM23ts3XtslXts3Xts3Xts3XtslXtllXts1Xts3Xtw7XtzzXsTz3sTy3wzz7zzzzzzzzU",
    "UPG10", "|<Upgrade 9>*90$24.zzzzzzzzzzzzsQC3sM23ts3XtlnXtkVXts1Xtw3XtzXXtz3Xts7XtsDXtsTXtzzXsTz3sTy3wTz7zzzzzzzzU",
    "UPG11",
    "|<Upgrade 10>*92$32.zzzzzzzzzzzzzzzzsTT3Uy73UMDbUk3XtkAMsyQ3CCDbsXXXty8ssyTWCCDbslXXtyA0syTXUSDbswDXtzzzsy7zzwDVzzy3wzzzlzzzzzzzzzzzU",
    "UPG12",
    "|<Upgrade 11>*90$29.zzzzzzzzzzzzzzz3vxUy73V1ww63Xtk877nUECDbcoQTDlssyTXllwz7XXtyD77nwSCDbswQTDzzsy7zzVwDzy3wTzyDzzzzzzzzzw",
    "UPG13",
    "|<Upgrade 12>*91$32.zzzzzzzzzzzzzzzzsTT3Uy730MDbUk3Xtk8MsyQ2CCDbcnXXtyDVsyTXkSDbskTXtyA0syTW0CDbsk3Xtzzzsy7zzwDVzzy3wzzzlzzzzzzzzzzzU",
    "UPG14",
    "|<Upgrade MAX>*88$29.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzztzzzzUTXly8S7XwsMC3tkEQ7nU0lD78FWCCNW0SQz40Qty1wtnwntnzzzzlzzzznzzzzzzzzzzzzzzzzzz7zzzz"
)

ShouldStopUpgrading(sleepamount := 300) {
    Sleep sleepamount
    if CheckForLobbyButton() {
        Sleep(100)
        return DetermineOutcome()
    }
}

LookDown() {
    MouseMove(400, 300)
    loop 20 {
        SendInput("{WheelUp}")
        Sleep 50
    }
    Sleep 200
    MouseGetPos(&x, &y)
    MouseMove(400, 300)
    SendInput(Format("{Click {} {} Left}", x, y + 150))

    loop 20 {
        SendInput("{WheelDown}")
        Sleep 50
    }
}

LoadedLoop() {
    global hasReconnect, gameEnded
    AddToLog("Waiting to load in")
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            global StageStartTime := A_TickCount
            AddToLog("Loaded in")
            gameEnded := false
            if (hasReconnect == 1) {
                if (WebhookE ? (DCWebhookE ? true : false) : false)
                    discord.SendEmbed("Reconnect")
                hasReconnect := 0
            }
            Sleep 1000
            BetterClick(350, 103) ; click yes
            BetterClick(350, 100) ; click yes
            BetterClick(350, 97) ; click yes
            Sleep 200
            OnSpawnSetup()
            break
        }
        else if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, P)) {
            Sleep 10000
            if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, P) and (ok !=
                FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart))) {
                global StageStartTime := A_TickCount
                AddToLog("Loaded in late")
                gameEnded := false
                if (hasReconnect == 1) {
                    if (WebhookE ? (DCWebhookE ? true : false) : false)
                        discord.SendEmbed("Reconnect")
                    hasReconnect := 0
                }
                Sleep 1000
                BetterClick(350, 103) ; click yes
                BetterClick(350, 100) ; click yes
                BetterClick(350, 97) ; click yes
                Sleep 200
                OnSpawnSetup()
                break
            }
        }

        DisconnectCheck()
    }
    /*
    chat := ChatToSend.Value
    if (ChatStatusBox.Value = 1 && StrLen(chat) > 0) {
        AddToLog("Sending chat")
        SendChat()
    }*/
}

StartedLoop() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            continue
        }
        AddToLog("Game started")
        TryPlacingUnits()
        break
    }
}

LobbyLoop() {
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
            break
        }
        DisconnectCheck()
    }
    AddToLog("Returned to lobby, going back to raids")
    return GoToRaids()
}

CheckForLobbyButton() {
    if (ok := FindText(&X, &Y, 273, 103, 482, 214, 0, 0, LobbyText)) {
        return true
    }
}

SendChat() {
    SendInput("/")
    Sleep 250
    /*chat := ChatToSend.Value
    if (ChatStatusBox.Value = 1 && StrLen(chat) > 0) {
        for char in StrSplit(chat) {
            Send(char)
            Sleep(Random(100, 200))  ; Optional delay between each keypress
        }
    }*/
    if SendChatE.Value = 1 && StrLen(chatContents) > 0 {
        Send(chatContents)
    }
    Sleep 1200
    SendInput("{Enter}")
    Sleep 250
    BetterClick(130, 43)
}

DisableAutoUpgradeUI :=
    "|<>*106$324.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzUTDzzwzXzzyTzzzzzzkzzzzzzblzzzzzzyDzyT6TzzzzzzzzzzzzzzU77zzwTXzzyDzz7zzz0DzzzzzXlzzzzzzyDzyD6Dzzzzzzzzzs0TzzU3zzzwTXzzwDzz7zzy07zzzzzXlzzzzzzyDzyD6DzzzzzzzzzU07zzX3zDzQTXtzw7zi7lzy73zyTvzXlzzxyzryDbyD6Dzzzz00000001zzXVA3UA1XUTs7b41UTyDW1s60zXlUS0UM3UC1yD6Dzzzw00000000zzXl430A1X0Ds3X410DwTW0k20TXlUA0UE30A0yD6Dzzzs00000000zzXl4T0A0X6DlXX676DwTW8FW0TXlW4EXk30AMyD6Dzzzk00000000TzXl42CAMW0Dk1X76CA4DWA02ATXlX0sXXWC80yD6DzzzU00000000TzXXC26AMW0TU1X76682D2A06QTXVX0EXVX681yC6DzzzU00000000DzU3AX0A0V6TU0U730A6060FaQTU3U40bk30ANy0CDzzz000000000DzU7830A1V0T7sk710Tz0C0k6QTk3UC0bk30A1z0CTzzz000000000DzUTA7kA3lUTbss7XkzzUS3s6QTsDUz8bw3kC1zUyTzzz000000000DzzzzzzzzzzzzzzzzzzzzyTzzzzzzbyszzzzzzzzzzzzz000000000DzzzzzzzzzzzzzzzzzzzzyTzzzzzzbw1zzzzzzzzzzzzz000000000DzzzzzzzzzzzzzzzzzzzzyTzzzzzzby3zzzzzzzzzzzzz000000000DzzzzzzzzzzzzzzzzzzzzyTzzzzzzbzjzzzzzzzzzzzzz000000000DzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU00000000DzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU00000000Dzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk00000000TzzjzSzzzzzzzzzrzzrzzzzzyzzzzjzzyzzTzzzzjzzzzs00000000TzVzzSzzzyzzzzzzzxrzzzzzyzrPz9zzyzzzzzzzvzzzzw00000000zzgxzSvrzyRzjyzzzwrrzzzzwrrPz9rzyzrzzzzztzzzzz00000000zzifV2ojVOMT2B8I8QkdqX2MEdrPV0dD6kXEVkvEdzzzzzzzzzy001zzidhOobhOvTOp/JeRqdqhGvKdrPhRdTOqjKdqvKfzzzzzzzzzzU07zzhidGrvdGuTGhvJeRqjofGuIjqvdRjTKojKdouKfzzzzzzzzzzs0TzzXdp6tbpfQzayTLjSqnujuxOntvpQnTSunSxuxShzzzzzzzzzzzzzzzzzzzzzzzzzyzzzyzzzzjrzzzzzzzzzTzzzvzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxzzzzzjzzzzzzzzzzzzzrzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU"
ShowUpgradeUIOnLeft :=
    "|<>*97$322.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzznwTzzzzzzzzzzzzzzzXzzzzzzzzzzyDzz7zzzzzzzzzzzzzzzzzzzw1lzzzzzz7lzzzzzzzyDzzXslzzzzzszzsNzzzzzzzzw0zzzzzzzzzU77zzzzzwT7zzzzzzzszzyDX7zzzzzXzz13zzzzzzzy00Tzzzzzzzy0QTzzzzzlwTzzzzzzzXzzsyATzzzzyDzwQDzzzzzzzk00zzzzzzzzsvlDwSSxz7lqTqSnvjqDXzXslzszNzsz7U0Tzzzzzzy001zzzzzzzzVz0D0ElXwT60w0k60Q0s3yDX7y0s1zXk400zzzzzzzk003zzzzzzzy0w0s024DlwM1U30E1U307syATk1U3yC0003zzzzzzy0007zzzzzzzw1k1U28Ez7lU20A3060A8TXslz060DssEU0Dzzzzzzs000Tzzzzzzzw374C807wT6C0klsMMkVVyDX7sQMszX3373zzzzzzzU001zzzzzzzzyAQEsk0TlwMs337Vl3W07syATVlXXyA0AQDzzzzzzw0003zzzzzzzssllX303z3VV20AT664ATzVklz66CDsszlkzzzzzzzk000DzzzzzzzU3760A4Dy0C0M0lw0M0k3z077w0MszVU77Uzzzzzzz0000zzzzzzzy0QQQ1slzs0s1k37s1k3UDw0QTs3XXy30QS3zzzzzzw0003zzzzzzzw3llsDXbzsDWTWATl7WD0zw7lzkSCDwS1lwDzzzzzzk000DzzzzzzzzzzzzzzzzzyDxkzzzzzzzzzzzzzzzzzzzzzzzzzzzz0000zzzzzzzzzzzzzzzzzzszU7zzzzzzzzzzzzzzzzzzzzzzzzzzzw0003zzzzzzzzzzzzzzzzzzXy0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzk000DzzzzzzzzzzzzzzzzzyDy7zzzzzzzzzzzzzzzzzzzzzzzzzzzzU001zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy0007zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs000TzzzzzzzqzzzzyzxTzzzzrvbzzzzzzLzTXzbzzzzzzzzzzzzzzk003zzzzzzzz/zybvvvoxzzxyPiTzzTrjxDRq7qTPyvirTzzzzzzzzU00Tzzzzzzzug0esA27E3M0AE6tk00Us1o0o+Q/o37gY03zzzzzzzz003zzzzzzzzUkORjg9xMyWFglxLMWBbgrKDHjqj/IzCnBjzzzzzzzy00TzzzzzzzxpKBbz6nndsaD4Hly9aMzDQuSarayn7tDaSTzzzzzzzz0DzzzzzzzzzzzjzzzzzzzxzzzzzzzzzzzzzzzzrzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU"

CheckIngameSettings() {
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, DisableAutoUpgradeUI)) {
        BetterClick(526, 263)
        Sleep(300)
    }
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, ShowUpgradeUIOnLeft)) {
        BetterClick(526, 312)
        Sleep(300)
    }

    return true
}

TPtoSpawn() {
    CoordMode("Mouse", "Client")
    BetterClick(27, 574) ; setings
    Sleep 1000
    BetterClick(400, 287)
    Sleep 600
    loop 4 {
        Sleep 150
        SendInput("{WheelDown 1}") ; scroll
    }
    Sleep 600
    CheckIngameSettings()
    Sleep(500)
    BetterClick(525, 366) ; tp to spawn
    Sleep 600
    BetterClick(582, 175) ; exit settings

}

AntiCaptcha() {
    global deltaX, deltaY
    ocrResult := OCR.FromRect(230 + deltaX, 290 + deltaY, (570 - 230), (340 - 290), , 2)
    ; Display OCR results
    DisconnectCheck()
    if ocrResult {
        BetterClick(414, 342)
        AddToLog("Captcha Detected: " ocrResult.Text)

        ; Clean up the captcha string
        captcha := StrReplace(ocrResult.Text, " ")  ; Remove spaces
        if (StrLen(captcha) <= 1 || RegExMatch(captcha, "[A-Za-z]")) {
            AddToLog("invalid captcha retrying")
            BetterClick(584, 192) ; close captcha
            return
        }

        ; Remove special characters like /, -, and .
        captcha := RegExReplace(captcha, "[^0-9]")

        ; Send captcha
        Send(captcha)
    } else {
        AddToLog("NO CAPTCHA FOUND.")
    }

    BetterClick(309, 386) ; select
    Sleep 1500
    BetterClick(383, 221)
    Sleep 500

    sleep 6000
    if (ok := FindText(&X, &Y, 10, 70, 350, 205, 0, 0, LoadingScreen)) {
        return
    }
    if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
        return
    }
    AddToLog("Walking to ensure the UI pops up again if it didnt matchmake")

    loop 2 {
        HoldKey("D", 400)
        HoldKey("A", 800)
        HoldKey("Space", 2000)
    }

    Sleep 1500
    if (ok := FindText(&X, &Y, 221, 206, 403, 355, 0, 0, MatchmakeUI)) {
        AddToLog("Waiting for captcha cooldown then retrying")
        Sleep 6000
    }
    DisconnectCheck()
    return
}

TapToMove(toggle) {

    SendInput("{Esc}")
    Sleep 1000
    BetterClick(246, 121)
    Sleep 300
    SendInput("{Down}")
    Sleep 100
    SendInput("{Down}")
    Sleep 300
    if (toggle) {
        SendInput("{Right}")
        Sleep 300
        SendInput("{Right}")
    }
    else {
        SendInput("{Left}")
        Sleep 300
        SendInput("{Left}")
    }
    Sleep 300
    SendInput("{Esc}")
    Sleep 1000
}

PixelSearchFunction(Color, Xtl, Ytl, Xbr, Ybr, Tol) {
    CoordMode("Pixel", "Window")
    if (!WinActive("ahk_exe RobloxPlayerBeta.exe")) {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
    }
    global foundX, foundY
    if (PixelSearch(&foundX, &foundY, Xtl, Ytl, Xbr, Ybr, Color, Tol)) {
        CoordMode("Mouse", "Window")
        return true
    } else {
        CoordMode("Mouse", "Window")
        return false
    }
}

MouseRelativeMove() {
    MouseMove(1, 1, 5, "R")
    Sleep(100)
    MouseMove(-1, -1, 5, "R")
}

global startMoveTime := A_TickCount

MoveTowards(key) {
    global startMoveTime
    if (A_TickCount - startMoveTime >= 1500) {
        Send("{" key " Up}")
        return
    }
    Send("{" key " Down}")

    Send("{Space}")

    Sleep(100)
}

MoveTowardsD() {
    MoveTowards("d")
    return
}

MoveTowardsW() {
    MoveTowards("w")
    return
}

MoveTowardsS() {
    MoveTowards("s")
    return
}

OnSpawnSetup() {
    SendInput ("{Tab}")
    LookDown()
    Sleep 200

    BeamPos := Map()
    foundBeam := false
    while foundBeam = false {
        if (PixelSearchFunction(0x43FFFF, 453, 52, 766, 580, 1)) {
            AddToLog("Beam Found")
            if (FoundY < 350) {
                AddToLog("Beam Top Right")
                BeamPos[1] := 577
                BeamPos[2] := 195
                foundBeam := true
                global startMoveTime := A_TickCount
                SetTimer(MoveTowardsD, 100)
                global startMoveTime := A_TickCount
                SetTimer(MoveTowardsW, 100)
            } else if (FoundY > 350) {
                BeamPos[1] := 575
                BeamPos[2] := 530
                AddToLog("Beam Bottom Right")
                foundBeam := true
                global startMoveTime := A_TickCount
                SetTimer(MoveTowardsD, 100)
                global startMoveTime := A_TickCount
                SetTimer(MoveTowardsS, 100)
            }
        }
    }

    Sleep(5200)
    StartedLoop()
}

IsPSLinkValid(url) {
    if url
        RegExMatch(url,
            "i)((http(s)?):\/\/)?((www|web)\.)?roblox\.com\/([a-z]{2}\/)?games\/8304191830\/?([^\/]*)\?privateServerLinkCode=.{32}(\&[^\/]*)*", &
            NewPrivServer)
    if ((StrLen(url) > 0) && !IsObject(NewPrivServer)) {
        if InStr(url, "/share?code") {
            MsgBox("
                    (
                    You entered a 'share?code' link!
                    To fix this:
                        1. Paste this link into your browser
                        2. Wait for Anime Adventures to load
                        3. Copy the link at the top of your browser.
                    )"
                , "Unresolved Private Server Link")
            return false
        } else {
            MsgBox("Make sure your link is:`r`n- copied correctly and completely`r`n- for Anime Adventures",
                "Invalid Private Server Link")
            return false
        }
    }
    return true
}

testReconnect(*) {
    if IsPSLinkValid(PServerURL)
        CloseRoblox()
    if (DisconnectCheck(1) = 1)
        MsgBox "Success!", "Reconnect Test", 0x1000
}

ObjMinIndex(obj) {
    for k, v in obj
        return k
    return 0
}

DisconnectCheck(testCheck := 0) {
    global gameEnded, disconnectionsSession, disconnectionsSessionText

    ; Check if roblox is disconnected
    ActivateRoblox()
    GetRobloxClientPos()
    if ((windowWidth > 0) && !WinExist("Roblox Crash") && !FindText(&X, &Y, 0, 0, 800, 600, 0, 0, RobuxImage)) {
        pBMScreen := Gdip_BitmapFromScreen(windowX + windowWidth // 2 "|" windowY + windowHeight // 2 "|200|80")
        if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) != 1) {
            Gdip_DisposeImage(pBMScreen)
            return 0
        }
        Gdip_DisposeImage(pBMScreen)
    }

    ; Obtain Link Code
    linkCodes := Map()
    for k, v in ["PServerURL"] {
        if (%v% && (StrLen(%v%) > 0)) {
            if RegexMatch(%v%, "i)(?<=privateServerLinkCode=)(.{32})", &linkCode)
                linkCodes[k] := linkCode[0]
            else
                AddToLog("Error`nPrivate Server Invalid")
        }
    }

    ; Stop upgrades / placements
    gameEnded := true

    disconnectionsSession++
    disconnectionsSessionText := disconnectionsSession

    if !testCheck
        if (WebhookE ? (DCWebhookE ? true : false) : false)
            discord.SendEmbed("Disconnect")

    loop {
        server := ((A_Index <= 20) && (n := ObjMinIndex(linkcodes))) ? n : 0

        i := A_Index, success := 0
        loop 5 {
            switch Mod(i, 5) {
                case 1, 2:
                    ;Close Roblox
                    CloseRoblox()
                    ;Run Server Deeplink
                    AddToLog("Attempting Private Server")
                    try Run '"roblox://placeID=8304191830' (server ? ("&linkCode=" linkCodes[server]) : "") '"'

                case 3, 4:
                    ;Run Server Deeplink (without closing)
                    AddToLog("Attempting Private Server Without Closing")
                    try Run '"roblox://placeID=8304191830' (server ? ("&linkCode=" linkCodes[server]) : "") '"'

                default:
                    if server {
                        CloseRoblox()
                        ;Run Server Link (legacy method w/ browser)
                        AddToLog("Attempting Private Server (Browser)")
                        try {
                            run PServerURL
                        } catch {
                            continue 2
                        }
                    } else {
                        (i = 1) && CloseRoblox()
                        try Run '"roblox://placeID=8304191830"'
                    }
            }

            ;STAGE 1 - wait for Roblox window
            loop 240 {
                if GetRobloxHWND() {
                    ActivateRoblox()
                    SetupMacro()
                    AddToLog("Roblox Detected")
                    break
                }
                if (A_Index = 240) {
                    AddToLog("Error`nNo Roblox Found`nRetry: " i)
                    break 2
                }
                Sleep 1000 ; timeout 4 mins, wait for any Roblox update to finish
            }
            ;STAGE 2 - wait for loaded game
            loop 180 {
                SetupMacro()
                ActivateRoblox()
                if !GetRobloxClientPos() {
                    AddToLog("Warning`nDisconnected during Reconnect")
                    continue 2
                }
                pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY + 30 "|" windowWidth "|" windowHeight - 30)
                if (ok := FindText(&X, &Y, 746, 476, 862, 569, 0, 0, AreasText)) {
                    AddToLog("Success`nGame Loaded")
                    success := 1
                    break 2
                }
                if (Gdip_ImageSearch(pBMScreen, bitmaps["disconnected"], , , , , , 2) = 1) {
                    Gdip_DisposeImage(pBMScreen)
                    AddToLog("Warning`nDisconnected during Reconnect")
                    continue 2
                }
                Gdip_DisposeImage(pBMScreen)
                if (A_Index = 180) {
                    AddToLog("Error`nAA Load Timeout`nRetry: " i)
                    break 2
                }
                Sleep 1000 ; timeout 3 mins, slow loading
            }
        }

        ;Successful Reconnect
        if (success = 1) {
            ActivateRoblox()
            ;GoToRaids()
            AddToLog("Reconnect successful")
            if !testCheck
                if (WebhookE ? (DCWebhookE ? true : false) : false)
                    discord.SendEmbed("Reconnect")

            if testCheck = 1 {
                return 1
            }

            return GoToRaids()
        }
    }
}

CloseRoblox() {
    SC_L := "sc026" ; l
    SC_Esc := "sc001" ; Esc
    SC_Enter := "sc01c" ; Enter
    ; if roblox exists, activate it and send Esc+L+Enter
    if (hwnd := GetRobloxHWND()) {
        GetRobloxClientPos(hwnd)
        if (windowHeight >= 500) ; requirement for L to activate "Leave"
        {
            ActivateRoblox()
            prevKeyDelay := A_KeyDelay
            SetKeyDelay 250
            send "{" SC_Esc "}{" SC_L "}{" SC_Enter "}"
            SetKeyDelay prevKeyDelay
        }
        try WinClose "Roblox"
        Sleep 500
        try WinClose "Roblox"
        Sleep 4500 ;Delay to prevent Roblox Error Code 264
    }
    ; kill any remnant processes
    for p in ComObjGet("winmgmts:").ExecQuery(
        "SELECT * FROM Win32_Process WHERE Name LIKE '%Roblox%' OR CommandLine LIKE '%ROBLOXCORPORATION%'")
        ProcessClose p.ProcessID
}

HoldKey(key, duration) {
    SendInput ("{" key "up}")
    ; go to teleporter
    Sleep 100
    SendInput ("{" key " down}")
    Sleep duration
    SendInput ("{" key " up}")
    KeyWait key ; Wait for "d" to be fully processed
}

cardSelector() {
    global SelectedCards
    AddToLog("Picking card in priority order")
    if (ok := FindText(&X, &Y, 78, 182, 400, 451, 0, 0, UnitExistence)) {
        BetterClick(329, 184) ; close upg menu
        sleep 100
    }

    SendInput("{q}")
    BetterClick(59, 572) ; Untarget Mouse
    sleep 500
    /* for index, priority in CardList {
        priority := StrLower(priority)
        priority := StrReplace(priority, " ", "_")
        if (!textCards.Has(priority)) {
            continue
        }
        if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, textCards.Get(priority))) {
            FindText().Click(cardX, cardY, 0)
            MouseMove 0, 10, 2, "R"
            Click 2
            sleep 1000
            MouseMove 0, 120, 2, "R"
            Click 2
            AddToLog(Format("Picked card: {}", priority))
            while (ok := FindText(&cardX, &cardY, 0, 0, 800, 600, 0, 0, pick_card)) {
                Sleep(100)
            }
            return
        }
    } */
    for index, priority in SelectedCards {
        if (!textCards.Has(priority)) {
            continue
        }

        values := textCards.Get(priority)

        if (!IsObject(values)) {
            if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, values)) {
                FindText().Click(cardX, cardY, 0)
                MouseMove 0, 10, 2, "R"
                Click 2
                sleep 1000
                MouseMove 0, 120, 2, "R"
                Click 2
                AddToLog(Format("Picked card: {}", priority))
                sleep 5000
                return
            }
            continue
        }

        keys := []
        for key, value in values {
            keys.InsertAt(1, key)
        }

        for index, key in keys {
            value := values[key]

            if (ok := FindText(&cardX, &cardY, 209, 203, 652, 404, 0, 0, value)) {
                FindText().Click(cardX, cardY, 0)
                MouseMove 0, 10, 2, "R"
                Click 2
                sleep 1000
                MouseMove 0, 120, 2, "R"
                Click 2
                AddToLog(Format("Picked card: {}", priority))
                sleep 5000
                return
            }
        }
    }
    AddToLog("Failed to pick a card")
}

DetermineOutcome() {
    global winsSession, lossesSession, attemptsSession, attemptsSessionText, lossesSessionText, winsSessionText

    gameEnded := true

    attemptsSession++
    attemptsSessionText := attemptsSession

    ; Checks for win or loss
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, DeathText)) {
        lossesSession++
        lossesSessionText := lossesSession
        win := false

        if (WebhookE ? (SOWebhookE ? true : false) : false) {
            SendInput ("{Tab}")
            Sleep 150
            discord.SendEmbed("Loss")
        }
    }
    else {
        winsSession++
        winsSessionText := winsSession
        win := true
    }

    BetterClick(348, 391) ; Clicks next

    if win {
        if (WebhookE ? (SOWebhookE ? true : false) : false) {
            SendInput ("{Tab}")
            Sleep 150
            discord.SendEmbed("Completed")
        }
    }

    AddToLog("returning to lobby")
    SavedMouseCoord := A_CoordModeMouse
    CoordMode("Mouse", "Window")

    if MatchmakeMode.Value = 1 { ; Matchmake
        BetterClick(320, 153) ; Clicks return to lobby
        sleep 500
        BetterClick(320, 150)
        sleep 500
        BetterClick(320, 147)
        CoordMode("Mouse", SavedMouseCoord)
        return LobbyLoop()
    } else {
        BetterClick(500, 153) ; Clicks replay
        sleep 500
        BetterClick(500, 150)
        sleep 500
        BetterClick(500, 147)
        CoordMode("Mouse", SavedMouseCoord)
        return AfterGame()
    }

}

global starsTries := 0

DebugRect(x, y, w, h) {
    hDC := DllCall("GetDC", "Ptr", mainGui.Hwnd, "Ptr")
    DllCall("gdiplus.dll\GdipCreateFromHDC", "Ptr", hDC, "Ptr*", &pGraphics := 0)
    DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
    DllCall("Gdiplus.dll\GdipCreatePen1", "UInt", 0xFF0000FF, "Float", 2, "Int", 2, "Ptr*", &pPen := 0)

    DllCall("Gdiplus.dll\GdipDrawRectangle", "Ptr", pGraphics, "Ptr", pPen, "Float", x, "Float", y, "Float", w,
        "Float",
        h)

    sleep 3000

}

isMatchFinished() {
    global starsSession, starsSessionText, starsTries, gameEnded
    DisconnectCheck()
    if (ok := FindText(&X, &Y, 0, 0, 800, 600, 0, 0, EndScreen)) { ; checks for end screen
        BetterClick(328, 186) ; closes unit upg menu
        try {
            ; Count stars earned
            StarResult := OCR.FromRect(300 + deltaX, 360 + deltaY, (440 - 300), (400 - 368), , 2)
            AddToLog(StarResult.Text)

            if StarResult {
                ; Clean up the captcha string
                stars := StrReplace(StarResult.Text, " ")  ; Remove spaces
                if (starsTries < 2) {
                    if (StrLen(stars) <= 1 || RegExMatch(stars, "[A-Za-z]")) {
                        AddToLog("invalid selection. retrying..")
                        starsTries += 1
                    }
                }

                ; Remove special characters like /, -, and .
                stars := RegExReplace(stars, "[/.\-_,+•*]")

                ; Update stat
                starsSession += stars
                starsSessionText := starsSession
            } else {
                AddToLog("NO CAPTCHA FOUND.")
            }

            DetermineOutcome()
        } catch {
            DetermineOutcome()
        }
    }
}
