import java.io.File;
import java.io.FileInputStream;
import java.security.Security;
import java.util.Properties;

public class TestSecurityProperties {
    // JDK 11
    private static final String JDK_PROPS_FILE_JDK_11 = System.getProperty("java.home") + "/conf/security/java.security";
    // JDK 8
    private static final String JDK_PROPS_FILE_JDK_8 = System.getProperty("java.home") + "/lib/security/java.security";

    public static void main(String[] args) {
        Properties jdkProps = new Properties();
        loadProperties(jdkProps);
        for (Object key: jdkProps.keySet()) {
            String sKey = (String)key;
            String securityVal = Security.getProperty(sKey);
            String jdkSecVal = jdkProps.getProperty(sKey);
            if (!securityVal.equals(jdkSecVal)) {
                String msg = "Expected value '" + jdkSecVal + "' for key '" + 
                             sKey + "'" + " but got value '" + securityVal + "'";
                throw new RuntimeException("Test failed! " + msg);
            } else {
                System.out.println("DEBUG: " + sKey + " = " + jdkSecVal + " as expected.");
            }
        }
        System.out.println("TestSecurityProperties PASSED!");
    }
    
    private static void loadProperties(Properties props) {
        String javaVersion = System.getProperty("java.version");
        System.out.println("Debug: Java version is " + javaVersion);
        String propsFile = JDK_PROPS_FILE_JDK_11;
        if (javaVersion.startsWith("1.8.0")) {
            propsFile = JDK_PROPS_FILE_JDK_8;
        }
        try (FileInputStream fin = new FileInputStream(new File(propsFile))) {
            props.load(fin);
        } catch (Exception e) {
            throw new RuntimeException("Test failed!", e);
        }
    }
}
