grammar Query;

@parser::header {
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalUnit;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import com.amshulman.insight.action.InsightAction;
import com.amshulman.insight.parser.InvalidTokenException.TokenType;
import com.amshulman.insight.query.QueryParameterBuilder;
import com.amshulman.insight.query.QueryParameters;
import com.amshulman.insight.types.EventRegistry;
import com.amshulman.insight.types.InsightMaterial;
import com.amshulman.insight.types.MaterialCompat;

import com.google.common.collect.ImmutableList;

import lombok.Getter;
import lombok.Setter;
import lombok.RequiredArgsConstructor;
}

@parser::members {
private static final String SINGLE_QUOTE = "\'";
private static final String DOUBLE_QUOTE = "\"";

@Getter @Setter public static Set<String> worlds = Collections.emptySet();

private final QueryParameterBuilder builder = new QueryParameterBuilder();
private final Set<String> usedParams = new HashSet<String>();

private final void checkParam(Token param) {
    checkParam(cleanString(param), param);
}

private final void checkParam(String name, Token param) {
    if (!usedParams.add(name)) {
        throw new UnexpectedTokenException(this, param);
    }
}

@RequiredArgsConstructor
private static class TemporalUnitWrapper {
    final char fieldName;
    final TemporalUnit temporalUnit;
}

private static final List<TemporalUnitWrapper> TEMPORAL_UNITS = ImmutableList.of(
    new TemporalUnitWrapper('y', ChronoUnit.YEARS),
    new TemporalUnitWrapper('w', ChronoUnit.WEEKS),
    new TemporalUnitWrapper('d', ChronoUnit.DAYS),
    new TemporalUnitWrapper('h', ChronoUnit.HOURS),
    new TemporalUnitWrapper('m', ChronoUnit.MINUTES));

private static LocalDateTime getOffsetDate(String duration) {
    LocalDateTime time = LocalDateTime.now();
    int location = -1;
    for (TemporalUnitWrapper wrapper : TEMPORAL_UNITS) {
	    int fieldLocation = duration.indexOf(wrapper.fieldName, location);
	    if (fieldLocation > -1) {
	        time = time.minus(Integer.parseInt(duration.substring(location + 1, fieldLocation)), wrapper.temporalUnit);
	        location = fieldLocation;
	    }
    }
    return time;
}

private static String cleanString(Token raw) {
    String cleaned = raw.getText().trim();
    if ((cleaned.startsWith(SINGLE_QUOTE) && cleaned.endsWith(SINGLE_QUOTE)) ||
        (cleaned.startsWith(DOUBLE_QUOTE) && cleaned.endsWith(DOUBLE_QUOTE))) {
        return cleaned.substring(1, cleaned.length() - 1);
    }
    return cleaned;
}
}

parse returns [QueryParameters queryParameters]: params+ EOF {$queryParameters = builder.build();};

params: actor | action | actee | material | radius | before | after | world | order;

actor: (inversion = INVERSION?)(keyword = ACTOR {checkParam($keyword);}) (a = STRING {builder.addActor(cleanString($a));})+ {if ($inversion.text != null) {builder.invertActors();}};

action: (inversion = INVERSION?)(keyword = ACTION {checkParam($keyword);}) (a = STRING {String actionName = cleanString($a); Collection<InsightAction> actions = EventRegistry.getActionsByAlias(actionName); if (actions.isEmpty()) {throw new InvalidTokenException(TokenType.ACTION, actionName);} for (InsightAction action : actions) {builder.addAction(action);}})+ {if ($inversion.text != null) {builder.invertActions();}};

actee: (inversion = INVERSION?)(keyword = ACTEE {checkParam($keyword);}) (a = STRING {builder.addActee(cleanString($a));})+ {if ($inversion.text != null) {builder.invertActees();}};

material: (inversion = INVERSION?)(keyword = MATERIAL {checkParam($keyword);}) (mat = STRING {String materialName = cleanString($mat).toUpperCase(); InsightMaterial mat = MaterialCompat.getWildcardMaterial(materialName); if (mat == null) { throw new InvalidTokenException(TokenType.MATERIAL, materialName);} builder.addMaterial(mat);})+ {if ($inversion.text != null) {builder.invertMaterials();}};

radius: (keyword = RADIUS {checkParam($keyword);}) (val = (NUMBER | STRING)) {String radiusString = $val.text.trim(); int radius = 0; if (radiusString.equalsIgnoreCase("worldedit")) {radius = QueryParameters.WORLDEDIT;} else {try {radius = Integer.parseInt(radiusString);} catch (NumberFormatException e) {throw new InvalidTokenException(TokenType.RADIUS, radiusString);} if(radius <= 0) {throw new InvalidTokenException(TokenType.RADIUS, radiusString);}} builder.setArea(null, radius);};

before: (keyword = BEFORE {checkParam($keyword);}) (duration = DURATION) {builder.setBefore(getOffsetDate($duration.text));};

after: (keyword = AFTER {checkParam($keyword);}) (duration = DURATION) {builder.setAfter(getOffsetDate($duration.text));};

world: (keyword = WORLD {checkParam($keyword);}) (w = STRING {String world = cleanString($w); if (!worlds.contains(world)) {throw new InvalidTokenException(TokenType.WORLD, world);} builder.addWorld(world);})+;

order: (keyword = (ASC | DESC) {checkParam("order", $keyword); builder.reverseOrder("asc".equalsIgnoreCase($keyword.text.trim()));});

INVERSION: '!';
ACTEE: 'actee ';
ACTION: 'action ';
ACTOR: 'actor ';
AFTER: 'after ';
BEFORE: 'before ';
MATERIAL: 'material ';
RADIUS: 'radius ';
WORLD: 'world ';
ASC: 'asc' SPACE?;
DESC: 'desc' SPACE?;

DURATION: (((BASE_NUMBER YEAR) (BASE_NUMBER WEEK)? (BASE_NUMBER DAY)? (BASE_NUMBER HOUR)? (BASE_NUMBER MINUTE)?) |
          ((BASE_NUMBER WEEK) (BASE_NUMBER DAY)? (BASE_NUMBER HOUR)? (BASE_NUMBER MINUTE)?) |
          ((BASE_NUMBER DAY) (BASE_NUMBER HOUR)? (BASE_NUMBER MINUTE)?) |
          ((BASE_NUMBER HOUR) (BASE_NUMBER MINUTE)?) |
          (BASE_NUMBER MINUTE)) SPACE?;

NUMBER: HYPHEN? BASE_NUMBER SPACE?;
fragment BASE_NUMBER: DIGIT+;

STRING: (SINGLE_QUOTED_STRING | DOUBLE_QUOTED_STRING | BASE_STRING) SPACE?;
fragment SINGLE_QUOTED_STRING: SINGLE_QUOTE BASE_STRING SINGLE_QUOTE;
fragment DOUBLE_QUOTED_STRING: DOUBLE_QUOTE BASE_STRING DOUBLE_QUOTE;
fragment BASE_STRING: (LOWER_CASE | UPPER_CASE | DIGIT | UNDERSCORE)+;

fragment YEAR: 'Y' | 'y';
fragment WEEK: 'W' | 'w';
fragment DAY: 'D' | 'd';
fragment HOUR: 'H' | 'h';
fragment MINUTE: 'M' | 'm';

fragment UPPER_CASE: 'A'..'Z';
fragment LOWER_CASE: 'a'..'z';
fragment DIGIT: '0'..'9';
fragment SINGLE_QUOTE: '\'';
fragment DOUBLE_QUOTE: '\"';
fragment SPACE: ' ';
fragment UNDERSCORE: '_';
fragment HYPHEN: '-';