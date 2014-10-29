function varargout = mfield(varargin)

persistent Field

if isempty(Field), Field = FIELD; end

varargout{1} = Field;

if nargin == 0, return; end

switch varargin{1}
    case 'build'
        Field.build;
    case 'save'
        Field.save(varargin{2});
    case 'load'
        Field.load(varargin{2});
    case 'label'
        Field.label(varargin{2});               
end

end