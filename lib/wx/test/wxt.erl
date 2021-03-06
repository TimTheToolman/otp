%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2008-2011. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%%-------------------------------------------------------------------
%%% File    : wxt.erl
%%% Author  : Dan Gudmundsson <dan.gudmundsson@ericsson.com>
%%% Description : Shortcuts for starting test with wx internal test_server
%%%
%%% Created :  4 Nov 2008 by Dan Gudmundsson <dan.gudmundsson@ericsson.com>
%%%-------------------------------------------------------------------
-module(wxt).
-compile(export_all).

%%  Modules or suites can be shortcuts i.e. basic expands to wx_basic_SUITE.
%%  
%%  t(Tests) run wx testcases.
%%    Tests can be module, {module, test_case} or [module|{module,test_case}]

t() ->
    t(read_test_case()).
t(Test) ->
    t(Test, []).

t(Mod, TC) when is_atom(Mod), is_atom(TC) ->
    t({Mod,TC}, []);
t(all, Config) when is_list(Config) ->
    Fs = filelib:wildcard("wx_*_SUITE.erl"),
    t([list_to_atom(filename:rootname(File)) || File <- Fs], Config);
t(Test,Config) when is_list(Config) ->
    Tests = resolve(Test),
    write_test_case(Test),
    Res = wx_test_lib:run_test(Tests, Config),    
    append_test_case_info(Test, Res).


user() ->
    user(read_test_case()). 
user(Mod) ->
    t(Mod, [{user,step}]).
user(Mod,Tc) when is_atom(Tc) ->
    t({Mod,Tc}, [{user,step}]).
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Resolves the name of test suites and test cases
%% according to the alias definitions. Single atoms
%% are assumed to be the name of a test suite. 
resolve(Suite0) when is_atom(Suite0) ->
    case alias(Suite0) of
	Suite when is_atom(Suite) ->
	    {Suite, all};
	{Suite, Case} ->
	    {Suite, Case}
    end;
resolve({Suite0, Case}) when is_atom(Suite0), is_atom(Case) ->
    case alias(Suite0) of
	Suite when is_atom(Suite) ->
	    {Suite, Case};
	{Suite, Case2} ->
	    {Suite, Case2}
    end;
resolve(List) when is_list(List) ->
    [resolve(Case) || Case <- List].

alias(Suite) when is_atom(Suite) ->
    Str = atom_to_list(Suite),
    case {Str, lists:reverse(Str)} of
	{"wx" ++ _, "ETIUS" ++ _} ->
	    Suite;
	_ -> 
	    list_to_atom("wx_" ++ Str ++ "_SUITE")
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

config_fname() ->
    "wx_test_case_config".

%% Read default config file
read_config() ->
    Fname = config_fname(),
    wx_test_lib:log("Consulting file ~s...~n", [Fname]),
    case file:consult(Fname) of
        {ok, Config} ->
	    wx_test_lib:log("Read config ~w~n", [Config]),
            Config;
        _Error ->
	    Config = wx_test_lib:default_config(),
            wx_test_lib:log("<>WARNING<> Using default config: ~w~n", [Config]),
            Config
    end.

%% Write new default config file
write_config(Config) when is_list(Config) ->
    Fname = config_fname(),
    {ok, Fd} = file:open(Fname, write),
    write_list(Fd, Config),
    file:close(Fd).

write_list(Fd, [H | T]) ->
    ok = io:format(Fd, "~p.~n",[H]),
    write_list(Fd, T);
write_list(_, []) ->
    ok.

test_case_fname() ->
    "wx_test_case_info".

%% Read name of test case
read_test_case() ->
    Fname = test_case_fname(),
    case file:open(Fname, [read]) of
	{ok, Fd} ->
	    Res = io:read(Fd, []),
	    file:close(Fd),
	    case Res of
		{ok, TestCase} ->
		    wx_test_lib:log("Using test case ~w from file ~s~n",
					[TestCase, Fname]),
		    TestCase;
		{error, _} ->
		    default_test_case(Fname)
	    end;
	{error, _} ->
	    default_test_case(Fname)
    end.

default_test_case(Fname) ->
    TestCase = all, 
    wx_test_lib:log("<>WARNING<> Cannot read file ~s, "
		    "using default test case: ~w~n",
			[Fname, TestCase]),
    TestCase.

write_test_case(TestCase) ->
    Fname = test_case_fname(),
    {ok, Fd} = file:open(Fname, write),
    ok = io:format(Fd, "~p.~n",[TestCase]),
    file:close(Fd).

append_test_case_info(TestCase, TestCaseInfo) ->
    Fname = test_case_fname(),
    {ok, Fd} = file:open(Fname, [read, write]),
    ok = io:format(Fd, "~p.~n",[TestCase]),
    ok = io:format(Fd, "~p.~n",[TestCaseInfo]),
    file:close(Fd),
    TestCaseInfo.
