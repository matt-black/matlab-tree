function varargout = treefun ( obj, varargin )
%% TREEFUN Apply a function to each node of the tree.
%   A = TREEFUN(OBJ,FUN) applies the function specified by FUN to
%   the contents of each node in the tree, OBJ.   
%   [A, B, ...] = TREEFUN(OBJ,FUN) where FUN is a function handle to a
%   function that returns multiple outputs. Returns multiple trees, each
%   corresponding to one of the output arguments of FUN. 
%   [A, B, ...] = TREEFUN(OBJ1,OBJ2,...,FUN) evaluates FUN using the
%   contents of the nodes of trees OBJ1, OBJ2, ... as input arguments, passed
%   to FUN in the same order as they are passed into TREEFUN. 
%   
%   The first argument to TREEFUN must be a tree, and the last argument must
%   be a function handle. Intermediate arguments that are trees must be
%   synchronized with the first argument, OBJ1. Non-tree intermediate
%   arguments are scalar-expanded to trees synchronized with OBJ1. 
%
%   See also TREEFUN2

    narginchk(2,Inf);                   % need at least 2 arguments (OBJ & FUN)
    fun = varargin{end};
    assert(isa(fun,'function_handle'), 'MATLAB:tree:treefun', ...
           'Last argument must be a function handle. Got a %s.', ...
           class(fun));
    try, fun_argin = nargin(fun);       % only throws if function doesn't exist
    catch, error('MATLAB:tree:treefun', ...
                 'Function %s does not exist.',func2str(f));
    end
    
    % validate number of input arguments is <= # inputs of FUN
    assert(nargin-1<=abs(fun_argin), 'MATLAB:tree:treefun', ...
           'FUN expects at most %d arguments, but you passed %d.', ...
           abs(fun_argin), nargin-1);

    % validate number of output arguments is <= # outputs of FUN
    nargoutchk(0,abs(nargout(fun)));

    % if called interactively, nargout=0, which causes problems in `cellfun`
    % call, below
    % given: 
    % >> t
    % t = ...
    %   Node: {3x1 cell}
    % e.g. if this isn't done...
    % >> t.treefun(@(x) x+1)
    % >>
    % but by setting output number to 1, `ans` will be assigned
    % >> t.treefun(@(x) x+1);
    % ans = ...
    %   Node: {3x1 cell}
    % NOTE: below, can't reassign `nargout` so introduce new variable
    if ~nargout
        n_out = 1;
    else
        n_out = nargout;
    end

    function nodes = getNodes (val, N)
    % GETNODES collects the nodes from the `val` input and returns them. If
    % `val` is not a tree, does scalar expansion. Also checks that `val` is
    % synchronized with the "reference" tree, OBJ (the first input to
    % `treefun`). 
        if ~isa(val,'tree')             % do scalar expansion
            nodes = tree(obj,val).Node;
        else
            assert(issync(obj,val), 'MATLAB:tree:treefun', ...
                   ['All tree arguments must be synchronized with the first. ' ...
                    'The %d argument was not.'], N);
            nodes = val.Node;
        end
    end

    nodes = cellfun(@getNodes, varargin(1:end-1), num2cell(2:nargin-1), ... 
                    'UniformOutput', false);
    nodes = horzcat({obj.Node},nodes);
    [content{1:n_out}] = cellfun(fun, nodes{:}, 'UniformOutput', false);
    for k = 1:n_out                     % create new tree for each output
        varargout{k} = tree(obj,'clear');
        varargout{k}.Node = content{k};
    end

end