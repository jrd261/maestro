function cmd_fold(args)

    data = mread(args.filename{1});
    
    x = str2double(data(:,1));
    y = str2double(data(:,2));
    
    p = args.period;
    t = args.phase;
    n = args.nbins;
    
    if isempty(n)
        n = 2000;
    end
    
    if isempty(t)
        t = 0;
    end

    
    x = x - min(x);
    
    
    xx = ((1/n:1/n:1) - 1/n/2)*p;
    yy = zeros(size(xx));
    nn = zeros(size(xx));
    
    X = x/p;
    X = round((X - floor(X))*(n-1)) + 1;
    
    
    for i=1:length(X)
        
        yy(X(i)) = yy(X(i)) + y(i);
        nn(X(i)) = nn(X(i)) + 1;
        
    end
    
    
    yy = yy./nn;
    
    
    out = [xx',yy'];
    
    save folded out -ASCII -DOUBLE




end