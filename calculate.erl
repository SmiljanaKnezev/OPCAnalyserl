-module(calculate).
-include_lib("xmerl/include/xmerl.hrl").
-export([clean_elem/1, cc/2, get_all_function_calls/1,  get_functions_called/2,
icc/3,icc_helper/4, opc/3, get_chains/2, lor/3, has_recursive_elem/1]).


show_elem(Infilename) ->
   {Element, _} = xmerl_scan:file(Infilename), Element.

simplify(Filename) ->
  {Element, _} = xmerl_scan:file(Filename),
  xmerl_lib:simplify_element(Element).

clean_elem(Filename) ->
  {Element, _} = xmerl_scan:file(Filename, [{space, normalize}]),
  [Clean] = xmerl_lib:remove_whitespace([Element]),
  xmerl_lib:simplify_element(Clean).


get_all_function_calls(Egdn_file) ->

  {_, _, [{_, _, Elements }]} = clean_elem(Egdn_file),
  Filtered = lists:filter(fun filter_function_calls/1, Elements).


filter_function_calls({edge, _,[{data,_,["CALLS"]},_] }) ->
      true;

filter_function_calls(_) -> false.


get_source({edge,[_,{source,Function_id},{_, _}],_ }) ->
  Function_id.


get_target({edge,[_,{source,_},{target,Target}],[_,_]}) ->
  Target.

get_targets({edge,[_,{source,_},{target,Target}],[_,{_,_,[Weight]}]}) ->
  {erlang:list_to_integer(Weight), Target}.


 get_functions_called(Fun, Egdn) ->
   All_funs = get_all_function_calls(Egdn),
   Funs_from = lists:filter(fun(All_funs) -> get_source(All_funs) == Fun end, All_funs),
   Targets = lists:map(fun(F) -> get_targets(F) end, Funs_from),
   Targets.


icc(Fun, Ecst, Egdn) ->
  icc_helper(Fun, Ecst, Egdn, [Fun]).

icc_helper(Fun, Ecst, Egdn, List) ->
  Funs = get_functions_called(Fun, Egdn),

  A = lists:map(fun({Weight, F}) ->
        case lists:member(F, List) of
          true ->  Weight * cc(Ecst, F);
          false -> Weight * icc_helper(F, Ecst, Egdn, [F | List])
        end
          end, Funs),

  D = cc(Ecst, Fun),
  D + lists:sum(A).



get_chains(Fun, Egdn) ->
  Funs =  get_functions_called(Fun, Egdn),
  Funs2 = lists:map(fun ({Weight, Id}) -> Id end, Funs),

  LList = expand_list([Fun], Funs2, []),
  D = expand_lists2(LList, Egdn, []),
  io:format("Call chains ********************: ~p~n", [D]),
  D.

expand_list(List1, [Head | Tail], Acc) ->
    A = lists:append(List1, [Head]),
    expand_list(List1, Tail, Acc ++ [A]);

expand_list(List1, [], Acc) -> Acc.


cant_expand(List, Egdn) ->
  case has_recursive_elem2(List) of
    true -> true;
    false -> get_functions_called(lists:last(List), Egdn) == []
  end.

has_recursive_elem(List) ->
  {[A, B], _} = lists:split(2, lists:reverse(List)),
  (hd(List) == lists:last(List)) or (A == B).

has_recursive_elem2(List) ->
  Elem = lists:last(List),
  List2 = lists:droplast(List),
  lists:member(Elem, List2).



expand_lists2(ListOfLists = [H | T], Egdn, Acc)  ->
  case cant_expand(H, Egdn) of
      true ->  expand_lists2(T, Egdn, Acc ++ [H]);
      false -> expand_lists2_helper(ListOfLists, Egdn, Acc)
  end;

expand_lists2([], Egdn, Acc) -> Acc.

add_funs_to_chain([H | T], Egdn, Acc) ->
   case cant_expand(H, Egdn) of
     true -> D = [H];
     false -> D = add_fun_to_chain(H, Egdn, Acc)
   end,
   add_funs_to_chain(T, Egdn, Acc ++ D);

 add_funs_to_chain([], Egdn, Acc) -> Acc.

add_fun_to_chain(List, Egdn, Acc) ->
  A = get_functions_called(lists:last(List), Egdn),
  A_filtered = lists:map(fun ({Weight, Id}) -> Id end, A),
  case length(A_filtered) of
    0 -> B = [List];
    _ -> B = expand_list(List, A_filtered, [])
  end,
  D = add_funs_to_chain(B, Egdn, []),
  D.

expand_lists2_helper([H | T], Egdn, Acc) ->
  B = add_fun_to_chain(H, Egdn, Acc),
  expand_lists2(T, Egdn,Acc ++  B);

expand_lists2_helper([], Egdn, Acc) -> Acc.


lor(Fun, From, Egdn) ->
  Funs =  get_chains(Fun, Egdn),

  Lors = lists:filtermap(fun(List) ->
     case hd(List) == lists:last(List) of
         true -> {true, List};
         false -> false
     end;
      (_) -> false
   end, Funs),

  Rec = [ P || P <- Lors,
	  lists:nth(1, P) == Fun,
    lists:nth(2, P) == From],

%  Rec = [ P || P <- Lors,
%   lists:member(From, P),
%   lists:member(Fun, P)
%  ],

  case Rec of
   	[] ->
   	    LRec = 0;
   	_ ->
   	    LRec = lists:max([length(X) || X <- Rec])-1
       end,
   LRec.



opc(Fun, Ecst, Egdn) ->
  Funs = get_functions_called(Fun, Egdn),

  A = lists:map(fun({Weight, F}) ->

    ICC = Weight * icc(F, Ecst, Egdn),
    LOR = lor(Fun,F, Egdn),

    {ICC + Weight * LOR,
     ICC + Weight * LOR * LOR,
     ICC * max(1, LOR),
     ICC * max(1, LOR * LOR)}
  end, Funs),


  CC = cc(Ecst, Fun),
  {A_IL, A_IR, A_ML, A_MR} = unzip4(A),
%  io:format("A_IL  : ~p\n", [A_IL]),
%  io:format("A_IR: ~p\n", [A_IR]),
%  io:format("A_ML: ~w\n", [A_ML]),
%  io:format("A_MR: ~w\n", [A_MR]),


  OPC = {lists:sum(A_IL) + CC, lists:sum(A_IR) + CC, lists:sum(A_ML) + CC, lists:sum(A_MR) + CC},
  {OPC_IL, OPC_IR, OPC_ML, OPC_MR} = OPC,

  io:format("opc(icc+lor)  : ~p\n", [OPC_IL]),
  io:format("opc(icc+lor^2): ~p\n", [OPC_IR]),
  io:format("opc(icc*lor)  : ~p\n", [OPC_ML]),
  io:format("opc(icc*lor^2): ~p\n", [OPC_MR]).

unzip4([]) -> {[], [],[],[]};
unzip4([{H1, H2, H3, H4} | T]) ->
	{T1, T2, T3, T4} = unzip4(T),
	{[H1|T1], [H2|T2], [H3|T3], [H4|T4]}.



filter_function_decl({_,_, [{_,Atribs,_} | _]}) ->
  {text, Value} = lists:keyfind(text, 1, Atribs),
  Value == "FUNCTION_DECL";

filter_function_decl(_) -> false.

cc(Filename, Function_name) ->

  [Package, Module, Rest] = string:tokens(Function_name, "."),

  case string:tokens(Rest, "@") of
    [Fun_name, _] -> Fun_name;
    [Fun_name, _, _] -> Fun_name
  end,

  {_, _, [_, {_, _, Elements} | _]} = clean_elem(Filename),

  case Elements of
    [_, {_,_, Lista }] -> Lista;
    [_, _, {_,_, Lista }] -> Lista
  end,


  Filtered = lists:filter(fun filter_function_decl/1, Lista),
  Node_with_function = lists:filter(fun(Filtered) -> get_function_name(Filtered) == Fun_name end, Filtered),

  CC_of_func = count_nodes(Node_with_function, 1),
%  CC_of_func = lists:map(fun(FDecl) -> count_nodes([FDecl], 1) end, Filtered),
  CC_of_func.

count_nodes([], Sum) -> Sum;

count_nodes([{token, Attributes, []} | T], Sum) ->
  Len = lists:foldl(fun({text,"FUNCTION_DECL"}, Acc) -> Acc;
                       ({text,"LOOP_STATEMENT"}, Acc) -> Acc + 1;
                      ({text,"BRANCH_STATEMENT"}, Acc) -> Acc + length(T) - 1;
                      (_, Acc) -> Acc
                    end, 0, Attributes),  %start with one

count_nodes(T, Sum + Len);


count_nodes([{childElement, [], List_of_tokens} | T], Sum) ->
    count_nodes(List_of_tokens, Sum) + count_nodes(T, 0).

get_function_name({_,_, [_,_,_, {_,_,[{_, Name_atrib, _},{_,_,[{_,Actual_name,_}]}]} | _]} ) ->
  {text, Value} = lists:keyfind(text, 1, Actual_name),
  Value.
