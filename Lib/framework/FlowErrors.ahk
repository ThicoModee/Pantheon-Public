#Requires AutoHotkey v2.0

class FlowImageError extends Error {

}

class FlowStop extends Error {

}

class FlowLoopTimeout extends Error {

    __New(owner) {

        super.__New("Image loop timed out.")

        this.Owner := owner

    }

}
