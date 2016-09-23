function varargout = treefun2(obj, val, fun)
%%TREEFUN2  Two-arguments function on trees, with scalar expansion.
    [obj, val] = permuteIfNeeded(obj, val);
    [varargout{1:nargout}] = treefun(obj,val,fun);
end