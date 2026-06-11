package com.rental.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Logger;

/**
 * Đọc config.properties từ classpath một lần lúc khởi động.
 * Dùng: AppConfig.get("sepay.api_key")
 * KHÔNG hardcode bất kỳ giá trị bí mật nào trong code.
 */
public class AppConfig {
    private static final Logger log = Logger.getLogger(AppConfig.class.getName());
    private static final Properties props = new Properties();

    static {
        try (InputStream in = AppConfig.class.getClassLoader()
                .getResourceAsStream("config.properties")) {
            if (in == null) {
                log.severe("[AppConfig] KHÔNG TÌM THẤY config.properties! Tạo file tại src/main/resources/config.properties");
            } else {
                props.load(in);
                log.info("[AppConfig] Đã tải config.properties thành công.");
            }
        } catch (IOException e) {
            log.severe("[AppConfig] Lỗi đọc config.properties: " + e.getMessage());
        }
    }

    public static String get(String key) {
        String val = props.getProperty(key, "");
        if (val.isBlank()) log.warning("[AppConfig] Key '" + key + "' chưa được điền!");
        return val;
    }

    public static int getInt(String key, int def) {
        try { return Integer.parseInt(get(key)); } catch (NumberFormatException e) { return def; }
    }
}
