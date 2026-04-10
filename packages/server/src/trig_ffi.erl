-module(trig_ffi).
-export([sin/1, cos/1, asin/1, pi/0, sqrt/1]).

sin(X) -> math:sin(X).
cos(X) -> math:cos(X).
asin(X) -> math:asin(X).
pi() -> math:pi().
sqrt(X) -> math:sqrt(X).
