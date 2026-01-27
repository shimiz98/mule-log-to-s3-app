package io.github.shimiz98.y1grep;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class App implements Consumer<String[]> 
{
    public static void main( String[] args )
    {
        new App().accept(args);
    }

    public void accept(String[] args) {
        int i = 0;
        Pattern beginPattern = Pattern.compile(args[i++]);
        Pattern endPattern = Pattern.compile(args[i++]);
        Pattern contextPattern = Pattern.compile(args[i++]);
        GrepPattern grepPattern = new GrepPattern(beginPattern, endPattern, contextPattern);
        for (/**/; i < args.length; i++) {
            try (BufferedReader r = Files.newBufferedReader(Path.of(args[i]), StandardCharsets.UTF_8)) {
                grep(r, grepPattern);
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            }
        }
    }

    void grep(BufferedReader r, GrepPattern grepPattern) throws IOException {
        String line;
        Map<String, List<String>> outputMap = new LinkedHashMap<>();
        Map<String, Boolean> isMatchedMap = new HashMap<>();
        while ((line = r.readLine()) != null) {
            Matcher cm = grepPattern.contextPattern.matcher(line);
            String contextName = "";
            if (cm.matches()) {
                for (int x = 1; x <= cm.groupCount(); x++) {
                    if (cm.group(x) != null) {
                        contextName = contextName + cm.group(x);
                    }
                }
            }
            boolean matching = isMatchedMap.getOrDefault(contextName, false);
            if (!matching) {
                Matcher bm = grepPattern.beginPattern.matcher(line);
                if (bm.matches()) {
                    List<String> x = outputMap.get(contextName);
                    if (x == null) {
                        x = new ArrayList<>();
                        outputMap.put(contextName, x);
                    }
                    x.add(line);
                    isMatchedMap.put(contextName, true);
                }
            } else {
                Matcher em = grepPattern.endPattern.matcher(line);
                if (em.matches()) {
                    outputMap.get(contextName).add(line);
                    isMatchedMap.put(contextName, false);
                } else {
                    outputMap.get(contextName).add(line);
                }
            }
        }
        for (Map.Entry<String, List<String>> entry: outputMap.entrySet()) {
            for (String outputLine: entry.getValue()) {
                System.out.printf("%s#%s%n", entry.getKey(), outputLine);
            }
        }
        return;
    }

    record GrepPattern(Pattern beginPattern, Pattern endPattern, Pattern contextPattern) {};
}
