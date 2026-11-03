#Requires AutoHotkey v2.0

class PantheonVersion {
    static Current := "1.0-beta.1"
    static Parts(value) {
        if !(value is String) || StrLen(value) > 80 || !RegExMatch(value, "^(0|[1-9]\d*)\.(0|[1-9]\d*)(?:\.(0|[1-9]\d*))?(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$", &match)
            throw ValueError("Invalid Pantheon version requirement.")
        pre := match[4] == "" ? [] : StrSplit(match[4], ".")
        for part in pre
            if RegExMatch(part, "^0[0-9]+$")
                throw ValueError("Invalid Pantheon prerelease version.")
        return [Integer(match[1]), Integer(match[2]), match[3] == "" ? 0 : Integer(match[3]), pre]
    }
    static Compare(left, right) {
        a := this.Parts(left), b := this.Parts(right)
        loop 3
            if a[A_Index] != b[A_Index]
                return a[A_Index] > b[A_Index] ? 1 : -1
        a := a[4], b := b[4]
        if !a.Length || !b.Length
            return a.Length == b.Length ? 0 : !a.Length ? 1 : -1
        loop Min(a.Length, b.Length) {
            x := a[A_Index], y := b[A_Index]
            if x == y
                continue
            xn := RegExMatch(x, "^\d+$"), yn := RegExMatch(y, "^\d+$")
            if xn && yn
                return Integer(x) > Integer(y) ? 1 : -1
            if xn != yn
                return xn ? -1 : 1
            return StrCompare(x, y, true) > 0 ? 1 : -1
        }
        return a.Length == b.Length ? 0 : a.Length > b.Length ? 1 : -1
    }
    static Require(value) {
        if this.Compare(this.Current, value) < 0
            throw ValueError("This macro requires Pantheon " value " or newer. Installed version: " this.Current ".")
    }
}
