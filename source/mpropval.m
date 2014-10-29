function propval = mpropval(defaultpropval,overridepropval)
%MPROPVAL Summary of this function goes here
%   Detailed explanation goes here

propval = defaultpropval;

for iPV=1:2:length(overridepropval)
    if isfield(propval,overridepropval{iPV})
        preclass = class(propval.(overridepropval{iPV}));
        propval.(overridepropval{iPV}) = overridepropval{iPV+1};
        postclass = class(propval.(overridepropval{iPV}));
        if ~strcmp(preclass,postclass), error('a:a:a','E2'); end
    else
        error('a:a:a','E1');
    end            
end