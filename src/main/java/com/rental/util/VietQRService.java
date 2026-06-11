package com.rental.util;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.logging.Logger;

/**
 * Tạo QR chuyển khoản thật bằng VietQR public API (miễn phí, không cần key).
 *
 * URL: https://img.vietqr.io/image/{bin}-{accountNo}-compact2.png
 *       ?amount=XXX&addInfo=YYY&accountName=ZZZ
 *
 * Khi quét QR này, app ngân hàng TỰ ĐIỀN: số TK + số tiền + nội dung.
 * Khách chỉ cần bấm XÁC NHẬN trong app ngân hàng.
 */
public class VietQRService {
    private static final Logger log = Logger.getLogger(VietQRService.class.getName());
    private static final String BASE = "https://img.vietqr.io/image/";

    /** Tạo URL QR từ config.properties */
    public static String buildQRUrl(long amount, String addInfo) {
        return buildQRUrl(
            AppConfig.get("bank.bin"),
            AppConfig.get("bank.account_no"),
            AppConfig.get("bank.account_name"),
            amount, addInfo
        );
    }

    public static String buildQRUrl(String bin, String acNo, String acName,
                                     long amount, String addInfo) {
        try {
            String url = BASE + bin + "-" + acNo + "-compact2.png"
                + "?amount=" + amount
                + "&addInfo=" + URLEncoder.encode(addInfo, StandardCharsets.UTF_8)
                + "&accountName=" + URLEncoder.encode(acName, StandardCharsets.UTF_8);
            log.info("[VietQR] Generated for addInfo=" + addInfo + " amount=" + amount);
            return url;
        } catch (Exception e) {
            log.severe("[VietQR] Error: " + e.getMessage());
            return "";
        }
    }

    /**
     * Sinh mã tham chiếu duy nhất nhúng vào nội dung chuyển khoản.
     * Format: HD{contractId}T{6 số cuối timestamp}
     * Ví dụ: HD42T830921
     * SePay sẽ đọc mã này từ nội dung CK và gửi về webhook.
     */
    public static String generateTxRef(int contractId) {
        String ts = String.valueOf(System.currentTimeMillis());
        return "HD" + contractId + "T" + ts.substring(ts.length() - 6);
    }
}
