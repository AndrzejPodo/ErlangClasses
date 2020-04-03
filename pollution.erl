%%%-------------------------------------------------------------------
%%% @author andrz
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Apr 2020 11:07 PM
%%%-------------------------------------------------------------------
-module(pollution).
-author("andrz").


%% API
-export([createMonitor/0, addStation/3, addValue/5, removeValue/4, getStationMean/3]).

-type cords(_X,_Y) :: tuple().

-type station(_Name, _Cords) :: tuple().

-type measure(_Datetime, _Type, _Val) :: tuple().

%%-type type() :: "pm10" | "pm25" | "temp."

-record(cords, {
  x :: float(),
  y :: float()
}).

-record(station, {
  name :: unicode:chardata(),
  cords :: cords(_,_)
}).
-record(measure, {
  datetime :: calendar:datetime(),
  type :: unicode:chardata(),
  val
  %%dict :: dict:dict({calendar:datetime(), type()}, _)
}).
-record(monitor, {
  list :: lists:list(),
  dict :: dict:dict(station(_,_), measure(_,_,_))
}).

createMonitor() -> #monitor{list = [], dict = dict:new()}.

addStation(Name, Cords, Monitor) ->
  case lists:member(#station{name = Name, cords = Cords}, Monitor#monitor.list)
  of true -> {error, "Proba dodania drugi raz tej samej stacji"};
     false-> #monitor{list = Monitor#monitor.list++[#station{name = Name, cords = Cords}], dict = Monitor#monitor.dict}
  end.

getStation(Station, Monitor)->lists:filter(fun(#station{name = N,cords = C})-> (C == Station) or (N == Station) end, Monitor#monitor.list).

getOneValue(NameOrCords, Date, Type, Monitor)->
  getOneVal(getStation(NameOrCords,Monitor), Date, Type, Monitor).

getOneVal([],_,_,_)->{error, "Nie ma takiej stacji"};
getOneVal([Station|_], Date, Type, Monitor)->
  case dict:is_key(Station, Monitor#monitor.dict)
    of true ->
      case lists:filter(fun(#measure{datetime = D, type = T, val=_})->(T == Type) and (D == Date) end, dict:fetch(Station, Monitor#monitor.dict))
        of [] -> {error, "Nie ma takiego pomiaru na tej stacji"};
        [H|_]-> H
        end;
      false ->{error, "Nie zarejestrowano pomiarow na tej stacji"}
  end.

getValues([],_,_)->{error, "Nie ma takiej stacji"};
getValues([Station|_], Type, Monitor)->
  case dict:is_key(Station, Monitor#monitor.dict)
  of true -> lists:filter(fun(#measure{datetime = D, type = T, val=_})->(T == Type) end, dict:fetch(Station, Monitor#monitor.dict));
     false ->{error, "Nie zarejestrowano pomiarow na tej stacji"}
  end.

addValue(NameOrCords, Monitor, Time, Type, Val)->
  addVal(getStation(NameOrCords, Monitor), Monitor, Time, Type, Val).

addVal([],_,_,_,_)->{error, "Nie ma takiej stacji"};
addVal([Station|_], Monitor, Time, Type, Val)->
  case dict:is_key(Station, Monitor#monitor.dict)
  of true ->
    case lists:filter(fun(#measure{datetime = D, type = T, val=_})->(T == Type) and (D == Time) end, dict:fetch(Station, Monitor#monitor.dict))
      of [] -> #monitor{list= Monitor#monitor.list,dict = dict:append(Station,#measure{datetime = Time, type=Type, val=Val},Monitor#monitor.dict)};
      _ -> {error, "Taki pomair juz zostal wprowadzony"}
    end;
  false ->#monitor{list= Monitor#monitor.list,dict = dict:append(Station,#measure{datetime = Time, type=Type, val=Val},Monitor#monitor.dict)}
  end.

removeValue(NameOrCords, Monitor, Time, Type)->
  removeVal(getStation(NameOrCords, Monitor), Monitor, Time,Type).

removeVal([], _, _, _)->{error, "Nie ma takiej stacji"};
removeVal([Station|_], Monitor, Time, Type)->
  case dict:is_key(Station, Monitor#monitor.dict)
  of true ->
    #monitor{list = Monitor#monitor.list, dict = dict:update(Station, fun(Old)->lists:filter(fun(#measure{datetime = D, type = T, val = _})->(D=/=Time) or (T=/=Type)end, Old) end, Monitor#monitor.dict)};
    false ->{error, "Nie ma takiego pomiaru"}
  end.

getStationMean(NameOrCords, Type, Monitor)->
  L = getValues(getStation(NameOrCords, Monitor), Type, Monitor),
  Len = length(L),
  lists:foldl(fun(#measure{datetime = _, type = _, val = X}, Acc)->Acc + X/Len end, 0, L).




