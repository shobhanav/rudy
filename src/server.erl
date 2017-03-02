%% @author eavnvya
%% @doc @todo Add description to server.


-module(server).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/1 , start/2, stop/0]).
start(Port) ->
    start(Port, 1).

start(Port, N) ->	
	register(rudy, spawn(fun() -> init(Port, N) end)).
		
stop() ->
	rudy ! stop,
	ok.
	

%% ====================================================================
%% Internal functions
%% ====================================================================

init(Port,N) ->
	Opt = [list, {active, false}, {reuseaddr, true}],
	case gen_tcp:listen(Port, Opt) of
		{ok, Listen} ->			
			handlers(Listen,N),			
			super();
		{error, Error} ->
			error
	end.

super()->
	receive
		stop -> 
			ok
	end.

handlers(Listen,N)->
	case N of
	0 ->
	    ok;
	N ->
	    spawn(fun() -> handler(Listen) end),
	    handlers(Listen, N-1)
    end.


handler(Listen) ->
	case gen_tcp:accept(Listen) of
		{ok, Client} ->
			requestWithMsg(Client),
%% 			request(Client),
			handler(Listen);
		{error, Error} ->
			error
	end.

request(Client) ->
	Recv = gen_tcp:recv(Client, 0),
	case Recv of 
		{ok, Str} ->
			Request = http:parse_request(Str),
			Response = reply(Request),
			gen_tcp:send(Client, Response);			
		{error, Error} ->
			io:format("rudy: error: ~w~n", [Error])
	end,
	gen_tcp:close(Client).

requestWithMsg(Client) ->
	inet:setopts(Client,[{active,once}]),
	receive
		{tcp, Client, Str}->			
			Request = http:parse_request(Str),
			Response = reply(Request),			
			gen_tcp:send(Client, Response);
		{tcp_closed, Client} ->
			io:format("rudy socket closed error: ~w~n", [self()])
	end,
	gen_tcp:close(Client).
	

reply({{get, URI, _}, _, _}) ->		
	[$/|FileName] = URI,
	case file:open(FileName, read) of
		{ok, Binary} -> 
			Data = readData(Binary),						
			file:close(Binary),			
			http:ok([Data]);
		{error, Reason} ->
			io:format("Error case file: ~s~n", [FileName]),
			Msg = "Get request received for non-existing file: " ++ FileName, 			
 			http:ok([Msg])		
	
	end.

readData(Device) ->
	case file:read_line(Device) of
		eof -> [];
		{ok, Data} -> [Data | readData(Device)]		
	end.
