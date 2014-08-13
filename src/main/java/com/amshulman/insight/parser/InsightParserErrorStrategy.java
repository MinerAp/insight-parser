package com.amshulman.insight.parser;

import org.antlr.v4.runtime.DefaultErrorStrategy;
import org.antlr.v4.runtime.Parser;
import org.antlr.v4.runtime.RecognitionException;

public class InsightParserErrorStrategy extends DefaultErrorStrategy {

    @Override
    public void reportError(Parser recognizer, RecognitionException e) throws RecognitionException {
        throw e;
    }
}
