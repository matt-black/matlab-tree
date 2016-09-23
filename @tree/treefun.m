function varargout = treefun ( obj, varargin )
% TREEFUN Apply a function to each node of the tree.
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

    fun = varargin{end};                % the last arg must be the function
    if ~isa(fun, 'function_handle')
        % TODO: allow string args (str2func)
        error('MATLAB:tree:treefunN', ...
              'Last argument must be a function handle. Got a %s.', ...
              class(fun));
    end

    % validate number of output arguments is <= # outputs of `fun`
    nargoutchk(0,abs(nargout(fun)));
    
    % if called interactively, nargout=0, which causes problems in `cellfun`
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
            if ~issync(obj,val) 
                error('MATLAB:tree:treefun', ...
                      ['All tree arguments must be synchronized with the first ' ...
                       'argument. The %dth argument was not.'], N);
            end
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