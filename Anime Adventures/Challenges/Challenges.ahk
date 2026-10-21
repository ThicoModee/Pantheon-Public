; Dependencies
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include GUI\gui.ahk
#Include WebhookOptions.ahk
#Include GUI\Maps.ahk
#Include GUI\Movements.ahk

#Include ..\..\
#Include Lib\FindText.ahk
#Include Lib\imageForCS.ahk
#Include Lib\OCR-main\Lib\OCR.ahk
#Include Lib\IsProcessElevated.ahk
#Include Lib\Gdip_ImageSearch.ahk
#Include Lib\Gdip_All.ahk
#Include Lib\Roblox.ahk

#DllLoad "Gdiplus.dll"

; Variables
global MacroStartTime := A_TickCount
global StageStartTime := A_TickCount

global hasReconnect := 0

; Define the rectangle coordinates
global startX := 100, startY := 500, endX := 700, endY := 350
global startY2 := 200, endY2 := 350
global step := 50 ; Step size for grid traversal
global successfulCoordinates := [] ; Array to store successful placements
global unsuccessfulCoordinates := []
global potentialPlacements := []
global filtered := []
global successThreshold := 3 ; Number of successful placements needed

pathColorsArray := ["0xb20032", "0xCC0033", "0xCC0066", "0xFF3366", "0xFF3399", "0xCC0000", "0xFF0033", "0xFF3333",
    "0xFF3366"]
brickColorsArray := ["0x2cd5ff", "0x003366", "0x336699", "0x00f7ff"]
hillColorsArray := ["0x006600", "0x009900", "0x00CC00", "0x00FF00", "0x33CC33", "0x33FF33", "0x66CC66", "0x66FF66",
    "0x99CC99"]
; x: 60, y: 630
; --
; x: 620, y: 630
; x: 805, y: 300
; x: 764, y: 72
; x: 655, y: 100
rect1 := { x: 0, y: 511, width: 60, height: 89 }
rect2 := { x: 0, y: 0, width: 260, height: 100 }
rect3 := { x: 215, y: 510, width: 405, height: 90 }
rect5 := { x: 625, y: 160, width: 180, height: 110 }
rect4 := { x: 570, y: 0, width: 194, height: 72 }
rect6 := { x: 135, y: 53, width: 490, height: 55 }

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
HolidayHunt :=
    "|<>*80$121.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzllzXzzzzzzzzzzzzsyDzsszlzzzzsyDzzztzwT7zwQTszzzzwT7zzzwTyDXzyDzwTzzzyDXzzzyDz7lwT7zyDzvvz7lzzzz7zXss3XXU700szXsllU60Tk0M1llU304QTk0Msk30Ds0A0Msk1U26Ds0AQM0kDw06CAQMsllWDw06CAQQTyDX76CAQMsk7yDX76CCDz7lXX76AAMQ3z7lV3777zXsk1VX060D3zXsk1XXUzlwQ1kFk3U7VzlwQ0llkTsyT1wMwFsXlzsyT4MsyDzzzzzzzzzzkzzzzzzzzzzzzzzzzzzzszzzzzzzzzzzzzzzzzzzwTzzzzzzzzzzzzzzzzzzyTzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk"
DeathText := "|<>*100$22.zzzzUzUw3w3l7l6ASAMtstXbXaASAQFgFkAEDUlUzzzzU"
InElevator :=
    "|<>*115$152.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz7zzzzzzt9yTzzwzzzzzzzzzzz0zzzzzzy2T7zzzDzzzzzzzzzzUDzzzzzzsblzzzzzzzzzzzzzztzUkHkyn89w3ksAUz3VsQ7zzzwMk80M74E2T0M4207kEA20zzzz60200Ns00bk4M8U1wsW8UDzzzlkAW80S0E9wN0386T0AX8nzzzyA28W1zU42D4Fs21bs38mAzzzzk428W1wH41k610UNs430X80zzy3Um9kTAt4S3kMAaT3VsQm0DzzzzzzzzzzzzzzyXzzzzzzzzzzzzzzzzzzzzzzzz0zzzzzzzzzzzzzzzzzzzzzzzzszzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs"
NextButton :=
    "|<>*79$113.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw0000000000000000Tzk0000000000000000Tz00000000000000000Tw00000000000000000Ts00000000000000000zk00000000000000001zU00000000000000003z000000000000000007y00000000000000000Dw00000000000000000Ts00007ky0001s00000zk0000Mn40006s00001zU0000ko80008k00003z00001UcEwA6kU00007y000031kbywzVk0000Dw000061Vs7D40k0000Ts0000A13U4A01U0000zk0000M060A0E300001zU0000l0AA81sA00003z00001X0E0s6kk00007y0000370U1kBVU0000Dw00006C1Vz0D3U0000Ts0000AS3040C100000zk0000Mq708MA200001zU0000laD0Nsw400003z00000yDrzzTDs00007y00000s73wMA700000Dw00000000000000000Ts00000000000000000zk00000000000000001zU00000000000000003z000000000000000007z00000000000000000Tz00000000000000001zz00000000000000007zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk"
NeoTokyo2 :=
    "|<>*94$272.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzUzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk7zzzzzzzzzzzzzzlzzzXzzzzzzzzzzzzzzs00003zzzzs0zzzzzzzzzzzzzzk7zzUDzzzzzzzzzzzzzs00000Tzzzy0Dzzzzzzzzzzzzzs0zzk1zzzzzzzzzzzzzy000003zzzzU3zzzzzzzzzzzzzy07zw0TzzzzzzzzzzzzzU00000zzzzs0zzzzzzzzzzzzzzU1zz07zzzzzzzzzzzzzs00000Dzzzy0Dzzzzzzzzzzzzzs0Dzk1zzzzzzzzzzzzzy000003zzzzU3zzzzzzzzzzzzzy01zw0TzzzzzzzzzzzzzU00001zzzzs0zzzzzzzzzzzzzzU0Dz07zzzzzzzzzzzzzz00001zzzzy0Dzzzzzzzzzzzzzs03zk1zzzzzzzzzzzzzzzz07zzzzzzU3zzzzzzzzzzzzzy00Tw0Tzzzzzzzzzzzzzzzk1zzzzzzs0zzzzzzzzzzzzzzU03z07zy0zzzw3zzzzzzzw0Tzzs7zy0Dzzszztzzw1zzzs00Tk1zw01zzs07zzzzzzz07zzk0DzU3zzs7zw3zs07zzy007w0Tw00Dzs00Tzzzzzzk1zzk00zs0zVw1zy0Ts00TzzU00z07y001zw003zzzzzzw0Tzs007y0DUS0DzU7w003zzs007k1z000Dy000Tzzzzzz07zw000zU3k3U3zk1y000Tzy000w0TU001z0003zzzzzzk1zy0007s0s0M0Tw0T0003zzU00D07k000TU000Tzzzzzw0Tz0000y0A0703y07U000Tzs0U1k1w0003s0007zzzzzz07zk000DU201k0zU3s0007zy0A0A0S03s0w0000zzzzzzk1zs0001s000S07k0w0000zzU30107U1y0D01w0Dzzzzzw0Ty03k0S000DU1w0T01s0Dzs0s0E1s0zk3k1zU3zzzzzz07zU3z07U00Dw0C07k1zU3zy0D000Q0Ds0s0Ts0Tzzzzzk1zk0zk0s007zU1U1s0Ts0TzU3s0070000C0Dz07U01zzw0Tw0Ty0C003zs0M0y0Dz07zs0y001k0003U3zk1k00Dzz07z07zU3U01zz000DU3zk1zy0Dk00Q0001s0zw0M003zzk1zk1zs0s00Tzk007s0zw0TzU3y0070000y0Dz06000zzw0Tw0Ty0C001zy001y0Dz07zs0zk01s000Tk1zU3U00Dzz07zU3z07U00Dzk00zk1zU1zy0Dw00S0Dzzw0Dk0s003zzk1zs0TU1s001zw00Dw0Dk0zzU3zU07U1zzz00k0D000zzw0Ty01U0S000DzU07z00k0Dzs0zw01s0DsTs0007s00Tzz07zk000DU201zs01zs0003zy0DzU0T0003y0001zzzzzzk1zw0003s0k0Dz00zy0001zzU3zs07k000Tk000zzzzzzw0TzU001y0C01zs0Dzk000zzs0zz01y0007y000Dzzzzzz07zw000TU3k0Ty03zy000Dzy0Dzs0Tk001zk007zzzzzzk1zz000Ds0y07zk1zzU007zzU3zz07y000Ty007zzzzzzw0zzw007y0Dk3zs0Tzy007zzw1zzk3zk00Dzk03zzzzzzz0DzzU07zU7y1zy0Dzzk03zzzUzzz1zz00Dzz03zzzzzzzs7zzy07zy3zkzz03zzz03zzzzzzzzzzzVzzzzzzzzzzzzzzzzzzzzzzzzzzk1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy0DzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk0zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy07zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs0zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzXzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"

RobuxImage :=
    "|<>*93$40.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzUTzzzzw0zzzzz3kzzzzkTUzzzw73UzzzVs7VzzyS07bzzlU06DzzA00Azzwk00nzzn1y3DzzA7sAzzwkTUnzzn1y3DzzA7sAzzwkTUnzzn003DzzC00QzzwQ03Xzzss0QTzzVs7VzzzVtsTzzz1y3zzzz1Uzzzzz0Dzzzzz3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"

bitmaps := Map(), bitmaps.CaseSense := 0
base64 :=
    "iVBORw0KGgoAAAANSUhEUgAAAGQAAAASBAMAAABft2a7AAAAElBMVEU5Oz38/Pz8/f39/f3+/v7///+Pg9IaAAAALElEQVR42mMYBcMGCAoKCikbQ4ELFIRCQQiU72wMBUqCgoIMoSSDUS100AIAwSaP+Z3P8L8AAAAASUVORK5CYII="
bitmaps["disconnected"] := Gdip_BitmapFromBase64(
    &base64
)

CannotPlaceUnitsArr := [CannotPlaceUnit1, CannotPlaceUnit2, CannotPlaceUnit3, CannotPlaceUnit4, CannotPlaceUnit5]

findAngleAndHoldKey(anglePatterns, keyDurations) {
    for index, angleData in anglePatterns {
        if (FindText(&X, &Y, angleData.xMin, angleData.yMin, angleData.xMax, angleData.yMax, 0, 0, angleData.pattern)) {
            AddToLog("Found Angle: " angleData.pattern)
            for keyData in angleData.keySequence {
                HoldKey(keyData.key, keyData.duration)
                Sleep(200)
            }
            return [true, angleData.placements]
        }
    }
    AddToLog("Not Found")
    return [false]
}

setupPlanet(mapName, angleDataList) {
    return findAngleAndHoldKey(angleDataList, [700, 700])
}

CannotPlaceUnits() {
    global CannotPlaceUnitsArr
    for index, placementAmount in CannotPlaceUnitsArr {
        if (ok := FindText(&X, &Y, 154 - 150000, 478 - 150000, 700 + 150000, 531 + 150000, 0, 0, placementAmount)) {
            return true
        }
    }
    return false
}

HasNotEnoughMoney() {
    if (ok := FindText(&X, &Y, 838 - 150000, 646 - 150000, 838 + 150000, 646 + 150000, 0, 0.8, NotEnoughMoney)) {
        return true
    }
    return false
}

; Instances
RobloxWindow := "ahk_exe RobloxPlayerBeta.exe"

; On startup
;CheckForUpdates()
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
    BetterClick(x, y)
    Sleep 50
    SendInput("q")

    ; Check if placement is successful
    sleep 50
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

Hotkey(pauseBind, (*) => PauseMacro())

MacroState := 0 ; 0=stopped, 1=paused, 2=running

PauseMacro() {
    if A_IsPaused {
        AddToLog("Macro Resumed")
        ActivateRoblox()
        MacroState := 2
    } else {
        AddToLog("Macro Paused")
        ; Suspend Movement
        SendInput("{A Up}")
        MacroState := 1
    }
    Pause -1
}

InitializeMacro() {
    global sessionTime := A_TickCount
    MacroState := 2
    StartStatsUpdate()
    
    TabCtrl.Choose("Status")

    for i, v1 in unitUpgradePrioritydropDowns {
        for j, v2 in unitUpgradePrioritydropDowns {
            if (i < j && v1.Text == v2.Text) {
                foundDuplicate := true
                StopStatsUpdate()
                MsgBox("Duplicate found in your upgrade priorities. Error: ERR_DUPLICATE_PRIORITY", "Error",
                    "+0x1000")
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
        MsgBox("Your ROBLOX must be open in order to start the macro. Error: ERR_RBLX_NOT_OPEN", "Error", "+0x1000",
        )
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

GoToRaids() {
    global Maps
    
    global placementCounts := Map()
    global placementTries := Map()
    SendInput ("{Tab}")
    global foundMap := ""
    global gameEnded := false
    loop {
        if (foundMap != "") {
            break
        }
        ; go to xmas map
        CoordMode("Mouse", "Window")
        for index, value in Maps {
            AddToLog("Checking for " index)
            if (ok := FindText(&X, &Y, 0, 0, 500, 200, 0, 0, value)) {
                AddToLog("Found map " index)
                global foundMap := index
                break 2
            }
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

        BetterClick(774, 505)
        Sleep 500
        BetterClick(310, 445)
        ; go to teleporter
        Sleep(500)
        HoldKey("d", 2000)
        HoldKey("s", 4000)

        if (ok := FindText(&X, &Y, 10 - 15000, 70 - 15000, 350 + 15000, 205 + 15000, 0, 0, InElevator)) {
            while (foundMap == "") {
                for index, value in Maps {
                    if (ok := FindText(&X, &Y, 0, 0, 500, 200, 0, 0, value)) {
                        AddToLog("Found map " index)
                        global foundMap := index
                        break 3
                    }
                }
            }
        }
    }
    CoordMode("Mouse", "Client")
    LoadedLoop()
    StartedLoop()
    OnSpawnSetup(foundMap)
    TryPlacingUnits()

}

StopMacro() {
    Reload()
}

IsPlacementSuccessful(index, slot) {
    Sleep PlacementSpeed
    if (ok := FindText(&X, &Y, 78, 182, 400, 451, 0, 0, UnitExistence)) {
        AddToLog("Unit placed")
        BetterClick(329, 184) ; close upg menu
        return true
    }
    else if (ok := FindText(&X, &Y, 88 - 150000, 416 - 150000, 88 + 150000, 416 + 150000, 0, 0, Priority)) {
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

;pathColors := 0xb20032 or 0xCC0033 or 0xCC0066 or 0xFF3366 or 0xFF3399 or 0xCC0000 or 0xFF0033 or 0xFF3333 or 0xFF3366
;brickColors := 0x000033, 0x003366, 0x336699, 0x000000, 0x000033, 0x333333, 0x000066, 0x333399, 0x003399

IsCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulCoordinates {
        if (coord.x = coordX && coord.y = coordY) {
            return true
        }
    }
    return false
}

IsHillCoordInUnsuccessful(coordX, coordY) {
    for coord in unsuccessfulCoordinates {
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

PathOrientation(X, Y) {
    range := 30

    for i in [-1, 1] {
        for color in pathColorsArray {
            if (PixelSearch(&OutX, &OutY, X, Y + (i * range), X, Y + (i * range), color, 50)) {
                return "vertical"
            }
        }
    }

    for i in [-1, 1] {
        for color in pathColorsArray {
            if (PixelSearch(&OutX, &OutY, X + (i * range), Y, X + (i * range), Y, color, 50)) {
                return "horizontal"
            }
        }
    }

    return "unknown"
}

generateOffsetCoords(&NfoundX, &NfoundY, PathOrientation) {

    if PathOrientation == "horizontal" {
        ;AddToLog("path horizontal")
        NfoundY := foundY + (Random(1, 2) == 1 ? -30 : 30)
        NfoundX := foundX
    }
    else if PathOrientation == "vertical" {
        ;AddToLog("path vertical")
        NfoundX := foundX + (Random(1, 2) == 1 ? -30 : 30)
        NfoundY := foundY
    }
    else {
        AddToLog("Path orientation unknown")
        NfoundX := foundX + (Random(1, 2) == 1 ? -30 : 30)
        NfoundY := foundY + (Random(1, 2) == 1 ? -30 : 30)
    }

    if (NfoundX > 800) {
        NfoundX := 600
    }

    if (NfoundX <= 50) {
        NfoundX := 100
    }

    if (NfoundY >= 600) {
        NfoundY := 450
    }

    if (NfoundY <= 50) {
        NfoundY := 150
    }

    multiplier := 0.9
    while isInsideAnyRect(NfoundX, NfoundY) {
        unsuccessfulCoordinates.Push({ x: NfoundX, y: NfoundY })

        NfoundX := foundX * multiplier
        NfoundY := foundY * multiplier
        multiplier -= 0.1
        if (multiplier <= 0) {
            break
        }
    }
}

generateHillCoords(&NfoundX, &NfoundY) {

    NfoundX := foundX
    NfoundY := foundY

    if (NfoundX > 800) {
        NfoundX := 600
    }

    if (NfoundX <= 50) {
        NfoundX := 100
    }

    if (NfoundY >= 600) {
        NfoundY := 450
    }

    if (NfoundY <= 50) {
        NfoundY := 150
    }

    multiplier := 0.9
    while isInsideAnyRect(NfoundX, NfoundY) {
        unsuccessfulCoordinates.Push({ x: NfoundX, y: NfoundY })

        NfoundX := foundX * multiplier
        NfoundY := foundY * multiplier
        multiplier -= 0.1
        if (multiplier <= 0) {
            break
        }
    }

    if (IsHillCoordInUnsuccessful(NfoundX, NfoundY) || IsCoordInSuccessful(NfoundX, NfoundY)) {
        generateHillCoords(&NfoundX, &NfoundY)
    }
}

isInsideAnyRect(x, y) {
    for index in [1, 2, 3, 4, 5, 6] {
        rect := %"rect" index%

        if (isInsideRect(rect, x, y)) {
            return true
        }
    }
    return false
}

; 10 545
; 804 628

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
            uniqueArray.Push({ x: Round(item.x), y: Round(item.y) })
        }
    }

    return uniqueArray
}

PathFind(slotNum, placementCount, hill) {
    global potentialPlacements
    potentialPlacements := []
    currentPlacementCount := 0

    SendInput(slotNum)
    MouseMove(785, 550)

    if hill {
        currentTolerance := 5
        while currentPlacementCount < placementCount {
            for i, color in hillColorsArray {
                if (PixelSearchFunction(color, 0, 0, 750, 500, currentTolerance)) {

                    generateHillCoords(&NfoundX, &NfoundY)

                    if (isInsideRect(rect6, NfoundX, NfoundY)) {
                        AddToLog("Generated coord is in healthbar")
                    } else {
                        potentialPlacements.Push({ x: NfoundX, y: NfoundY })
                        currentPlacementCount++
                    }

                }
            }
            currentTolerance += 1
        }
    } else {
        currentTolerance := 5
        while currentPlacementCount < placementCount {
            for i, color in pathColorsArray {
                currentBrickTolerance := 50
                if (PixelSearchFunction(color, 0, 0, 750, 500, currentTolerance)) {
                    ;MouseMove(foundX, foundY)
                    ;AddToLog(i)
                    if (!isInsideAnyRect(foundX, foundY)) {
                        orientation := PathOrientation(foundX, foundY)
                        generateOffsetCoords(&NfoundX, &NfoundY, orientation)

                        if (!IsCoordInUnsuccessful(NfoundX, NfoundY) && !IsCoordInSuccessful(NfoundX, NfoundY)) {
                            potentialPlacements.Push({ x: NfoundX, y: NfoundY })
                            currentPlacementCount++
                        }
                    } else {
                        unsuccessfulCoordinates.Push({ x: foundX, y: foundY })
                    }
                }
                ;AddToLog(color " not found")
                currentTolerance += 1
            }
        }
    }
}

/* PLACEMENT ALGOS BY A CONTRIBUTOR ON TAXI-MACRO-SELFHOST GITHUB PAGE TypeDDL1 */
/*
    clickCoords := Map(
        1, { openHere: {x: 170, y: 420}, matchmaking: {x: 240, y: 420} },  ; Example coords for page 1
        2, { openHere: {x: 330, y: 420}, matchmaking: {x: 400, y: 420} },  ; Example coords for page 2
        3, { openHere: {x: 490, y: 420}, matchmaking: {x: 560, y: 420} }, ; Example coords for page 3
        4, { openHere: {x: 237, y: 420}, matchmaking: {x: 305, y: 420} },  ; Example coords for page 4
        5, { openHere: {x: 397, y: 420}, matchmaking: {x: 465, y: 420} },  ; Example coords for page 5
        6, { openHere: {x: 557, y: 420}, matchmaking: {x: 625, y: 420} }  ; Example coords for page 6
    )
*/

global placementCounts := Map()
global placementTries := Map()

Placement() {
    global successfulCoordinates, maxedCoordinates, filtered, gameEnded
    successfulCoordinates := [] ; Reset successfulCoordinates for each run
    maxedCoordinates := []

    ; Iterate through all slots (1 to 6)
    for slotNum in [1, 2, 3, 4, 5, 6] {
        enabled := %"Unit" . slotNum . "Enabled"%
        placements := %"PlacementFM" slotNum%
        type := %"TypeFM" slotNum%

        if type == 3 { ; Hill
            AddToLog("Slot " slotNum " is a hill slot.")
            hill := true
        } else {
            hill := false
        }

        ; Skip if the slot is not enabled
        if !(enabled = 1) {
            continue
        }

        PathFind(slotNum, placements, hill)

        filtered := FilterUnique(potentialPlacements)

        AddToLog("Starting placements for Slot " slotNum " with " placements " placements.")

        placementCounts.Set(slotNum, 0)
        placementTries.Set(slotNum, 0)

        ; Continue placement for the current slot
        while (placementCounts.Get(slotNum) < placements && placementTries.Get(slotNum) < 25) { ; Rows
            if filtered.Length <= 0 {
                PathFind(slotNum, placements, hill)
                filtered := FilterUnique(potentialPlacements)
            }
            for i, coord in filtered {
                foundX := coord.x
                foundY := coord.y

                if (IsCoordInSuccessful(foundX, foundY) || isInsideAnyRect(foundX, foundY)) {
                    filtered.RemoveAt(i)
                    AddToLog("coord either in successful or intersects with blocked rectangles: x" foundX ", y" foundY)
                    continue
                }

                if gameEnded {
                    AddToLog("Game ended, stopping placement.")
                    break 2
                }

                AddToLog("placing at x" foundX " y" foundY ". currently on try " placementTries.Get(slotNum))

                if PlaceUnit(foundX, foundY, slotNum, i) {
                    placementCounts.Set(slotNum, placementCounts.Get(slotNum) + 1)
                    filtered.RemoveAt(i)
                    successfulCoordinates.Push({ x: FoundX, y: FoundY, slot: "slot_" slotNum }) ; Track successful placements
                } else {
                    filtered.RemoveAt(i)
                    placementTries.Set(slotNum, placementTries.Get(slotNum) + 1)
                }

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) { ; USE ABILITY IF OFF
                    BetterClick(373, 237)
                }

                isMatchFinished() ; next
                SendInput("q")
                BetterClick(565, 563) ; move mouse

                /*if ShouldStopUpgrading(1) {
                    AddToLog("Stopping due to finding lobby  condition.")
                    return LobbyLoop()
                }*/

                DisconnectCheck()
            }
            else AddToLog("Path not found, potentialPlacements length: " potentialPlacements.Length " `nfiltered length: " filtered
                .Length)
            DisconnectCheck()
        }

        AddToLog("Completed " placementCounts.Get(slotNum) " placements for Slot " slotNum ".")
        ; Upgrades Priority unit types inbetween placements

        DisconnectCheck()
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
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
        enabled := %"Unit" . slotNum . "Checkbox"%.Value
        placements := %"PlacementFM" slotNum%
        unitType := %"typeFM" slotNum%

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

                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                if ShouldStopUpgrading(1) {
                    AddToLog("Stopping due to finding lobby  condition.")
                    return LobbyLoop()
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
                return LobbyLoop()
            }
        }

        AddToLog("Completed " placementCount " placements for Slot " slotNum ".")
    }

    UpgradeUnits()

    AddToLog("All slot placements and upgrades completed.")
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
        [30, 30]   ; Row 1, Column 1
    ]
    for index, offset in gridOffsets {

        ; Adds the value that's stored in the array at the current index to either x or y's starting location
        gridX := startX + offset[2] ; Move horizontally by 'step' from the initial start location
        gridY := startY + offset[1] ; Move vertically by 'step' from the initial start location

        if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) ; USE ABILITY IF OFF
        {
            BetterClick(373, 237)
        }

        isMatchFinished() ; next
        BetterClick(565, 563) ; move mouse
        if ShouldStopUpgrading(1) {
            AddToLog("Stopping due to finding lobby condition.")
            return LobbyLoop()
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

global maxedCoordinates := []

UpgradeUnits() {
    if UpgradePriorityE = 1 {
        global successfulCoordinates, maxedCoordinates, unitUpgradePrioritydropDowns, gameEnded
        AddToLog("Beginning prioritized unit upgrades.")

        slotPriorityMap := Map()
        for index, dropDown in unitUpgradePrioritydropDowns {
            priorityText := dropDown.Text
            if priorityText && priorityText != "" {
                slotPriorityMap["slot_" index] := priorityText
            }
        }

        SortByPriority(&successfulCoordinates, slotPriorityMap)

        for index, value in successfulCoordinates {
            AddToLog(value.slot)
        }

        for coord in successfulCoordinates {
            if IsMaxed(coord) {
                AddToLog("Unit already maxed at: X" coord.x " Y" coord.y ". Skipping upgrade.")
                continue
            }
            while !IsMaxUpgrade() {
                UpgradeUnit(coord.x, coord.y)
                if (IsMaxUpgrade()) {
                    break
                }
                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return LobbyLoop()
                }

                if gameEnded {
                    AddToLog("Game ended, stopping placement.")
                    break 2
                }

                Sleep(200)

                if (ok := FindText(&X, &Y, 334, 182, 450, 445, 0, 0, AutoAbility)) {
                    BetterClick(373, 237)
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

        }

        return LobbyLoop()
    }
    else {
        global successfulCoordinates
        global maxedCoordinates

        AddToLog("Beginning unit upgrades.")

        while true { ; Infinite loop to ensure continuous checking
            for index, coord in successfulCoordinates {

                UpgradeUnit(coord.x, coord.y)

                if ShouldStopUpgrading() {
                    AddToLog("Found return to lobby, going back.")
                    successfulCoordinates := []
                    maxedCoordinates := []
                    return LobbyLoop()
                }

                if IsMaxUpgrade() {
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

                isMatchFinished() ; next
                BetterClick(565, 563) ; move mouse
                DisconnectCheck()
            }

            ; If all units are maxed, still check for stopping condition
            if successfulCoordinates.Length = 0 and maxedCoordinates.Length > 0 {
                DisconnectCheck()

                isMatchFinished() ; next
                if ShouldStopUpgrading() {
                    AddToLog("Stopping due to finding return to lobby button.")
                    return LobbyLoop()
                }
                Sleep(2000) ; Prevent excessive looping

            }

            DisconnectCheck()
        }
    }
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

UpgradeUnit(x, y) {
    CoordMode("Mouse", "Window")
    BetterClick(x, y - 3)
    CoordMode("Mouse", "Client")
    SendInput("r") ; upgrade
    SendInput("r") ; upgrade
    SendInput("r") ; upgrade
}

IsMaxUpgrade() {
    Sleep 500
    if (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0,
        0, MaxUpgrade2)) or (ok := FindText(&X, &Y, 142, 346, 406, 472, 0, 0, MaxUpgrade3))) {
        return true
    }
}

ShouldStopUpgrading(sleepamount := 300) {
    Sleep sleepamount
    if CheckForLobbyButton() {
        if (WebhookE ? (DCWebhookE ? true : false) : false) {
            SendInput ("{Tab}")
            Sleep 100
            discord.SendEmbed("Completed")
        }
        BetterClick(376, 117)
        return true
    }
}

OnSpawn() {
    OnSpawnSetup("")
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
    global hasReconnect
    AddToLog("Waiting to load in")
    loop {
        Sleep 1000
        if (ok := FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart)) {
            global StageStartTime := A_TickCount
            AddToLog("Loaded in")
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
            break
        }
        else if (ok := FindText(&X, &Y, 629 - 150000, 67 - 150000, 629 + 150000, 67 + 150000, 0, 0, P)) {
            Sleep 10000
            if (ok := FindText(&X, &Y, 629 - 150000, 67 - 150000, 629 + 150000, 67 + 150000, 0, 0, P) and (ok !=
                FindText(&X, &Y, 326, 60, 547, 173, 0, 0, VoteStart))) {
                global StageStartTime := A_TickCount
                AddToLog("Loaded in late")
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
    Sleep 1200
    SendInput("{Enter}")
    Sleep 250
    BetterClick(130, 43)
}

TPtoSpawn() {
    BetterClick(27, 574) ; setings
    Sleep 1000
    BetterClick(400, 287)
    Sleep 600
    loop 4 {
        Sleep 150
        SendInput("{WheelDown 1}") ; scroll
    }
    Sleep 600
    BetterClick(523, 370) ; tp to spawn
    Sleep 600
    BetterClick(582, 150) ; exit settings

}

AntiCaptcha() {
    global deltaX, deltaY
    ; Perform OCR on the defined region directly
    ;CoordMode("Mouse", "Window")
    ocrResult := OCR.FromRect(230 + deltaX, 290 + deltaY, (570 - 230), (340 - 290), , 2)
    ;ocrResult := OCR.FromRect(230, 260, (570 - 230), (310 - 260), , 2)
    ;x:230 y:260 x2:573 y2:309

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
        captcha := RegExReplace(captcha, "[/.\-_,]")

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
    for index, value in Maps {
        if (ok := FindText(&X, &Y, 10 - 15000, 70 - 15000, 350 + 15000, 205 + 15000, 0, 0, value)) {
            AddToLog("Found map " index)
            global foundMap := index
            break
        }
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
    BetterClick(246, 91)
    Sleep 500
    SendInput("{Down}")
    Sleep 100
    SendInput("{Down}")
    Sleep 500
    if (toggle) {
        SendInput("{Right}")
        Sleep 400
        SendInput("{Right}")
    }
    else {
        SendInput("{Left}")
        Sleep 400
        SendInput("{Left}")
    }
    Sleep 500
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

OnSpawnSetup(currentMap) {
    AddToLog("Setting up movement for " currentMap)
    if (Movements.Has(currentMap)) {
        Movements.Get(currentMap)()
    }
    SendInput("{Tab}")
    LookDown()
    Sleep(200)
}

OnSpawnSetup2(currentMap) {
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
            } else if (FoundY > 350) {
                BeamPos[1] := 575
                BeamPos[2] := 530
                AddToLog("Beam Bottom Right")
                foundBeam := true
            }
        }
    }

    TapToMove(true)
    Sleep(200)
    BetterClick(BeamPos[1], BeamPos[2])
    /*MouseMove(BeamPos[1], BeamPos[2], 0)
    MouseRelativeMove()
    Sleep(50)
    MouseMove(5, -1, 0, "R")
    Sleep(50)
    MouseMove(-5, 1, 0, "R")*/
    Sleep(100)
    loop (20) {
        Click("R")
        Sleep(10)
        Click("Right")
        Sleep(10)
        MouseClick("Right")
        Sleep(10)
    }
    Sleep(5000)
    TapToMove(false)

    /*TPtoSpawn()
    Sleep 200
    TapToMove(true)
    Sleep 200
    AddToLog("Attempting to move to spot")
    loop 80 {
        Sleep 100
    
        if FindAndClickColor() {
            break
        }
    }
    Sleep 4000
    Sleep 1000
    TapToMove(false)*/

}

ObjMinIndex(obj) {
    for k, v in obj
        return k
    return 0
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

NeoTokyo :=
    "|<>*94$277.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzsDzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs3zzzzzzzzzzzzzzzlzzzXzzzzzzzzzzzzzzs00003zzzzs0zzzzzzzzzzzzzzzUDzz0Tzzzzzzzzzzzzzk00000zzzzw0TzzzzzzzzzzzzzzU3zz07zzzzzzzzzzzzzs00000Dzzzy0Dzzzzzzzzzzzzzzk0zzU3zzzzzzzzzzzzzw000007zzzz07zzzzzzzzzzzzzzs0Tzk1zzzzzzzzzzzzzy000003zzzzU3zzzzzzzzzzzzzzw07zs0zzzzzzzzzzzzzz000001zzzzk1zzzzzzzzzzzzzzy01zw0TzzzzzzzzzzzzzU00001zzzzs0zzzzzzzzzzzzzzz00Ty0Dzzzzzzzzzzzzzy00003zzzzw0TzzzzzzzzzzzzzzU0Dz07zzzzzzzzzzzzzzzw0Tzzzzzy0Dzzzzzzzzzzzzzzk03zU3zzzzzzzzzzzzzzzy0Dzzzzzz07zzzzzzzzzzzzzzs00zk1zzUDzzz0zzzzzzzz07zzy1zzU3zzyDzyTzz0Tzzzw00Ds0zy00zzw03zzzzzzzU3zzs07zk1zzw3zy1zw03zzzy007w0Tw00Dzs00Tzzzzzzk1zzk00zs0zVw1zy0Ts00Tzzz001y0Dw003zs007zzzzzzs0zzk00Dw0T0w0Tz0Ds007zzzU00T07w000zs001zzzzzzw0Tzk003y0D0C0Dz07s001zzzk007U3w000Ds000Tzzzzzy0Dzk000z070303zU3s000Tzzs003k1w0007s0007zzzzzz07zk000DU301k0zU1s0007zzw0E0s0y0001w0003zzzzzzU3zs0007k100s0Tk1w0003zzy0A0A0S03s0w0000zzzzzzk1zs0001s000S07k0w0000zzz06020D03w0S03s0Tzzzzzs0zw07U0w000T03s0y03k0TzzU3U107U3z0D07y0Dzzzzzw0Ty0Dw0S000zk0s0T07y0Dzzk1s003U1z0703z03zzzzzy0Dy07y07000zw0A0D03z03zzs0y001k0003U3zk1s00Tzz07z07zU3U00zy060DU3zk1zzw0T000s0001k1zs0s007zzU3zU3zk1k00zzU007k1zs0zzy0Dk00Q0001s0zw0M003zzk1zk1zs0s00Tzk007s0zw0Tzz07w00C0001w0Ty0A001zzs0zs0zw0Q003zw003w0Ty0DzzU3z007U001z07y0C000zzw0Ty0Dw0S000zz003z07y07zzk1zU03k1zzzU1y07000Tzy0Dz03w0D000DzU01zU1y07zzs0zs01s0Tzzk0A03k00Dzz07zU0M07U003zs01zk0A03zzw0Ty00w07wDw0003w00DzzU3zs0007k100zw00zw0001zzy0DzU0T0003y0001zzzzzzk1zw0003s0k0Dz00zy0001zzz07zk0DU000zU001zzzzzzs0zz0003w0Q03zk0TzU001zzzU3zw07s000Ts000zzzzzzw0Tzk001y0D01zs0Dzs000zzzk1zz03y000Dy000zzzzzzy0Dzs001z07k0zy0Dzw000zzzs0zzk1zU007zU01zzzzzzz0Dzz001zU3w0zy07zzU01zzzy0zzs1zs007zs01zzzzzzzU7zzk03zk3z0zz07zzs01zzzzUzzz1zz00Dzz03zzzzzzzs7zzy07zy3zkzz03zzz03zzzzzzzzzzzz3zzzzzzzzzzzzzzzzzzzzzzzzzzU3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs0zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzs0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw0Tzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw0Dzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy0Dzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz07zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzk7zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzw3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzXzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzy"

DetermineOutcome() {
    global winsSession, lossesSession, attemptsSession, attemptsSessionText, lossesSessionText, winsSessionText

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

    ;gameEnded := true
    loop 10 {
        BetterClick(348, 391)
        Sleep(300)
    }

    AddToLog("returning to lobby")
    SavedMouseCoord := A_CoordModeMouse
    CoordMode("Mouse", "Window")

    BetterClick(370, 153) ; Clicks return to lobby
    sleep 10
    BetterClick(370, 150)
    sleep 10
    BetterClick(370, 147)

    CoordMode("Mouse", SavedMouseCoord)
    return LobbyLoop()
}

XPProgress :=
    "|<>*132$124.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzyTtUDz0Tzzzzzzzzzzzzzkz20Dw0TzzzzzzzzzzzzzVsM0Tk0zzzzzzzzzzzzzz33XVz73zzzzzzzzzzzzzy0CD7wSAFkTUAFkD0s7zzs1swTlsk60Q0k60M30TzzkDXVz730E1U30E1XANzzz0y07w0AD324AD767kzzzs1s0zk1lwQ8slw0M30Tzz03U7z0D7lkXX7k1k60zzwA6DzwTwT320AT7zsT3zzVsMzzlzlw0M0lw0M10DzwDkXzz7z7s3k37s1UA1zztzaDzwTwTkTmATkD1sDzzzzzzzzzzzzzszzzzzzzzzzzzzzzzzzzk3zzzzzzzzzzzzzzzzzzy0Tzzzzzzzzzzzzzzzzzzy3zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU"

isMatchFinished() {
    global starsSession, starsSessionText, gameEnded
    BetterClick(328, 186) ; closes unit upg menu
    if (ok := FindText(&X, &Y, 756 - 150000, 415 - 150000, 756 + 150000, 415 + 150000, 0, 0, NextButton) or (ok :=
        FindText(&X, &Y, 756 - 150000, 415 - 150000, 756 + 150000, 415 + 150000, 0, 0, XPProgress))) {
        AddToLog("game ended")
        gameEnded := true
        DetermineOutcome()
    }
}
