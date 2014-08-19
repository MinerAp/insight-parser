package com.amshulman.insight.parser;

import lombok.Getter;

public class InvalidTokenException extends IllegalArgumentException {

    private static final long serialVersionUID = 2475955056493311236L;

    @Getter private final TokenType type;

    public InvalidTokenException(TokenType type, String s) {
        super(s);
        this.type = type;
    }

    public enum TokenType {
        ACTION, MATERIAL, RADIUS, WORLD
    }
}
