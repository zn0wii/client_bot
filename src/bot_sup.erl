%% Copyright
-module(bot_sup).
-author("yz").
-behaviour(supervisor).

%% API
-export([start_link/0, start_child/1, init/1]).
-export([start/2]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Id) ->
    supervisor:start_child(?SERVER, [Id]).

start(StartId, Num) ->
    lists:foreach(fun(Id) -> start_child(Id) end, lists:seq(StartId, StartId+Num)).

init([]) ->
    {ok, {{simple_one_for_one, 5, 10},
        [{bot_dummp, {bot_proc, start_link, []}, permanent, brutal_kill, worker, [bot_proc]}]}}.
