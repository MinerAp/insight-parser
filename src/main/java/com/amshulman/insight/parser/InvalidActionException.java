package com.amshulman.insight.parser;

public class InvalidActionException extends IllegalArgumentException {

    private static final long serialVersionUID = -7050061751276406569L;

    public InvalidActionException() {
        super();
    }

    public InvalidActionException(String s) {
        super(s);
    }

    public InvalidActionException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidActionException(Throwable cause) {
        super(cause);
    }
}
