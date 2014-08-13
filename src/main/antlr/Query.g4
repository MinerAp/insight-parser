grammar Query;

@parser::header {
import com.amshulman.insight.action.InsightAction;
import com.amshulman.insight.query.QueryParameterBuilder;
import com.amshulman.insight.query.QueryParameters;
import com.amshulman.insight.types.EventCompat;
import com.amshulman.insight.types.InsightMaterial;
import com.amshulman.insight.types.MaterialCompat;

import java.util.Calendar;
import java.util.Collection;
import java.util.Date;

import org.bukkit.Location;
import org.bukkit.Material;
}

@parser::members {
private static final String SINGLE_QUOTE = "\'";
private static final String DOUBLE_QUOTE = "\"";

private final QueryParameterBuilder builder = new QueryParameterBuilder();

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

private static String cleanString(String raw) {
    String cleaned = raw.trim();
    
    if((cleaned.startsWith(SINGLE_QUOTE) && cleaned.endsWith(SINGLE_QUOTE)) || (cleaned.startsWith(DOUBLE_QUOTE) && cleaned.endsWith(DOUBLE_QUOTE))) {
        return cleaned.substring(1, cleaned.length() - 1);
    }
    
    return cleaned;
}
}

parse returns [QueryParameters queryParameters]: params+ EOF {$queryParameters = builder.build();};

params: actor | action | actee | material | radius | before | after | world;

actor: (inversion = INVERSION?)ACTOR (a = STRING {builder.addActor(cleanString($a.text));})+ {if ($inversion.text != null) {builder.invertActors();}};

action: (inversion = INVERSION?)ACTION (a = STRING {String actionName = cleanString($a.text); Collection<InsightAction> actions = EventCompat.getQueryActions(actionName); if (actions == null) {throw new InvalidActionException(actionName);} for (InsightAction action : actions) {builder.addAction(action);}})+ {if ($inversion.text != null) {builder.invertActions();}};

actee: (inversion = INVERSION?)ACTEE (a = STRING {builder.addActee(cleanString($a.text));})+ {if ($inversion.text != null) {builder.invertActees();}};

material: (inversion = INVERSION?)MATERIAL (mat = STRING {String materialName = cleanString($mat.text).toUpperCase(); InsightMaterial mat = MaterialCompat.getWildcardMaterial(materialName); if (mat == null) { throw new InvalidMaterialException(materialName);} builder.addMaterial(mat);})+ {if ($inversion.text != null) {builder.invertMaterials();}};

radius: RADIUS (val = NUMBER) {int radius = Integer.parseInt($val.text.trim()); if(radius <= 0) {throw new InvalidRadiusException(Integer.toString(radius));} builder.setArea(null, radius);};

before: BEFORE (duration=DURATION) {builder.setBefore(getOffsetDate($duration.text));};

after: AFTER (duration=DURATION) {builder.setAfter(getOffsetDate($duration.text));};

world: WORLD (w = STRING {builder.addWorld(cleanString($w.text));})+;

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