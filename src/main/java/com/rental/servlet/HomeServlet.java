package com.rental.servlet;

import com.rental.dao.ApartmentDAO;
import com.rental.model.Apartment;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

public class HomeServlet extends HttpServlet {
    private final ApartmentDAO apartmentDAO = new ApartmentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        List<Apartment> featured = apartmentDAO.getFeatured(6);
        req.setAttribute("apartments", featured);
        req.setAttribute("featuredApartments", featured);
        req.setAttribute("totalApartments", apartmentDAO.countByStatus("approved"));
        req.getRequestDispatcher("/WEB-INF/views/home.jsp").forward(req, resp);
    }
}
