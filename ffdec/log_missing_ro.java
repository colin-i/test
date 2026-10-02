import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.util.zip.*;

/**
 * Script to find NEW resources in English that don't exist in Romanian translation.
 * Reads ignored resources list and required JAR files from Translator.java source file.
 */
public class log_missing_ro {

    private static List<String> IGNORED_RESOURCES;

    private static List<String> loadIgnoredResources(String translatorPath) {
        List<String> ignored = new ArrayList<>();
        File translatorFile = new File(translatorPath);
        ignored.add("translator/Translator");

        if (!translatorFile.exists()) {
            System.err.println("Warning: Translator.java not found");
            return ignored;
        }

        try (BufferedReader reader = new BufferedReader(new FileReader(translatorFile))) {
            String line;
            boolean inIgnoredList = false;

            while ((line = reader.readLine()) != null) {
                if (line.contains("ignoredResources = Arrays.asList")) {
                    inIgnoredList = true;
                    continue;
                }

                if (inIgnoredList) {
                    if (line.trim().equals(");")) {
                        break;
                    }
                    // Extract quoted strings from line
                    int start = line.indexOf('"');
                    while (start >= 0) {
                        int end = line.indexOf('"', start + 1);
                        if (end < 0) break;
                        String resource = line.substring(start + 1, end);
                        if (!resource.isEmpty()) {
                            ignored.add(resource);
                        }
                        start = line.indexOf('"', end + 1);
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("Error reading Translator.java: " + e.getMessage());
            return ignored;
        }

        return ignored;
    }

    private static List<File> loadRequiredJars(String translatorPath) {
        List<File> jars = new ArrayList<>();
        File translatorFile = new File(translatorPath);
        if (!translatorFile.exists()) {
            System.err.println("Warning: Translator.java not found for reading JAR list: " + translatorPath);
            return jars;
        }

        // Find project root by searching upwards from Translator.java
        File projectDir = translatorFile.getAbsoluteFile().getParentFile();
        while (projectDir != null && !new File(projectDir, "build.xml").exists() && !new File(projectDir, "dist").exists()) {
            projectDir = projectDir.getParentFile();
        }
        if (projectDir == null) {
            projectDir = new File(".");
        }

        Pattern loadJarPattern = Pattern.compile("loadJarTry\\s*\\(\\s*\"([^\"]+)\"\\s*\\)");
        try (BufferedReader reader = new BufferedReader(new FileReader(translatorFile))) {
            String line;
            while ((line = reader.readLine()) != null) {
                Matcher m = loadJarPattern.matcher(line);
                if (m.find()) {
                    String relPath = m.group(1);
                    // Match Translator.loadJarTry logic: check dist/<path> first, then <path>
                    File file = new File(projectDir, "dist/" + relPath);
                    if (!file.exists()) {
                        file = new File(projectDir, relPath);
                    }
                    if (file.exists()) {
                        jars.add(file);
                    } else {
                        System.err.println("Warning: Required JAR not found: " + file.getPath());
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("Error reading JARs from Translator.java: " + e.getMessage());
        }

        return jars;
    }

    public static void main(String[] args) throws Exception {
        String translatorPath = args.length > 0
                ? args[0]
                : "/home/bc/ffdec/jpexs-decompiler-1/src/com/jpexs/decompiler/flash/gui/translator/Translator.java";

        IGNORED_RESOURCES = loadIgnoredResources(translatorPath);

        // Dynamically resolve required JAR files from Translator.java
        List<File> jarFiles = loadRequiredJars(translatorPath);
        Map<String, String> englishResources = new TreeMap<>(); // key=normalized path, value=full display name
        Pattern pat = Pattern.compile("(?<path>.+?)(_(?<locale>[^\\\\.]+))?\\.properties$");

        for (File jarFile : jarFiles) {
            if (!jarFile.exists()) continue;
            loadResourceNames(jarFile, englishResources, "en", false, pat);
        }

        // Load Romanian resources with full paths from translated.zip
        Map<String, String> romanianResources = new TreeMap<>(); // key=normalized path, value=full display name
        String translatedZip = "/home/bc/.config/FFDec/translated.zip";
        File zipFile = new File(translatedZip);
        if (zipFile.exists()) {
            loadResourceNames(zipFile, romanianResources, "Romanian [ro]", true, pat);
        } else {
            System.err.println("Warning: " + translatedZip + " not found");
        }

        // Find NEW resources (in English but NOT in Romanian)
        int i = 0;
        System.out.println("=== NEW Resources (in English but not in Romanian) ===");
        for (Map.Entry<String, String> enEntry : englishResources.entrySet()) {
            String normalizedPath = enEntry.getKey();
            if (romanianResources.containsKey(normalizedPath)) continue;

            String displayName = enEntry.getValue();
            if (isIgnored(normalizedPath)) continue;

            System.out.println(displayName);
            i++;
        }
        System.out.println("Total "+i);
    }

    private static void loadResourceNames(File file, Map<String, String> resourceMap,
                                         String targetLocale, boolean fromTranslatedZip, Pattern pat) throws Exception {
        try (FileInputStream fis = new FileInputStream(file);
             ZipInputStream zis = new ZipInputStream(fis)) {
            ZipEntry zipEntry;
            while ((zipEntry = zis.getNextEntry()) != null) {
                if (zipEntry.isDirectory()) continue;
                String name = zipEntry.getName();
                if (!name.endsWith(".properties")) continue;

                Matcher m = pat.matcher(name);
                if (!m.matches()) continue;

                String path = m.group("path");
                String locale = m.group("locale");
                if (locale == null) locale = "en";
                if (!locale.equals(targetLocale)) continue;

                // Create full display name
                String displayName;
                if (fromTranslatedZip) {
                    displayName = name; // Use full path from ZIP (already includes .properties)
                } else {
                    // For JAR files, use JAR path + resource path + extension
                    displayName = file.getName() + ": " + name;
                }

                // Create normalized path for comparison
                String normalizedPath = path;
                if (fromTranslatedZip) {
                    // Remove "lib/" prefix first if present
                    normalizedPath = normalizedPath.replaceFirst("^lib/", "");
                    // Then remove JAR filename prefix (e.g., "ffdec.jar/")
                    normalizedPath = normalizedPath.replaceFirst("^[^/]+?/", "");
                }

                if (isIgnored(normalizedPath)) continue;

                resourceMap.put(normalizedPath, displayName);
            }
        }
    }

    private static boolean isIgnored(String path) {
        for (String ignored : IGNORED_RESOURCES) {
            if (path.contains(ignored)) {
                return true;
            }
        }
        return false;
    }
}
