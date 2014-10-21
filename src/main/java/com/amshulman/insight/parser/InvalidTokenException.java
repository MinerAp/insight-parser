package com.amshulman.insight.parser;

import lombok.Getter;

@SuppressWarnings("serial")
public class InvalidTokenException extends IllegalArgumentException {

    @Getter private final TokenType type;

    public InvalidTokenException(TokenType type, String s) {
        super(s);
        this.type = type;
    }

    public enum TokenType {
        ACTION, MATERIAL, RADIUS, WORLD
    }
}
