package com.rental.servlet.admin;

import com.rental.dao.*;
import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;

public class AdminExportServlet extends HttpServlet {

    private final UserDAO      userDAO      = new UserDAO();
    private final ApartmentDAO apartmentDAO = new ApartmentDAO();
    private final ContractDAO  contractDAO  = new ContractDAO();
    private final PaymentDAO   paymentDAO   = new PaymentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        User user = (User) req.getSession().getAttribute("loggedUser");
        if (user == null || !"admin".equals(user.getRole())) {
            resp.sendError(403); return;
        }

        String fromDate = req.getParameter("fromDate");
        String toDate   = req.getParameter("toDate");
        if (fromDate == null || fromDate.isEmpty())
            fromDate = LocalDate.now().minusMonths(11).withDayOfMonth(1).toString();
        if (toDate == null || toDate.isEmpty())
            toDate = LocalDate.now().toString();

        req.setAttribute("fromDate",           fromDate);
        req.setAttribute("toDate",             toDate);
        req.setAttribute("generatedAt",        new java.util.Date());
        req.setAttribute("adminName",          user.getFullName());
        req.setAttribute("totalUsers",         userDAO.countAll());
        req.setAttribute("totalApartments",    apartmentDAO.countAll());
        req.setAttribute("approvedApartments", apartmentDAO.countByStatus("approved"));
        req.setAttribute("pendingApartments",  apartmentDAO.countByStatus("pending"));
        req.setAttribute("totalContracts",     contractDAO.countAll());
        req.setAttribute("activeContracts",    contractDAO.countActive());
        req.setAttribute("totalRevenue",       paymentDAO.getTotalRevenue());
        req.setAttribute("periodRevenue",      paymentDAO.getRevenueByPeriod(fromDate, toDate));
        req.setAttribute("avgDaysToRent",      contractDAO.getAvgDaysToRent());

        req.setAttribute("contractsByType",    contractDAO.getContractsByType());
        req.setAttribute("contractsByStatus",  contractDAO.getContractsByStatus());
        req.setAttribute("aptByCity",          apartmentDAO.getApartmentsByCity());
        req.setAttribute("aptByType",          apartmentDAO.getApartmentsByType());
        req.setAttribute("priceDistribution",  apartmentDAO.getPriceDistribution());
        req.setAttribute("topApartments",      contractDAO.getTopApartments(10));
        req.setAttribute("revenueByMonth",     contractDAO.getRevenueByMonth());
        req.setAttribute("contractsByMonth",   contractDAO.getContractsByMonth());
        req.setAttribute("usersByMonth",       userDAO.getNewUsersByMonth());

        req.getRequestDispatcher("/WEB-INF/views/admin/report-print.jsp")
           .forward(req, resp);
    }
}
