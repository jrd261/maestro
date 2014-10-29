function clk = mclk(r,rho,xi_r,xi_h,l)

% Not yet checked if working properly

clk = trapz(r,rho.*r.^2.*(2*xi_r.*xi_h+xi_h.^2))/trapz(r,rho.*r.^2.*(xi_r.^2 + l*(l+1).*xi_h.^2));

end

