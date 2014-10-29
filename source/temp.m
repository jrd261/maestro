
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


I = 1;
d = load('~/merged');
hold off
E = errorbar(d(:,I)/86400/365+2000,d(:,I+1),d(:,I+2),'ko','LineWidth',1);
hold on

X = d(:,I);
XX = X(1) - 2*86400*365:.1*86400*365:max(X)+2*86400*365;
model = mgetmodel('sinusoid_plus_parabola');

p  = load('~/test');
p = p((I-1)/3+1,2:2:size(p,2));

line(XX/86400/365+2000,model.evaluate(XX,p),'LineWidth',2,'Color','r');
axis([min(XX/86400/365+2000),max(XX/86400/365+2000),min(d(:,I+1))-20,max(d(:,I+1))+20])

xlabel('Year','FontName','georgia','FontSize',12,'FontWeight','bold')
ylabel('O-C (s)','FontName','georgia','FontSize',12,'FontWeight','bold')



legend({'B+C'},'FontName','georgia','FontSize',12,'FontWeight','bold')

