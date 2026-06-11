package com.rental.etl.dimension;

import com.rental.etl.core.ETLContext;
import com.rental.etl.core.ETLJob;

import java.sql.*;
import java.time.*;
import java.time.format.TextStyle;
import java.util.*;

/**
 * DimTimeLoader: Khởi tạo bảng dim_time cho 10 năm (2020–2030).
 * Chạy 1 lần (one-time), idempotent nhờ INSERT IGNORE.
 */
public class DimTimeLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.dim_time (" +
        "  date_key     INT         PRIMARY KEY COMMENT 'YYYYMMDD'," +
        "  full_date    DATE        NOT NULL UNIQUE," +
        "  day_of_week  TINYINT     NOT NULL COMMENT '1=Mon..7=Sun'," +
        "  day_name     VARCHAR(15) NOT NULL," +
        "  week_of_year TINYINT     NOT NULL," +
        "  month_num    TINYINT     NOT NULL," +
        "  month_name   VARCHAR(15) NOT NULL," +
        "  quarter      TINYINT     NOT NULL," +
        "  year_num     SMALLINT    NOT NULL," +
        "  is_weekend   BOOLEAN     DEFAULT FALSE," +
        "  is_holiday   BOOLEAN     DEFAULT FALSE" +
        ") ENGINE=InnoDB";

    private static final String INSERT_SQL =
        "INSERT IGNORE INTO cc_dwh.dim_time " +
        "(date_key,full_date,day_of_week,day_name,week_of_year,month_num,month_name,quarter,year_num,is_weekend,is_holiday) " +
        "VALUES (?,?,?,?,?,?,?,?,?,?,?)";

    private static final Map<String, Boolean> VN_HOLIDAYS = buildHolidays();
    private static final Locale VI_LOCALE = Locale.of("vi");

    private final ETLContext ctx;
    private int rowsProcessed = 0;

    public DimTimeLoader(ETLContext ctx) { this.ctx = ctx; }

    @Override public String getJobName() { return "DimTimeLoader"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
    }

    @Override public void transform() { /* inline trong load */ }

    @Override
    public void load() throws Exception {
        Connection dwh = ctx.getDwhConn();
        // Bỏ qua nếu đã đầy dữ liệu
        try (ResultSet rs = dwh.createStatement().executeQuery("SELECT COUNT(*) FROM cc_dwh.dim_time")) {
            rs.next();
            if (rs.getInt(1) >= 3650) { // ~10 năm
                System.out.println("[DimTimeLoader] Bảng dim_time đã đầy, bỏ qua.");
                return;
            }
        }

        try (PreparedStatement ps = dwh.prepareStatement(INSERT_SQL)) {
            LocalDate start = LocalDate.of(2020, 1, 1);
            LocalDate end   = LocalDate.of(2030, 12, 31);
            dwh.setAutoCommit(false);
            int batch = 0;
            for (LocalDate d = start; !d.isAfter(end); d = d.plusDays(1)) {
                int dateKey = d.getYear() * 10000 + d.getMonthValue() * 100 + d.getDayOfMonth();
                int dow = d.getDayOfWeek().getValue(); // 1=Mon..7=Sun
                String dayName = d.getDayOfWeek().getDisplayName(TextStyle.FULL, VI_LOCALE);
                int week = d.get(java.time.temporal.WeekFields.ISO.weekOfWeekBasedYear());
                String monthName = d.getMonth().getDisplayName(TextStyle.FULL, VI_LOCALE);
                int quarter = (d.getMonthValue() - 1) / 3 + 1;
                boolean isWeekend = dow >= 6;
                boolean isHoliday = VN_HOLIDAYS.containsKey(
                    String.format("%02d-%02d", d.getMonthValue(), d.getDayOfMonth()));

                ps.setInt(1, dateKey);
                ps.setDate(2, java.sql.Date.valueOf(d)); 
                ps.setInt(3, dow);
                ps.setString(4, dayName);
                ps.setInt(5, week);
                ps.setInt(6, d.getMonthValue());
                ps.setString(7, monthName);
                ps.setInt(8, quarter);
                ps.setInt(9, d.getYear());
                ps.setBoolean(10, isWeekend);
                ps.setBoolean(11, isHoliday);
                ps.addBatch();
                batch++;
                if (batch % 500 == 0) { ps.executeBatch(); dwh.commit(); }
            }
            ps.executeBatch();
            dwh.commit();
            dwh.setAutoCommit(true);
            rowsProcessed = batch;
        }
    }

    private static Map<String, Boolean> buildHolidays() {
        Map<String, Boolean> h = new HashMap<>();
        // Ngày lễ Việt Nam cố định (MM-dd)
        h.put("01-01", true); // Tết Dương lịch
        h.put("04-30", true); // Ngày Giải phóng
        h.put("05-01", true); // Quốc tế Lao động
        h.put("09-02", true); // Quốc khánh
        // Giỗ Tổ Hùng Vương (10/3 ÂL) - xấp xỉ 04-18
        h.put("04-18", true);
        return h;
    }
}
