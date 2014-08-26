%%%-------------------------------------------------------------------
%%% @author goddess <goddess@rekoo.com>
%%% @copyright (C) 2013, goddess.rekoo.com
%%% @doc
%%%
%%% @end
%%% Created : 29 Jan 2013 by goddess <goddess@rekoo.com>
%%%-------------------------------------------------------------------
-module(bot_proc).
-behaviour(gen_server).

%% -include("robot.hrl").
-include("bot.hrl").

%% API
-export([start_link/1, start_link/3]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {sock, sock_cache, step, account_id, play_state}).


%%%===================================================================
%%% API
%%%===================================================================
-define(ip, "127.0.0.1").
-define(port, 8888).

start_link(Id) ->
    Name = lists:flatten(io_lib:format("robot_~p", [Id])),
    start_link(Name, ?ip, ?port).


start_link(AccountId, Ip, Port) ->
    Name = list_to_atom(util:to_list(AccountId)),
    gen_server:start_link({local, Name}, ?MODULE, [AccountId, Ip, Port, ?TCP_OPTS, ?TCP_TIMEOUT], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([AccountId, Ip, Port, Options, Timeout]) ->
    cache:init(self()),
    process_flag(trap_exit, true),
    case gen_tcp:connect(Ip, Port, Options, Timeout) of
        {ok, Sock} ->
            inet:setopts(Sock, [{active, true}]),
            bot_data:update(#botdata{sock=Sock, account_id=AccountId}),
            bot_play:play(),
            heartbeat(self()),
            erlang:send_after(1000, self(), youturn),
            erlang:send_after(10000, self(), queuecheck),
            {ok, #state{sock=Sock, sock_cache=netsake:net_packet_init(), step=1, account_id=AccountId, play_state=init}};
        {error, Reason} ->
            ?log("Robot connection error: ~p~n", [Reason]),
            {stop, Reason}
    end.

%% @private
handle_call(Request, From, State) ->
    ?log("Unhandled Call Warning, Request: ~p, From: ~p, Stacktrace: ~p~n", 
        [Request, From, erlang:get_stacktrace()]),
    {reply, ok, State}.


%% @private
%% @doc Handling cast messages
handle_cast({playsend, Msg}, State) ->
    netsake:send(State#state.sock, Msg, State#state.step),
    {noreply, State#state{step=step_policy(State#state.step)}};

handle_cast(Msg, State) ->
    ?log("Unhandled Cast Warning, Msg: ~p, Stacktrace: ~p~n", [Msg, erlang:get_stacktrace()]),
    {noreply, State}.

handle_info({tcp_closed, _Socket}, State) ->
    {stop,normal, State};

handle_info({tcp, Sock, <<Bin/binary>>}, #state{sock=Sock, sock_cache=Cache, play_state=PlayState}=State) ->
    {Cache2, PlayState2} = proc_tcp(Bin, Cache, PlayState),
    {noreply, State#state{sock_cache=Cache2, play_state=PlayState2}};

handle_info(heartbeat, State) ->
    netsake:send(State#state.sock, {heartbeat}, State#state.step),
    heartbeat(self()),
    {noreply, State#state{step=step_policy(State#state.step)}};

handle_info(youturn, State) ->
    erlang:send_after(1000, self(), youturn),
    bot_play:play(youturn),
    {noreply, State};

handle_info(queuecheck, #state{sock=Sock}=State) ->
    case erlang:process_info(self(),message_queue_len) of
        {message_que_len, Num} when Num > 100 ->
            inet:setopts(Sock, [{active, false}]),
            ?log("message_que_len ~p ~n", [Num]);
        _ ->
           inet:setopts(Sock, [{active, true}])
    end,
    erlang:send_after(10000, self(), queuecheck),
    {noreply, State};

handle_info({M, F, A}, State) ->
    apply(M, F, A),
    {noreply, State};

handle_info(Info, State) ->
    ?log("Info: ~p, Stacktrace: ~p~n", [Info, erlang:get_stacktrace()]),
    {noreply, State}.

%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
terminate(_Reason, #state{sock=Sock}=_State) ->
    gen_tcp:close(Sock),
    ok.

%% @private
%% @doc Convert process state when code is changed
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
step_policy(Num) when Num >= 1000 -> 1;
step_policy(Num) -> Num +1.

heartbeat(Pid) ->
    erlang:send_after(?HEART_BEAT, Pid, heartbeat).

proc_tcp(Bin, Cache, PlayState) ->
    {Cache2, DataBin} = netsake:net_packet(Bin, Cache),
    case DataBin of
        fail ->
            {Cache2, PlayState};
        _ ->
            {M, F, A} = netsake:unpack(DataBin),
            PlayState2 = bot_play:handle({M, F, A}, PlayState),
            proc_tcp([], Cache2, PlayState2)
    end.
