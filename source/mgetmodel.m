function model = mgetmodel(name)

model.evaluate = @(x,a) [];
model.jacobian = @(x,a) [];
model.basis = @(x,a) [];
model.translate = @(a,da,o) deal(a,da);
model.guess = @(x,y,dy,a) a;
model.islinear = false;
switch name                       
    case {'sinusoid'}        
        model.evaluate = @sinusoid_evaluate;
        model.jacobian = @sinusoid_jacobian;                     
        model.guess = @sinusoid_guess;        
    case {'polynomial'}      
        model.islinear = true;
        model.evaluate = @polynomial_evaluate;              
        model.basis = @polynomial_basis; 
    case {'sinusoid_plus_parabola'}                
        model.evaluate = @sinpar_evaluate;
        model.jacobian = @sinpar_jacobian;
        model.guess = @sinpar_guess;
    case {'linsinpar'}
        model.islinear = true;
        model.evaluate = @linsinpar_evaluate;
        model.basis = @linsinpar_basis;
        model.translate = @linsinpar_translate;
   case {'linear_sinusoid'}
       model.islinear = true;
       model.evaluate = @sinusoid_evaluate;
       model.basis = @sinusoid_basis;
       model.translate = @sinusoid_translate;       
    case {'sinusoid_plus_parabola_special'}
        model.evaluate = @sinparspecial_evaluate;
        model.jacobian = @sinparspecial_jacobian;
        model.guess = @sinparspecial_guess;        
    case {'sinusoid_plus_linear'}
        model.evaluate = @sinpluslin_evaluate;
        model.jacobian = @sinpluslin_jacobian;
        model.guess = @sinpluslin_guess;        
    case {'linsinlin'}
      model.islinear = true;
        model.evaluate = @linsinlin_evaluate;
        model.basis = @linsinlin_basis;
        model.translate = @linsinlin_translate;

	 
    otherwise
        
        error('No function found by that name');          
end

end


%% LINEAR SInPAR
function out = linsinpar_evaluate(x,a)

out = a(1) + a(2)*x + a(3)*x.^2 + a(4)*sin(2*pi*a(5)*(x-a(6)));

end
function  out = linsinpar_basis(x,a)
    f = a;
    out = zeros(size(x,1),5);
    out(:,1) = ones(length(x),1);
    out(:,2) = x;
    out(:,3) = x.^2;
    out(:,4) = sin(2*pi*f*x);
    out(:,5) = -cos(2*pi*f*x);        
end
function [p,e] = linsinpar_translate(a,da,f)
    p(1) = a(1);
    p(2) = a(2);
    p(3) = a(3);
    p(4) = (a(4).^2+a(5).^2).^(1/2);
    p(5) = f;
    p(6) = atan2(a(5),a(4))/2/pi/f;
    
    e(1) = da(1);
    e(2) = da(2);
    e(3) = da(3);
    e(4) = 1/p(4)*(a(5)^2*da(4)^2+a(4)^2*da(5)^2)^(1/2);                
    e(5) = 0;
    e(6) = 1./p(4)^2*(a(5)^2*da(4)^2+a(4)^2*da(5)^2)^(1/2)/2/pi/f;

end

function out = linsinlin_evaluate(x,a)

out = a(1) + a(2)*x + a(3)*sin(2*pi*a(4)*(x-a(5)));

end
function  out = linsinlin_basis(x,a)
    f = a;
    out = zeros(size(x,1),4);
    out(:,1) = ones(length(x),1);
    out(:,2) = x;
    out(:,3) = sin(2*pi*f*x);
    out(:,4) = -cos(2*pi*f*x);        
end
function [p,e] = linsinlin_translate(a,da,f)
    p(1) = a(1);
    p(2) = a(2);
    p(3) = (a(3).^2+a(4).^2).^(1/2);
    p(4) = f;
    p(5) = atan2(a(4),a(3))/2/pi/f;
    
    e(1) = da(1);
    e(2) = da(2);
    e(3) = 1/p(3)*(a(4)^2*da(3)^2+a(3)^2*da(4)^2)^(1/2);                
    e(4) = 0;
    e(5) = 1./p(3)^2*(a(4)^2*da(3)^2+a(3)^2*da(4)^2)^(1/2)/2/pi/f;

end



%% SINUSOID (linear)
function out = sinusoid_basis(x,a)
    f = a;
    out = zeros(size(x,1),length(f)*2);      
    for i=1:length(f)
        out(:,2*i-1) = sin(2*pi*f(i)*x);
        out(:,2*i) = -cos(2*pi*f(i)*x);
    end
end
function [p,e] = sinusoid_translate(a,da,f) % a is solution from inverting basis, o is original or additional info
    p = zeros(length(a)*3/2,1);
    e = zeros(length(a)*3/2,1);
    k = 1;
    for i=1:3:size(p,1)
        j = 1+(i-1)*2/3;        
        p(i) = (a(j+1).^2+a(j).^2).^(1/2);
        e(i) = 1/p(i)*(a(j+1)^2*da(j+1)^2+a(j)^2*da(j)^2)^(1/2);                
        p(i+1) = f(k);
        e(i+1) = 0;
        p(i+2) = atan2(a(j+1),a(j))/2/pi/f(k);
        e(i+2) = 1./p(i)^2*(a(j+1)^2*da(j)^2+a(j)^2*da(j+1)^2)^(1/2)/2/pi/f(k);
        k =k + 1;
    end
end

%% SINUSOID (nonlinear)
function out = sinusoid_evaluate(x,a)

out = zeros(size(x,1),1);
for i = 1:3:length(a)
    out = out + a(i)*sin(2*pi*a(i+1)*(x-a(i+2)));    
end

end
function out = sinusoid_jacobian(x,a)
x = x(:);
out = zeros(size(x,1),length(a));
for i=1:3:length(a)
    out(:,i) = sin(2*pi*a(i+1)*(x-a(i+2)));
    out(:,i+1) = a(i)*cos(2*pi*a(i+1)*(x-a(i+2)))*2*pi.*(x-a(i+2));
    out(:,i+2) = -a(i)*cos(2*pi*a(i+1)*(x-a(i+2)))*2*pi*a(i+1);
end


end
function out = sinusoid_guess(x,y,dy,a)
    if isempty(a)
         [F,A] = mfastperiodogram(x,y);
         [junk,i] = max(A); %#ok<ASGLU>
         a = F(i);
    end
    model = mgetmodel('linear_sinusoid');
    [p,e] = mllsqr(model.basis(x,a),y,dy);        
    out = model.translate(p,e,a);    
end



%% POLYNOMIAL
function out = polynomial_evaluate(x,a)
    out = zeros(size(x));
    p = ones(size(x));
    for i=1:length(a)
        out = out + p*a(i);
        p = p.*x;
    end
end
function out = polynomial_basis(x,a)
    out = zeros(size(x,1),length(a));
    for i=1:size(out,2)
        out(:,i) = x.^(i-1);
    end
end

%% SINUSOID + PARABOLA (just one sin and one parabola)
function out = sinpar_evaluate(x,a)
    out = a(1)+a(2)*x+a(3)*x.^2+a(4)*sin(2*pi*a(5)*(x-a(6)));
end
function out = sinpar_jacobian(x,a)
x = x(:);
out = zeros(size(x,1),length(a));
out(:,1) = ones(size(x));
out(:,2) = x;
out(:,3) = x.^2;
out(:,4) = sin(2*pi*a(5)*(x-a(6)));
out(:,5) = a(4)*2*pi.*(x-a(6)).*cos(2*pi*a(5)*(x-a(6)));
out(:,6) = -a(4)*2*pi*a(5)*cos(2*pi*a(5)*(x-a(6)));

end
function out = sinpar_guess(x,y,dy,a)

    
    
    par = polyfit(x,y,1);  
    y = y - polyval(par,x);           
    
        
    linsinmodel = mgetmodel('linear_sinusoid');
    [P,E] = mllsqr(linsinmodel.basis(x,a),y,dy);    
    P = linsinmodel.translate(P,E,a);   
    y = y - linsinmodel.evaluate(x,P);
             
    out(4) = P(1);
    out(5) = P(2);
    out(6) = P(3);
    polymodel = mgetmodel('polynomial');
    P = mllsqr(polymodel.basis(x,[0,0,0]),y,dy);        
    out(1) = P(1);
    out(2) = P(2);
    out(3) = P(3);
   
   
    out = out';
    

end

%% SINUSOID + PARABOLA SPECIAL
function out = sinparspecial_evaluate(x,a)

    N = size(x,2);    
    out = zeros(size(x));
    for i=1:N
        j = 2+(4*i-3);
        X = x(:,i);
        out(:,i) = a(j)+a(j+1)*X+a(j+2)*X.^2+a(j+3)*sin(2*pi*a(1)*(X-a(2)));        
    end

    %a(1) = f
    %a(2) = t0
    
    %a(3) = a0
    %a(4) = a1
    %a(5) = a2
    %a(6) = A   
end
function out = sinparspecial_jacobian(x,a)
N = size(x,2);
n = size(x,1);
out = zeros(size(x(:),1),N*4+2);
for i = 1:N
    j = 2+(4*i-3);
    out((i-1)*n+1:i*n,1) = a(j+3)*cos(2*pi*a(1)*(x(:,i)-a(2)))*2*pi.*(x(:,i)-a(2));
    out((i-1)*n+1:i*n,2) = - a(j+3)*cos(2*pi*a(1)*(x(:,i)-a(2)))*2*pi*a(1);    
    out((i-1)*n+1:i*n,j) = ones(n,1);
    out((i-1)*n+1:i*n,j+1) = x(:,i);
    out((i-1)*n+1:i*n,j+2) = x(:,i).^2;
    out((i-1)*n+1:i*n,j+3) = sin(2*pi*a(1)*(x(:,i)-a(2)));
end
end
function out = sinparspecial_guess(x,y,dy,a)

N = size(x,2);

offsets = zeros(N,1);
linears = zeros(N,1);
quadratics = zeros(N,1);
frequencies = zeros(N,1);
phases = zeros(N,1);
amplitudes = zeros(N,1);

out = zeros(2+4*N,1);

f = a(1);

linsinmodel = mgetmodel('linear_sinusoid');
polymodel = mgetmodel('polynomial');
for i=1:N    
    [P,E] = mllsqr(linsinmodel.basis(x(:,i),f),y(:,i),dy(:,i));    
    P = linsinmodel.translate(P,E,f);
    y(:,i) = y(:,i) - linsinmodel.evaluate(x(:,i),P);
        
    amplitudes(i) = P(1);
    frequencies(i) = P(2);
    phases(i) = P(3);
    
    P = mllsqr(polymodel.basis(x(:,i),[0,0,0]),y(:,i),dy(:,i));
    
    offsets(i) = P(1);
    linears(i) = P(2);
    quadratics(i) = P(3);   
    
end



for i=1:length(phases)-1
    
    if(abs(phases(i+1)-phases(i)) < 1/f/4)
        continue
    end
    
    if(phases(i+1)-phases(i) > 1/f/4)
        phases(i+1) = phases(i+1) - 1/f/2;                
        amplitudes(i+1) = -amplitudes(i+1);
    elseif(phases(i+1)-phases(i) < 1/f/4)
        phases(i+1) = phases(i+1) + 1/f/2;                
        amplitudes(i+1) = -amplitudes(i+1);      
    end
end

out(1) = f;
out(2) = mean(phases);

for i=1:N
    j = 2 + 4*(i-1) + 1;
    out(j) = offsets(i);
    out(j+1) = linears(i);
    out(j+2) = quadratics(i);
    out(j+3) = amplitudes(i);    
end

end

%% SINUSOID + LINEAR
function out = sinpluslin_evaluate(x,a)
x = x(:);
out = a(1)+a(2)*x+a(3)*sin(2*pi*a(4)*(x-a(5)));

end
function out = sinpluslin_jacobian(x,a)
x = x(:);
out(:,1) = ones(size(x));
out(:,2) = x;
out(:,3) = sin(2*pi*a(4)*(x-a(5)));
out(:,4) = a(3)*cos(2*pi*a(4)*(x-a(5)))*2*pi.*(x-a(5));
out(:,5) = -2*pi*a(4)*a(3)*cos(2*pi*a(4)*(x-a(5)));
end
function out = sinpluslin_guess(x,y,dy,a)
if size(a,1) < size(a,2), a = a'; end
out = a;


end
