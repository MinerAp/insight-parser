package com.amshulman.insight.parser;

public class InvalidMaterialException extends IllegalArgumentException {

    private static final long serialVersionUID = -8784512771233981586L;

    public InvalidMaterialException() {
        super();
    }

    public InvalidMaterialException(String s) {
        super(s);
    }

    public InvalidMaterialException(String message, Throwable cause) {
        super(message, cause);
    }

    public InvalidMaterialException(Throwable cause) {
        super(cause);
    }
}
