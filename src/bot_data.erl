%% Copyright
-module(bot_data).
-author("yz").
-include("bot.hrl").

%% API
-compile([export_all]).
-export([]).

get() ->
    BotData = cache:find(botdata),
    %% todo process
    BotData.

update(#botdata{}=Data) ->
    cache:update(Data).
