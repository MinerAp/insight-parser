package com.amshulman.insight.parser;

import org.antlr.v4.runtime.InputMismatchException;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.misc.NotNull;

@SuppressWarnings("serial")
public class UnexpectedTokenException extends InputMismatchException {

    public UnexpectedTokenException(@NotNull Parser recognizer, @NotNull Token token) {
        super(recognizer);
        setOffendingToken(token);
    }
}
