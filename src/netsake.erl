%% Copyright
-module(netsake).
-author("yz").

-include("bot.hrl").

-record(netcache, {need_len=0, bin = <<>>}).

%% API
-compile([export_all]).
-export([]).

pack(Data, _Step) ->
    <<_PacketLen:32, DataBin/binary>> = erlang:term_to_binary(Data) ,
    PacketLen = erlang:byte_size(DataBin),
    <<PacketLen:32, DataBin/binary>>.

unpack(Data) ->
    erlang:binary_to_term(Data). 

send(Sock, Data, Step) ->
    send(Sock, pack(Data, Step)).

send(Sock, Binary) ->
    gen_tcp:send(Sock, Binary).


net_packet_init() ->
    #netcache{need_len=0, bin = <<>>}.

net_packet(CurNetBin, NetCache) ->
    #netcache{need_len=NeedLen, bin=Bin} = NetCache,
    NetBin =
    case CurNetBin of
        [] -> Bin;
        _ -> l2b([Bin|CurNetBin])
    end,

    BinSize = bsz(NetBin),

    case NeedLen of
        0 when BinSize >= 32 ->
            <<NeedLen1:32, Rest/binary>> = NetBin,
            case bsz(Rest) >= NeedLen1 of
                true ->
                    <<NeedBin:NeedLen1/binary, Rest1/binary>> = Rest,
                    {NetCache#netcache{need_len=0, bin=Rest1}, NeedBin};
                false ->
                    {NetCache#netcache{need_len=NeedLen1, bin=Rest}, fail}
            end;
        0 ->
            {NetCache#netcache{need_len=0, bin=NetBin}, fail};
        NeedLen when BinSize >= NeedLen ->
            <<NeedBin:NeedLen/binary, Rest/binary>> = NetBin,
            {NetCache#netcache{need_len=0, bin=Rest}, NeedBin};
        _ ->
            {NetCache#netcache{need_len=NeedLen, bin=NetBin}, fail}
    end.

l2b(L) -> erlang:list_to_binary(L).
bsz(B) -> erlang:byte_size(B).


