% Nitrogen Web Framework for Erlang
% Copyright (c) 2008 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (nitrogen).
-export ([
	start/0,
	stop/0,
	init/1,
	start_server/0,
	request/1,
	route/1,
	get_platform/0,
	get_port/0,
	get_wwwroot/0,
	get_signkey/0
]).

start() -> supervisor:start_link(?MODULE, []).

init(_Args) ->
	RestartStrategy = one_for_one,
	MaxRestarts = 1000,
	MaxSecondsBetweenRestarts = 3600,
	SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
	NitrogenServer = {quickstart_sup, {nitrogen, start_server, []}, permanent, 2000, worker, dynamic},
	SessionServer  = {wf_session_server, {wf_session_server, start_link, []}, permanent, 2000, worker, [wf_session_server]},
	SessionSup     = {wf_session_sup, {wf_session_sup, start_link, []}, permanent, 2000, supervisor, [wf_session_sup]},
	{ok,{SupFlags,[NitrogenServer, SessionServer, SessionSup]}}.

start_server() ->
	Result = case get_platform() of
		yaws     -> nitrogen_yaws_app:start();
		mochiweb -> nitrogen_mochiweb_app:start();
		inets    -> nitrogen_inets_app:start()
	end,

	io:format("~n~n---~n"),
	io:format("Nitrogen is now running on ~s.~n", [get_platform()]),
	io:format("Serving files from: ~s.~n", [get_wwwroot()]),
	io:format("Open your browser to: http://localhost:~p~n", [get_port()]),
	io:format("---~n~n"),

	Result.

stop() -> 
	case get_platform() of
		yaws     -> nitrogen_yaws_app:stop();
		mochiweb -> nitrogen_mochiweb_app:stop();
		inets    -> nitrogen_inets_app:stop()
	end.	
	
%%% DEFAULTS FOR ROUTE AND REQUEST %%%
	
request(_) -> ok.
route(Path) -> wf_utils:path_to_module(Path).


%%% GET CONFIG SETTINGS %%%
	
get_platform() -> 
	case application:get_env(platform) of
		{ok, Val} -> Val;
		_ -> inets
	end.
	
get_port() -> 
	case application:get_env(port) of 
		{ok, Val} -> Val;
		_ -> 8000
	end.

get_wwwroot() -> 
	case application:get_env(wwwroot) of
		{ok, Val} -> Val;
		_ -> "./wwwroot"
	end.
	
get_signkey() -> 
	case application:get_env(signkey) of
		{ok, Val} -> Val;
		_ -> throw("You must declare a signkey!")
	end.
