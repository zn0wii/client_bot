%% Copyright
-author("yz").

-define(TCP_OPTS, [binary, {packet, 0}, {active, true}]).
-define(TCP_TIMEOUT, 1000).
-define(HEART_BEAT, 30000).

-define(log(Msg),
    error_logger:info_msg(Msg, [])).

-define(log(Format, Args),
    error_logger:info_msg(Format, Args)).

-record(botdata, {sock, account_id, role, package}).
