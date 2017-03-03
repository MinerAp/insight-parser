package com.amshulman.insight.parser;

import org.antlr.v4.runtime.InputMismatchException;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.Token;

@SuppressWarnings("serial")
public class UnexpectedTokenException extends InputMismatchException {

    public UnexpectedTokenException(Parser recognizer, Token token) {
        super(recognizer);
        setOffendingToken(token);
    }
}
