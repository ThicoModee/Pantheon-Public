#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\vendor\JSON.ahk

class ProfileStore {
    static WriteJson(path, profile) {
        SplitPath(path, , &directory)
        DirCreate(directory)
        temp := path ".tmp"
        file := FileOpen(temp, "w", "UTF-8-RAW")
        if !file
            throw Error("Could not open the profile for writing.")
        try {
            text := JSON.stringify(profile)
            if file.Write(text) < StrLen(text)
                throw Error("The profile could not be fully written.")
        } finally file.Close()
        FileMove(temp, path, 1)
    }

    static Int(value, low, high, label) {
        if !(value is Integer) || value < low || value > high
            throw ValueError(label " must be a whole number from " low " to " high ".")
        return value
    }

}
