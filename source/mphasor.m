function [A3,P3,dA3,dP3] = mphasor(A1,P1,A2,P2,dA1,dP1,dA2,dP2)

C1 = A1*cos(P1);
C2 = A2*cos(P2);
S1 = A1*sin(P1);
S2 = A2*sin(P2);


C1C2 = C1 + C2;
S1S2 = S1 + S2;

A3 = (C1C2^2+S1S2^2)^(1/2);
P3 = atan2(S1S2,C1C2);

if nargin > 4
    dC1 = (cos(P1)^2*dA1^2 + A1^2*sin(P1)^2*dP1^2)^(1/2);
    dC2 = (cos(P2)^2*dA2^2 + A2^2*sin(P2)^2*dP2^2)^(1/2);
    dS1 = (sin(P1)^2*dA1^2 + A1^2*cos(P1)^2*dP1^2)^(1/2);
    dS2 = (sin(P2)^2*dA2^2 + A2^2*cos(P2)^2*dP2^2)^(1/2);
    
    dC1C2 = (dC1^2 + dC2^2)^(1/2);
    dS1S2 = (dS1^2 + dS2^2)^(1/2);
    
    
    dA3 = 1/A3*(C1C2^2*dC1C2^2+S1S2^2*dS1S2^2)^(1/2);
    dP3 = 1/A3^2*(C1C2^2*dS1S2^2+S1S2^2*dC1C2^2)^(1/2);
end




end