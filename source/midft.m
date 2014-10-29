function y = midft(f,a,x)



aR = real(a);
aI = imag(a);
y = zeros(size(x));
pid = mprocessinit('\nPerforming IDFT...');

for iy = 1:length(y)
    
    
    y(iy) = 2/length(f)*sum(aR.*cos(2*pi*f*x(iy))+1i*aI.*sin(2*pi*f*x(iy)));
    
    
    
    
    
    
    mprocessupdate(pid,iy/length(y));
    
end
mprocessfinish(pid,1);










end