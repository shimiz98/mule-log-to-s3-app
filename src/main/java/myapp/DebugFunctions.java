package myapp;

import java.lang.management.ManagementFactory;
import java.util.List;

public class DebugFunctions {
	public static List<String> getJvmInputArguments() {
		// MEMO DataWeaveのみで以下を試したが、上手くいかなかった。
		// java!java::lang::management::ManagementFactory::getRuntimeMXBean().getInputArguments() ==> null
		return ManagementFactory.getRuntimeMXBean().getInputArguments();
	}
}
