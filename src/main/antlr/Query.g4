grammar Query;

@parser::header {
import java.util.Calendar;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.HashSet;
import java.util.Set;

import com.amshulman.insight.action.InsightAction;
import com.amshulman.insight.parser.InvalidTokenException.TokenType;
import com.amshulman.insight.query.QueryParameterBuilder;
import com.amshulman.insight.query.QueryParameters;
import com.amshulman.insight.types.EventCompat;
import com.amshulman.insight.types.InsightMaterial;
import com.amshulman.insight.types.MaterialCompat;

import lombok.Getter;
import lombok.Setter;
}

@parser::members {
private static final String SINGLE_QUOTE = "\'";
private static final String DOUBLE_QUOTE = "\"";

@Getter @Setter public static Set<String> worlds = Collections.emptySet();

private final QueryParameterBuilder builder = new QueryParameterBuilder();
private final Set<String> usedParams = new HashSet<String>();

private final void checkParam(Token param) {
    if (!usedParams.add(cleanString(param).toUpperCase())) {
        throw new UnexpectedTokenException(this, param);
    }
}

private static Date getOffsetDate(String duration) {
    Calendar c = Calendar.getInstance();
    int location = -1;

    location = subtractFieldIfExists(c, duration, location, 'y', Calendar.YEAR);
    location = subtractFieldIfExists(c, duration, location, 'w', Calendar.WEEK_OF_YEAR);
    location = subtractFieldIfExists(c, duration, location, 'd', Calendar.DAY_OF_YEAR);
    location = subtractFieldIfExists(c, duration, location, 'h', Calendar.HOUR_OF_DAY);
    location = subtractFieldIfExists(c, duration, location, 'm', Calendar.MINUTE);

    return c.getTime();
}

private static int subtractFieldIfExists(Calendar c, String duration, int previousFieldLocation, char fieldName, int field) {
    int fieldLocation = duration.indexOf(fieldName, previousFieldLocation);
    if (fieldLocation > -1) {
        c.add(field, -Integer.parseInt(duration.substring(previousFieldLocation + 1, fieldLocation)));
        return fieldLocation;
    }

    return previousFieldLocation;
}

private static String cleanString(Token raw) {
    String cleaned = raw.getText().trim();
    
    if((cleaned.startsWith(SINGLE_QUOTE) && cleaned.endsWith(SINGLE_QUOTE)) || (cleaned.startsWith(DOUBLE_QUOTE) && cleaned.endsWith(DOUBLE_QUOTE))) {
        return cleaned.substring(1, cleaned.length() - 1);
    }
    
    return cleaned;
}
}

parse returns [QueryParameters queryParameters]: params+ EOF {$queryParameters = builder.build();};

params: actor | action | actee | material | radius | before | after | world;

actor: (inversion = INVERSION?)(keyword = ACTOR {checkParam($keyword);}) (a = STRING {builder.addActor(cleanString($a));})+ {if ($inversion.text != null) {builder.invertActors();}};

action: (inversion = INVERSION?)(keyword = ACTION {checkParam($keyword);}) (a = STRING {String actionName = cleanString($a); Collection<InsightAction> actions = EventCompat.getQueryActions(actionName); if (actions.isEmpty()) {throw new InvalidTokenException(TokenType.ACTION, actionName);} for (InsightAction action : actions) {builder.addAction(action);}})+ {if ($inversion.text != null) {builder.invertActions();}};

actee: (inversion = INVERSION?)(keyword = ACTEE {checkParam($keyword);}) (a = STRING {builder.addActee(cleanString($a));})+ {if ($inversion.text != null) {builder.invertActees();}};

material: (inversion = INVERSION?)(keyword = MATERIAL {checkParam($keyword);}) (mat = STRING {String materialName = cleanString($mat).toUpperCase(); InsightMaterial mat = MaterialCompat.getWildcardMaterial(materialName); if (mat == null) { throw new InvalidTokenException(TokenType.MATERIAL, materialName);} builder.addMaterial(mat);})+ {if ($inversion.text != null) {builder.invertMaterials();}};

radius: (keyword = RADIUS {checkParam($keyword);}) (val = (NUMBER | STRING)) {String radiusString = $val.text.trim(); int radius = 0; if (radiusString.equalsIgnoreCase("worldedit")) {radius = QueryParameters.WORLDEDIT;} else {try {radius = Integer.parseInt(radiusString);} catch (NumberFormatException e) {throw new InvalidTokenException(TokenType.RADIUS, radiusString);} if(radius <= 0) {throw new InvalidTokenException(TokenType.RADIUS, radiusString);}} builder.setArea(null, radius);};

before: (keyword = BEFORE {checkParam($keyword);}) (duration = DURATION) {builder.setBefore(getOffsetDate($duration.text));};

after: (keyword = AFTER {checkParam($keyword);}) (duration = DURATION) {builder.setAfter(getOffsetDate($duration.text));};

world: (keyword = WORLD {checkParam($keyword);}) (w = STRING {String world = cleanString($w); if (!worlds.contains(world)) {throw new InvalidTokenException(TokenType.WORLD, world);} builder.addWorld(world);})+;

INVERSION: '!';
ACTEE: 'actee ';
ACTION: 'action ';
ACTOR: 'actor ';
AFTER: 'after ';
BEFORE: 'before ';
MATERIAL: 'material ';
RADIUS: 'radius ';
WORLD: 'world ';

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