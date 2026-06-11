package com.rental.servlet;

import com.rental.dao.*;
import com.rental.model.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

public class ProfileServlet extends HttpServlet {
    private final ContractDAO contractDAO = new ContractDAO();
    private final ApartmentDAO apartmentDAO = new ApartmentDAO();
    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("loggedUser");
        loadProfileData(req, user);
        req.getRequestDispatcher("/WEB-INF/views/user/profile.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        User user = (User) req.getSession().getAttribute("loggedUser");
        String action = req.getParameter("action");
        if ("updateProfile".equals(action)) {
            user.setFullName(req.getParameter("fullName"));
            user.setPhone(req.getParameter("phone"));
            user.setCccd(req.getParameter("cccd"));
            if (userDAO.updateProfile(user)) {
                // Update session
                req.getSession().setAttribute("loggedUser", userDAO.findById(user.getUserId()));
                resp.sendRedirect(req.getContextPath() + "/user/profile?success=updated");
            } else {
                req.setAttribute("error", "Cập nhật thất bại.");
                loadProfileData(req, user);
                req.getRequestDispatcher("/WEB-INF/views/user/profile.jsp").forward(req, resp);
            }
        }
    }

    private void loadProfileData(HttpServletRequest req, User user) {
        List<Contract> rentedContracts = contractDAO.getByTenantId(user.getUserId());
        List<Apartment> myApartments = apartmentDAO.getByOwnerId(user.getUserId());
        List<Contract> landlordContracts = contractDAO.getByOwnerId(user.getUserId());
        req.setAttribute("rentedContracts", rentedContracts);
        req.setAttribute("myApartments", myApartments);
        req.setAttribute("landlordContracts", landlordContracts);
    }
}
