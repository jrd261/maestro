function S = mrobuststd(data,i)

    
S = nanmedian(abs(data(:)-nanmedian(data(:))))*1.4826;

% return
% data = data(:);
% data = data - mean(data);
% 
% datacopy = data;
% val1 = min(abs(datacopy));
% datacopy(abs(datacopy) == val1) = [];
% val2 = min(abs(datacopy));
% diff = val2-val1;
% 
% Y = hist(data,-2*diff:diff:2*diff);
% while((Y(1)+Y(5))/(Y(2)+Y(3)+Y(4))>.5)
%     diff = diff*2;
%     Y = hist(data,-2*diff:diff:2*diff);
% 
%     
%     
% end
% 
% Y = Y(2:4);
% 
% 
% Sest = diff/log(Y(2)/mean([Y(1),Y(3)]))^(1/2);
% 
% 
% [Y,X] = hist(data,-1.5*Sest:diff:1.5*Sest);
% X(1) = [];
% X(length(X)) = [];
% Y(1) = [];
% Y(length(Y)) = [];
% 
% 
% [A,S] = m1dgaussfit(X',Y'); %#ok<ASGLU>
