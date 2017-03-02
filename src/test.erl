%% @author eavnvya
%% @doc @todo Add description to test.


-module(test).

%% ====================================================================
%% API functions
%% ====================================================================
-export([bench/2]).

bench(Host, Port) ->
	Start = erlang:system_time(micro_seconds),
	run(100, Host, Port),
	Finish = erlang:system_time(micro_seconds),
	Finish - Start.


%% ====================================================================
%% Internal functions
%% ====================================================================

run(N, Host, Port) ->
	if
		N == 0 ->
			ok;
		true ->
			request(Host, Port),
			run(N-1, Host, Port)
	end.
request(Host, Port) ->
	Opt = [list, {active, false}, {reuseaddr, true}],
	{ok, Server} = gen_tcp:connect(Host, Port, Opt),
	gen_tcp:send(Server, http:get("/foo.txt")),
	Recv = gen_tcp:recv(Server, 0),
	case Recv of
		{ok, _} ->
			ok;
		{error, Error} ->
			io:format("test: error: ~w~n", [Error])
	end,
	gen_tcp:close(Server).
