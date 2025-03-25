package myapp;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.nio.file.FileStore;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class DebugFunctions {
	public static List<String> getJvmInputArguments() {
		// MEMO DataWeaveのみで以下を試したが、上手くいかなかった。
		// java!java::lang::management::ManagementFactory::getRuntimeMXBean().getInputArguments() ==> null
		return ManagementFactory.getRuntimeMXBean().getInputArguments();
	}

	public static Map<String, Long> getFileStore(String path) throws IOException {
		FileStore fileStore = Files.getFileStore(Path.of(path));
		Map<String, Long> result = new LinkedHashMap<>();
		result.put("totalSpace", fileStore.getTotalSpace());
		result.put("usableSpace", fileStore.getUsableSpace());
		result.put("unallocatedSpace", fileStore.getUnallocatedSpace());
		return result;
	}
}
