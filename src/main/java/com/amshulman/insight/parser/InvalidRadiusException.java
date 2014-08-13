package com.amshulman.insight.parser;

public class InvalidRadiusException extends IllegalArgumentException {

    private static final long serialVersionUID = 2475955056493311236L;

    public InvalidRadiusException() {
        super();
    }

    public InvalidRadiusException(String s) {
        super(s);
    }

    public InvalidRadiusException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidRadiusException(Throwable cause) {
        super(cause);
    }
}
