%% Copyright
-module(bot_play).
-author("yz").
-include("bot.hrl").

%% API
-compile([export_all]).
-export([]).


send(Msg) ->
%%     ?log("send: ~p", [Msg]),
    gen_server:cast(self(), {playsend, Msg}).

handle({M, F, A}, PlayState) ->
    ?log("~p handle: ~p~n", [PlayState, A]),
    case barrier(A) of
        true ->
            ?MODULE:(PlayState)({M, F, A});
        _ -> PlayState
    end.

waiting(Record, CallBack) ->
    put(Record, CallBack).

barrier({code, Code}) ->
    case get(Code) of
        undefined ->
            true;
        F ->
            ?log("callback for code: ~p", [Code]),
            F(), erase(Code), false
    end;
barrier(A) ->
    case get(A) of
        undefined ->
            true;
        F ->
            F(), erase(A), false
    end.

waiting_code(Code, F) ->
    put(Code, F).

%%%===================================================================
%% start
%%%===================================================================
play() ->
    play(protocol_1).

play(protocol_1) ->
    send(ok);
play(youturn) ->
    dosomething,
    ok.

%%%===================================================================
%% login
%%%===================================================================

%%%===================================================================
%% gaming
%%%===================================================================

%%%===================================================================
%% util
%%%===================================================================
sleep(T) ->
    receive
    after T -> ok
    end.
